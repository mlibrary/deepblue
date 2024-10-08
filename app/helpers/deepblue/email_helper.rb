# frozen_string_literal: true

module Deepblue

  module EmailHelper

    mattr_accessor :email_helper_debug_verbose, default: false

    TEXT_HTML = 'text/html'.freeze unless const_defined? :TEXT_HTML
    UTF8 = 'UTF-8'.freeze unless const_defined? :UTF8

    # hyrax4 upgrade
    def self.t( key )
      I18n.t( key ) # Update: hyrax4
    end

    # hyrax4 upgrade
    def self.t!( key, **options )
      I18n.t!( key, **options )
    end

    # hyrax4 upgrade
    def self.translate( key )
      I18n.translate!( key )
    end

    # hyrax4 upgrade
    def self.translate!( key, **options )
      I18n.translate!( key, **options  )
    end

    # CLEAN_STR_REPLACEMENT_CHAR = "?"

    # Replace invalid UTF-8 character sequences with a replacement character
    #
    # Returns self as valid UTF-8.
    def self.clean_str!(str)
      return str if str.encoding.to_s == UTF8
      str.force_encoding("binary").encode(UTF8, :invalid => :replace, :undef => :replace, :replace => '?')
    end

    # Replace invalid UTF-8 character sequences with a replacement character
    #
    # Returns a copy of this String as valid UTF-8.
    def self.clean_str(str)
      clean_str!(str.dup)
    end

    def self.clean_str_needed?( str )
      str.encoding.to_s != UTF8
    end

    def self.cc_contact_email( curation_concern: )
      if curation_concern.is_a?( DataSet )
        curation_concern.authoremail
      elsif curation_concern.is_a?( FileSet )
        curation_concern.parent.authoremail
      elsif curation_concern.is_a?( Collection )
        curation_concern.depositor
      else
        nil
      end
    end

    def self.cc_creator( curation_concern:, join_with: ", " )
      if curation_concern.is_a?( DataSet )
        curation_concern.creator.join( join_with )
      elsif curation_concern.is_a?( FileSet )
        curation_concern.parent.creator
      elsif curation_concern.is_a?( Collection )
        curation_concern.creator
      else
        "Creator"
      end
    end

    def self.cc_depositor( curation_concern: )
      if curation_concern.is_a?( DataSet )
        curation_concern.depositor
      elsif curation_concern.is_a?( FileSet )
        curation_concern.parent.depositor
      elsif curation_concern.is_a?( Collection )
        curation_concern.depositor
      else
        "Depositor"
      end
    end

    def self.cc_doi( curation_concern: )
      if curation_concern.is_a?( DataSet )
        curation_concern.doi
      elsif curation_concern.is_a?( FileSet )
        curation_concern.parent.doi
      elsif curation_concern.is_a?( Collection )
        curation_concern.doi
      else
        "DOI"
      end
    end

    def self.cc_globus_link( curation_concern: )
      if curation_concern.is_a?( DataSet )
        ::Deepblue::GlobusService.globus_external_url curation_concern.id
      elsif curation_concern.is_a?( FileSet )
        ::Deepblue::GlobusService.globus_external_url curation_concern.parent.id
      elsif curation_concern.is_a?( Collection )
        ""
      else
        ""
      end
    end

    def self.cc_title( curation_concern:, join_with: " " )
      if curation_concern.is_a?( DataSet )
        curation_concern.title.join( join_with )
      elsif curation_concern.is_a?( FileSet )
        curation_concern.label
      elsif curation_concern.is_a?( Collection )
        curation_concern.title.join( join_with )
      else
        rv = curation_concern&.title&.first
        rv ||= "Title"
        return rv
      end
    end

    def self.cc_url( curation_concern:, only_path: false )
      curation_concern_url( curation_concern: curation_concern, only_path: only_path )
    end

    def self.contact_email
      # Settings.hyrax.contact_email
      notification_email_contact_us_to
    end

    def self.collection_url( id: nil, collection: nil, only_path: false )
      id = collection.id if collection.present?
      host = hostname
      Rails.application.routes.url_helpers.hyrax_collection_url( id: id, host: host, only_path: only_path )
    rescue ActionController::UrlGenerationError => e
      Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      return ''
    end

    def self.content_html?( content_type )
      ::Deepblue::EmailHelper::TEXT_HTML == content_type
    end

    def self.curation_concern_type( curation_concern: )
      if curation_concern.is_a?( DataSet )
        'work'
      elsif curation_concern.is_a?( FileSet )
        'file'
      elsif curation_concern.is_a?( Collection )
        'collection'
      else
        'unknown'
      end
    end

    def self.curation_concern_url( curation_concern:, only_path: false )
      if curation_concern.is_a?( DataSet )
        data_set_url( id: curation_concern.id, only_path: only_path )
      elsif curation_concern.is_a?( FileSet )
        file_set_url( id: curation_concern.id, only_path: only_path )
      elsif curation_concern.is_a?( Collection )
        collection_url( id: curation_concern.id, only_path: only_path )
      else
        begin
          return polymorphic_path(curation_concern)
        rescue Exception => ignore
          return ""
        end
      end
    end

    def self.detect_content_type( body )
      body = Array( body )
      body.each do |line|
        return TEXT_HTML if line =~ /^.*<([^<>]+>[^<>]+<[^<>]+|[^<>]+\/)>.*$/
      end
      return nil
    end

    def self.data_set_url( id: nil, data_set: nil, only_path: false )
      id = data_set.id if data_set.present?
      host = hostname
      Rails.application.routes.url_helpers.hyrax_data_set_url( id: id, host: host, only_path: only_path )
    rescue ActionController::UrlGenerationError => e
      Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      return ''
    end

    def self.file_set_url( id: nil, file_set: nil, only_path: false )
      id = file_set.id if file_set.present?
      host = hostname
      Rails.application.routes.url_helpers.hyrax_file_set_url( id: id, host: host, only_path: only_path )
    rescue ActionController::UrlGenerationError => e
      Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      return ''
    end

    def self.echo_to_rails_logger
      Rails.configuration.email_log_echo_to_rails_logger
    end

    def self.escape_html(s)
      ERB::Util.html_escape(s)
    end

    def self.hostname
      rv = Settings.hostname
      return rv unless rv.nil?
      # then we are in development mode
      "http://localhost:3000/data/"
    end

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: 'unknown_id',
                  timestamp: LoggingHelper.timestamp_now,
                  to:,
                  to_note: '',
                  cc: nil,
                  bcc: nil,
                  from: ::Deepblue::EmailHelper.notification_email_from,
                  subject:,
                  message: '',
                  email_sent:,
                  **key_values )

      email_enabled = Rails.configuration.email_enabled
      added_key_values = { to: to }
      added_key_values.merge!( { to_note: to_note } ) if to_note.present?
      added_key_values.merge!( { cc: cc } ) if cc.present?
      added_key_values.merge!( { bcc: bcc } ) if bcc.present?
      added_key_values.merge!( { from: from,
                                 subject: subject,
                                 message: message,
                                 email_enabled: email_enabled,
                                 email_sent: email_sent } )
      key_values.merge! added_key_values
      LoggingHelper.log( class_name: class_name,
                         event: event,
                         event_note: event_note,
                         id: id,
                         timestamp: timestamp,
                         echo_to_rails_logger: EmailHelper.echo_to_rails_logger,
                         logger: EMAIL_LOGGER,
                         **key_values )
    end

    def self.log_raw( msg )
      EMAIL_LOGGER.info( msg )
    end

    def self.mailto_contact_us_html( label: nil, new_window: false )
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "" ] if Rails.configuration.email_debug_verbose
      to = contact_us_at
      label = to if label.blank?
      rv = if new_window
             "<a href=\"mailto:#{to}\" target=\"_blank\">#{label}</a>"
           else
             "<a href=\"mailto:#{to}\">#{label}</a>"
           end
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{rv}",
                                  "" ] if Rails.configuration.email_debug_verbose
      rv
    end

    def self.mailto_workflow_html( label: nil, new_window: false )
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "" ] if Rails.configuration.email_debug_verbose
      to = notification_email_workflow_to
      label = to if label.blank?
      rv = if new_window
             "<a href=\"mailto:#{to}\" target=\"_blank\">#{label}</a>"
           else
             "<a href=\"mailto:#{to}\">#{label}</a>"
           end
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{rv}",
                                  "" ] if Rails.configuration.email_debug_verbose
      rv
    end

    def self.contact_us_at
      notification_email_contact_us_to
    end

    def self.notification_email_contact_form_to
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{Rails.configuration.notification_email_contact_form_to}",
                                  "" ] if Rails.configuration.email_debug_verbose
      Rails.configuration.notification_email_contact_form_to
    end

    def self.notification_email_contact_us_to
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{Rails.configuration.notification_email_contact_us_to}",
                                  "" ] if Rails.configuration.email_debug_verbose
      Rails.configuration.notification_email_contact_us_to
    end

    def self.notification_email_deepblue_to
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{Rails.configuration.notification_email_deepblue_to}",
                                  "" ] if Rails.configuration.email_debug_verbose
      Rails.configuration.notification_email_deepblue_to
    end

    def self.notification_email_from
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{Rails.configuration.notification_email_from}",
                                  "" ] if Rails.configuration.email_debug_verbose
      Rails.configuration.notification_email_from
    end

    def self.notification_email_jira_to
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{Rails.configuration.notification_email_jira_to}",
                                  "" ] if Rails.configuration.email_debug_verbose
      Rails.configuration.notification_email_jira_to
    end

    def self.notification_email_service_request_to
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                 ::Deepblue::LoggingHelper.called_from,
                                 "rv=#{Rails.configuration.notification_email_service_request_to}",
                                 "" ] if Rails.configuration.email_debug_verbose
      Rails.configuration.notification_email_service_request_to
    end

    def self.notification_email_rds_to
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{Rails.configuration.notification_email_rds_to}",
                                  "" ] if Rails.configuration.email_debug_verbose
      Rails.configuration.notification_email_rds_to
    end

    def self.notification_email_to
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{Rails.configuration.notification_email_to}",
                                  "" ] if Rails.configuration.email_debug_verbose
      Rails.configuration.notification_email_to
    end

    def self.notification_email_workflow_to
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "rv=#{Rails.configuration.notification_email_workflow_to}",
                                  "" ] if Rails.configuration.email_debug_verbose
      Rails.configuration.notification_email_workflow_to
    end

    def self.send_email( to:,
                         cc: nil,
                         bcc: nil,
                         from: notification_email_from,
                         subject:,
                         body:,
                         log: false,
                         content_type: nil )

      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
      #                                       "to=#{to}",
      #                                       "cc=#{cc}",
      #                                       "bcc=#{bcc}",
      #                                       "from=#{from}",
      #                                       "subject=#{subject}",
      #                                       "body=#{body}",
      #                                       "log=#{log}",
      #                                       "content_type=#{content_type}" ] if true
      subject = subject.join( '' ) if subject.is_a? Array
      body = body.join( "\n" ) if body.is_a? Array
      subject = EmailHelper.clean_str subject if EmailHelper.clean_str_needed? subject
      body = EmailHelper.clean_str body if EmailHelper.clean_str_needed? body
      email_enabled = Rails.configuration.email_enabled
      is_enabled = email_enabled ? "is enabled" : "is not enabled"
      LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "is_enabled=#{is_enabled}",
                                  "to=#{to}",
                                  "cc=#{cc}",
                                  "bcc=#{bcc}",
                                  "from=#{from}",
                                  "subject=#{subject}",
                                  "body=#{body}" ] if log || Rails.configuration.email_debug_verbose
      return if to.blank?
      return unless email_enabled
      email = DeepblueMailer.send_an_email( to: to,
                                            cc: cc,
                                            bcc: bcc,
                                            from: from,
                                            subject: subject,
                                            body: body,
                                            content_type: content_type )
      email.deliver_now
      true
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      send_email_error( to: to,
                        cc: cc,
                        bcc: bcc,
                        from: from,
                        subject: subject,
                        body: body,
                        log: log,
                        content_type: content_type,
                        email_enabled: email_enabled,
                        exception: e )
      false
    end

    def self.send_email_error( to: nil,
                               cc: nil,
                               bcc: nil,
                               from: notification_email_from,
                               subject: nil,
                               body: nil,
                               log: nil,
                               content_type: nil,
                               email_enabled:,
                               exception: )
      return unless email_enabled
      subject ||= "Send email error encountered"
      body ||= "#{exception.class} #{exception.message} at:\n#{exception.backtrace.join("\n")}"
      to_addresses = to
      to_addresses ||= Rails.configuration.email_error_alert_addresses
      to_addresses = Array( to_addresses )
      to_addresses.each do |addr|
        email = DeepblueMailer.send_an_email( to: addr,
                                              from: from,
                                              subject: subject,
                                              body: body,
                                              content_type: content_type )
        email.deliver_now
      end
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    end

    def self.build_email_body( subject:, messages: [], msg_handler: nil )
      messages ||= []
      messages = messages + msg_handler.msg_queue if msg_handler.present? && msg_handler.msg_queue.present?
      rv =<<-END_BODY
