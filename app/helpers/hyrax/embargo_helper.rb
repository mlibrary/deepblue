# frozen_string_literal: true

module Hyrax

  module EmbargoHelper

    def asset_embargo_release_date( asset: )
      rv = "#{asset.embargo_release_date} #{Time.zone}"
      DateTime.parse rv
    end

    def assets_with_expired_embargoes
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ]
      @assets_with_expired_embargoes ||= EmbargoService.assets_with_expired_embargoes
    end

    def assets_under_embargo
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ]
      @assets_under_embargo ||= EmbargoService.assets_under_embargo
    end

    def assets_with_deactivated_embargoes
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ]
      @assets_with_deactivated_embargoes ||= EmbargoService.assets_with_deactivated_embargoes
    end

    def about_to_expire_embargo_email( asset:, expiration_days:, email_owner: true, test_mode: false, verbose: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( "asset", asset ),
                                             "asset=#{asset}",
                                             "expiration_days=#{expiration_days}",
                                             "email_owner=#{email_owner}",
                                             "test_mode=#{test_mode}",
                                             "verbose=#{verbose}",
                                             "" ]
      embargo_release_date = asset.embargo_release_date
      curation_concern = ::ActiveFedora::Base.find asset.id
      email = curation_concern.authoremail
      # subject = Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.subject", title: title )
      title = curation_concern.title.join
      subject = "Deepblue Data: Embargo will expire in #{expiration_days} days for #{title}"
      url = ::Deepblue::EmailHelper.curation_concern_url( curation_concern: curation_concern )
      Deepblue::LoggingHelper.debug "about_to_expire_embargo_email: curation concern id: #{curation_concern.id} email: #{email} exipration_days: #{expiration_days}" if verbose
      body = []
      body << "The embargo will expire in #{expiration_days} days on #{embargo_release_date} for #{title} (#{curation_concern.id})"
      body << "When the embargo is deactivated, its visibility will be set to #{visibility_on_embargo_deactivation( curation_concern: curation_concern )}."
      body << ""
      body << "You may visit it at: #{url}"
      body = body.join( "\n" )
      event_note = "#{expiration_days} days"
      event_note += " test_mode" if test_mode
      Deepblue::EmailHelper.log( class_name: self.class.name,
                                 current_user: nil,
                                 event: "Embargo expiration notification",
                                 event_note: event_note,
                                 id: curation_concern.id,
                                 to: email,
                                 from: email,
                                 subject: subject,
                                 body: body )
      Deepblue::EmailHelper.send_email( to: email, from: email, subject: subject, body: body ) unless test_mode
    end

    def days_to_embargo_release_date( now: DateTime.now, embargo_release_date: )
      embargo_release_date = DateTime.parse "#{embargo_release_date} #{Time.zone}" if embargo_release_date.is_a? String
      ((embargo_release_date - @start_of_day).to_f + 0.5).to_i
    end

    # Update the visibility of the work to match the correct state of the embargo, then clear the embargo date, etc.
    # Saves the embargo and the work
    def deactivate_embargo( curation_concern:, copy_visibility_to_files:, email_owner: true, test_mode: false, verbose: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( "curation_concern", curation_concern ),
                                             "copy_visibility_to_files=#{copy_visibility_to_files}",
                                             "email_owner=#{email_owner}",
                                             "test_mode=#{test_mode}",
                                             "verbose=#{verbose}",
                                             "" ]
      # also probably want to lock the model
      if curation_concern.is_a? FileSet
        ::Deepblue::LoggingHelper.debug "deactivate_embargo for file_set: curation concern id: #{curation_concern.id}" if verbose
        curation_concern.visibility = visibility_on_embargo_deactivation( curation_concern: curation_concern )
        curation_concern.save! unless test_mode
      else
        curation_concern.embargo_visibility! unless test_mode # If the embargo has lapsed, update the current visibility.
        curation_concern.deactivate_embargo! unless test_mode
        curation_concern.embargo.save! unless test_mode
        rv = false
        rv = curation_concern.save! unless test_mode
        curation_concern.copy_visibility_to_files if copy_visibility_to_files && !test_mode
        deactivate_embargo_email( curation_concern: curation_concern, test_mode: test_mode ) if email_owner
        rv
      end
    end

    def deactivate_embargo_email( curation_concern:, test_mode:, verbose: false )
      email = curation_concern.authoremail
      # subject = Deepblue::EmailHelper.t( "hyrax.email.notify_attach_files_to_work_job_complete.subject", title: title )
      title = curation_concern.title.join
      subject = "Deepblue Data: Embargo deactivated for #{title}"
      url = ::Deepblue::EmailHelper.curation_concern_url( curation_concern: curation_concern )
      Deepblue::LoggingHelper.debug "deactivate_embargo_email: curation concern id: #{curation_concern.id} email: #{email}" if verbose
      body = []
      body << "The embargo for #{title} (#{curation_concern.id}) has been deactivated by setting its visibility to #{curation_concern.visibility}."
      body << ""
      body << "You may visit it at: #{url}"
      body = body.join( "\n" )
      event_note = ''
      event_note = "test_mode" if test_mode
      Deepblue::EmailHelper.log( class_name: self.class.name,
                                 current_user: nil,
                                 event: "Deactivate embargo",
                                 event_note: event_note,
                                 id: curation_concern.id,
                                 to: email,
                                 from: email,
                                 subject: subject,
                                 body: body )
      Deepblue::EmailHelper.send_email( to: email, from: email, subject: subject, body: body ) unless test_mode
    end

    def warn_deactivate_embargo_email( curation_concern:, days: )
      # TODO
    end

    def visibility_on_embargo_deactivation( curation_concern: )
      curation_concern.to_solr["visibility_after_embargo_ssim"]
    end

  end

end
