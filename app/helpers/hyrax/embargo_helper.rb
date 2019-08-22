# frozen_string_literal: true

module Hyrax

  module EmbargoHelper

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

    def about_to_expire_embargo_email( asset:, expiration_days:, mode: 'report' )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( "asset", asset ),
                                             "asset=#{asset}",
                                             "expiration_days=#{expiration_days}",
                                             "" ]
      embargo_release_date = asset.embargo_release_date
      # calculate actual days to expiration
      model = asset.solr_document.to_model
      # formulate email message
      if mode == 'report'

      end
    end

      # Update the visibility of the work to match the correct state of the embargo, then clear the embargo date, etc.
    # Saves the embargo and the work
    def deactivate_embargo( curation_concern:, copy_visibility_to_files: false, email_owner: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( "curation_concern", curation_concern ),
                                             "copy_visibility_to_files=#{copy_visibility_to_files}",
                                             "email_owner=#{email_owner}",
                                             "" ]
      return if true
      # also probably want to lock the model
      if curation_concern.file_set?
        curation_concern.visibility = curation_concern.to_solr["visibility_after_embargo_ssim"]
        curation_concern.save!
      else
        # Add configurable option to email owner of the work about embargo deactivation.
        curation_concern.embargo_visibility! # If the embargo has lapsed, update the current visibility.
        curation_concern.deactivate_embargo!
        curation_concern.embargo.save!
        rv = curation_concern.save!
        curation_concern.copy_visibility_to_files if copy_visibility_to_files
        deactivate_embargo_email( curation_concern: curation_concern ) if email_owner
        rv
      end
    end

    def deactivate_embargo_email( curation_concern: )
      # TODO
    end

    def warn_deactivate_embargo_email( curation_concern:, days: )
      # TODO
    end

  end

end