#{subject}<br/>
<br/>
#{messages.empty? ? "" : "Messages:<br/>\n<pre>\n#{messages.join("\n")}\n</pre><br/>"}
      END_BODY
      return rv
    end

    def self.send_email_fritx( subject:,
                               msg_handler: nil,
                               messages: nil,
                               content_type: ::Deepblue::EmailHelper::TEXT_HTML )

      msg_handler.msg "send_email_fritx( #{subject} )" if msg_handler.present?
      body = build_email_body( subject: subject, msg_handler: msg_handler, messages: messages )
      send_email( to: "fritx@umich.edu", subject: subject, body: body, content_type: content_type )
    rescue Exception => e
      send_email_error( to: "fritx@umich.edu", email_enabled: true, exception: e )
    end

    def self.template_default_options( curation_concern:, starting_options: {} )
      options = {}
      options.merge! starting_options if starting_options.present?
      options[:contact_us_at] = contact_us_at
      options[:contact_email] = cc_contact_email( curation_concern: curation_concern )
      options[:creator] = cc_creator( curation_concern: curation_concern )
      options[:depositor] = cc_depositor( curation_concern: curation_concern )
      options[:globus_link] = cc_globus_link( curation_concern: curation_concern )
      options[:title] = cc_title( curation_concern: curation_concern )
      options[:curation_concern_url] = curation_concern_url( curation_concern: curation_concern )
      options[:url] = options[:curation_concern_url]
      options[:hostname] = Rails.configuration.hostname
      options
    end

    def self.to_anchor( value )
      "<a href=#{value}>#{value}</a>"
    end

    def self.to_anchor?( value )
      return false if value.blank?
      return false unless value.is_a? String
      value.start_with? 'http' # TODO: other starting values, like doi: or it looks like an email address
    end

    def self.to_mon( datetime )
      datetime.strftime("%b")
    end

    def self.to_month( datetime )
      datetime.strftime("%B")
    end

    def self.user_email
      Rails.configuration.user_email
    end

    def self.user_email_from( current_user, user_signed_in: true )
      return current_user if current_user.is_a? String # assume that it's the actual email in this case
      return nil unless user_signed_in
      user_email = nil
      unless current_user.nil?
        # LoggingHelper.debug "current_user=#{current_user}"
        # LoggingHelper.debug "current_user.name=#{current_user.name}"
        # LoggingHelper.debug "current_user.email=#{current_user.email}"
        user_email = current_user.email
      end
      user_email
    end

  end

end
