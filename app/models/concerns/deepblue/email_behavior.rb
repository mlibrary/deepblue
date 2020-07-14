# frozen_string_literal: true

module Deepblue

  require_relative './abstract_event_behavior'

  # class EmailError < AbstractEventError
  # end

  module EmailBehavior
    include AbstractEventBehavior

    EMAIL_BEHAVIOR_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.email_behavior_debug_verbose

    def attributes_all_for_email
      %i[]
    end

    def attributes_brief_for_email
      %i[]
    end

    def attributes_standard_for_email
      %i[]
    end

    def attributes_for_email_event_create_rds
      return attributes_standard_for_email, USE_BLANK_KEY_VALUES
    end

    def attributes_for_email_event_create_user
      return attributes_standard_for_email
    end

    def attributes_for_email_event_destroy_rds
      return attributes_standard_for_email, USE_BLANK_KEY_VALUES
    end

    def attributes_for_email_event_globus_rds
      return attributes_brief_for_email, IGNORE_BLANK_KEY_VALUES
    end

    def attributes_for_email_event_publish_rds
      return attributes_standard_for_email, USE_BLANK_KEY_VALUES
    end

    def attributes_for_email_event_unpublish_rds
      return attributes_standard_for_email, USE_BLANK_KEY_VALUES
    end

    def email_attribute_values_for_snapshot( attributes:,
                                             current_user:,
                                             event:,
                                             event_note:,
                                             to_note:,
                                             ignore_blank_key_values:,
                                             **added_email_key_values )

      email_key_values = { user_email: for_email_user( current_user ) }
      email_key_values.merge!( event_note: event_note ) if event_note.present?
      email_key_values.merge!( to_note: to_note ) if to_note.present?
      email_key_values.merge!( added_email_key_values ) if added_email_key_values.present?
      email_key_values = map_email_attributes!( event: event,
                                                attributes: attributes,
                                                ignore_blank_key_values: ignore_blank_key_values,
                                                **email_key_values )
      email_key_values
    end

    def email_address_workflow
      to = EmailHelper.notification_email_to # will be nil on developer's machine
      from = EmailHelper.notification_email_from # will be nil on developer's machine
      [to, 'RDS-workflow-event', from]
    end

    def email_address_user( current_user )
      to = EmailHelper.user_email_from current_user
      from = EmailHelper.notification_email_from # will be nil on developer's machine
      [to, 'user-workflow-event', from]
    end

    def email_compose_body( message:, email_key_values: )
      body = StringIO.new
      body.puts message.to_s if message.present?
      email_key_values.each_pair do |key, value|
        label = for_email_label key
        value = for_email_value( key, value )
        body.puts "#{label}#{value}"
      end
      body.string
    end

    def email_event_create_rds( current_user:, event_note: '', return_email_parameters: false, send_it: true )
      return unless DeepBlueDocs::Application.config.use_email_notification_for_creation_events
      attributes, ignore_blank_key_values = attributes_for_email_event_create_rds
      email_key_values = {}
      email_key_values = map_email_attributes!( event: EVENT_CREATE,
                                                attributes: attributes,
                                                ignore_blank_key_values: ignore_blank_key_values,
                                                **email_key_values )
      cc_type = EmailHelper.curation_concern_type( curation_concern: self )
      to, to_note, from = email_address_workflow
      email_event_notification( to: to,
                                to_note: to_note,
                                from: from,
                                subject: Deepblue::EmailHelper.t( "hyrax.email.subject.#{cc_type}_created" ),
                                attributes: attributes,
                                current_user: current_user,
                                event: EVENT_CREATE,
                                event_note: event_note,
                                id: for_email_id,
                                ignore_blank_key_values: ignore_blank_key_values,
                                return_email_parameters: return_email_parameters,
                                send_it: send_it,
                                email_key_values: email_key_values )
    end

    def email_event_create_user( current_user:, event_note: '' )
      return unless DeepBlueDocs::Application.config.use_email_notification_for_creation_events
      to, _to_note, from = email_address_user( current_user )
      cc_title = EmailHelper.cc_title curation_concern: self
      cc_type = EmailHelper.curation_concern_type( curation_concern: self )
      cc_url = EmailHelper.curation_concern_url( curation_concern: self )
      cc_depositor = EmailHelper.cc_depositor( curation_concern: self )
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "to, to_note, from=#{to}, #{_to_note}, #{from}",
                                           "cc_type=#{cc_type}",
                                           "cc_title=#{cc_title}",
                                           "cc_url=#{cc_url}",
                                           "cc_depositor=#{cc_depositor}",
                                           "" ] if EMAIL_BEHAVIOR_DEBUG_VERBOSE
      body = EmailHelper.t( "hyrax.email.notify_user_#{cc_type}_created_html",
                            title: EmailHelper.escape_html( cc_title ),
                            url: cc_url,
                            depositor: cc_depositor,
                            contact_us_at: ::Deepblue::EmailHelper.contact_us_at )
      email_notification( to: to,
                          from: from,
                          content_type: "text/html",
                          subject: Deepblue::EmailHelper.t( "hyrax.email.subject.#{cc_type}_created" ),
                          body: body,
                          current_user: current_user,
                          event: EVENT_CREATE,
                          event_note: event_note,
                          id: for_email_id )
    end

    def email_event_destroy_rds( current_user:, event_note: '' )
      attributes, ignore_blank_key_values = attributes_for_email_event_destroy_rds
      cc_type = EmailHelper.curation_concern_type( curation_concern: self )
      to, to_note, from = email_address_workflow
      body = email_event_notification( to: to,
                                       to_note: to_note,
                                       from: from,
                                       subject: Deepblue::EmailHelper.t( "hyrax.email.subject.#{cc_type}_deleted" ),
                                       attributes: attributes,
                                       current_user: current_user,
                                       event: EVENT_DESTROY,
                                       event_note: event_note,
                                       id: for_email_id,
                                       ignore_blank_key_values: ignore_blank_key_values,
                                       return_email_body: true )
      ::Deepblue::JiraHelper.jira_add_comment( curation_concern: self, event: EVENT_DESTROY, comment: body )
    end

    def email_event_globus_rds( current_user:, event_note: )
      attributes, ignore_blank_key_values = attributes_for_email_event_globus_rds
      to, to_note, from = email_address_workflow
      email_event_notification( to: to,
                                to_note: to_note,
                                from: from,
                                subject: for_email_subject( subject_rest: "Globus #{event_note}" ),
                                attributes: attributes,
                                current_user: current_user,
                                event: EVENT_GLOBUS,
                                event_note: event_note,
                                id: for_email_id,
                                ignore_blank_key_values: ignore_blank_key_values )
    end

    def email_event_publish_rds( current_user:, event_note: '', message: '' )
      attributes, ignore_blank_key_values = attributes_for_email_event_publish_rds
      cc_type = EmailHelper.curation_concern_type( curation_concern: self )
      to, to_note, from = email_address_workflow
      email_event_notification( to: to,
                                to_note: to_note,
                                from: from,
                                subject: Deepblue::EmailHelper.t( "hyrax.email.subject.#{cc_type}_published" ),
                                attributes: attributes,
                                current_user: current_user,
                                event: EVENT_PUBLISH,
                                event_note: event_note,
                                message: message,
                                id: for_email_id,
                                ignore_blank_key_values: ignore_blank_key_values )
    end

    def email_event_publish_user( current_user:, event_note: '', message: '' )
      # to_from = email_address_user( current_user )
      cc_title = EmailHelper.cc_title curation_concern: self
      cc_title = EmailHelper.escape_html( cc_title )
      cc_type = EmailHelper.curation_concern_type( curation_concern: self )
      cc_url = EmailHelper.curation_concern_url( curation_concern: self )
      cc_depositor = EmailHelper.cc_depositor( curation_concern: self )
      cc_contact_email = EmailHelper.cc_contact_email( curation_concern: self ) # i.e. authoremail for works
      template_key = "hyrax.email.notify_user_#{cc_type}_published_html"
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           #"to_from=#{to_from}",
                                           "cc_title=#{cc_title}",
                                           "cc_type=#{cc_type}",
                                           "cc_url=#{cc_url}",
                                           "cc_depositor=#{cc_depositor}",
                                           "cc_contact_email=#{cc_contact_email}",
                                           "template_key=#{template_key}",
                                           "" ] if EMAIL_BEHAVIOR_DEBUG_VERBOSE
      # for the work's authoremail
      body = EmailHelper.t( template_key,
                            title: cc_title,
                            url: cc_url,
                            depositor: cc_depositor,
                            contact_us_at: ::Deepblue::EmailHelper.contact_us_at )
      email_notification( to: cc_depositor,
                          from: EmailHelper.notification_email_from,
                          content_type: "text/html",
                          subject: Deepblue::EmailHelper.t( "hyrax.email.subject.#{cc_type}_published" ),
                          body: body,
                          current_user: current_user,
                          event: EVENT_PUBLISH,
                          event_note: event_note,
                          id: for_email_id )
      ::Deepblue::JiraHelper.jira_add_comment( curation_concern: self, event: EVENT_PUBLISH, comment: body )
      return if cc_contact_email.blank? || cc_depositor == cc_contact_email
      body = EmailHelper.t( template_key,
                            title: cc_title,
                            url: cc_url,
                            depositor: cc_contact_email,
                            contact_us_at: ::Deepblue::EmailHelper.contact_us_at )
      email_notification( to: cc_contact_email,
                          from: EmailHelper.notification_email_from,
                          content_type: "text/html",
                          subject: Deepblue::EmailHelper.t( "hyrax.email.subject.#{cc_type}_published" ),
                          body: body,
                          current_user: current_user,
                          event: EVENT_PUBLISH,
                          event_note: event_note,
                          id: for_email_id )
    end

    def email_event_unpublish_rds( current_user:, event_note: '' )
      attributes, ignore_blank_key_values = attributes_for_email_event_unpublish_rds
      cc_type = EmailHelper.curation_concern_type( curation_concern: self )
      to, to_note, from = email_address_workflow
      body = email_event_notification( to: to,
                                       to_note: to_note,
                                       from: from,
                                       subject: Deepblue::EmailHelper.t( "hyrax.email.subject.#{cc_type}_unpublished" ),
                                       attributes: attributes,
                                       current_user: current_user,
                                       event: EVENT_UNPUBLISH,
                                       event_note: event_note,
                                       id: for_email_id,
                                       ignore_blank_key_values: ignore_blank_key_values,
                                       return_email_body: true )
      ::Deepblue::JiraHelper.jira_add_comment( curation_concern: self, event: EVENT_UNPUBLISH, comment: body )
    end

    def email_create_to_user( current_user:, event_note: '' ) # TODO: delete this method
      email_create( current_user: current_user, event_note: event_note )
    end

    def for_email_class
      for_email_object.class
    end

    def for_email_id
      for_email_object.id
    end

    def for_email_ignore_empty_attributes
      true
    end

    def for_email_label( key )
      "#{key}: "
    end

    def for_email_object
      self
    end

    def for_email_route
      "route to #{for_email_object.id}"
    end

    def for_email_subject( subject_rest: )
      "DBD: #{subject_rest}"
    end

    def for_email_value( key, value )
      return '' if value.blank?
      if value.respond_to? :each
        value = if 1 == value.size
                  value[0]
                else
                  value.join( for_email_value_sep( key: key ) )
                end
      end
      value
    end

    def for_email_value_sep( key: )
      rv = case key.to_s
           when 'title'
             ' '
           else
             '; '
           end
      rv
    end

    def for_email_user( current_user )
      return '' if current_user.blank?
      return current_user if current_user.is_a? String
      EmailHelper.user_email_from( current_user )
    end

    def map_email_attributes!( event:, attributes:, ignore_blank_key_values:, **email_key_values )
      prov_object = for_email_object
      if attributes.present?
        attributes.each do |attribute|
          next if map_email_attributes_override!( event: event,
                                                  attribute: attribute,
                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                  email_key_values: email_key_values )
          value = case attribute.to_s
                  when 'id'
                    for_email_id
                  when 'location'
                    for_email_route
                  when 'route'
                    for_email_route
                  when 'date_created'
                    prov_object[:date_created].blank? ? '' : prov_object[:date_created]
                  else
                    prov_object[attribute]
                  end
          value = '' if value.nil?
          if ignore_blank_key_values
            email_key_values[attribute] = value if value.present?
          else
            email_key_values[attribute] = value
          end
        end
      end
      email_key_values
    end

    # override this if there is anything extra to add
    # return true if handled
    def map_email_attributes_override!( event:,                    # rubocop:disable Lint/UnusedMethodArgument
                                        attribute:,                # rubocop:disable Lint/UnusedMethodArgument
                                        ignore_blank_key_values:,  # rubocop:disable Lint/UnusedMethodArgument
                                        email_key_values: )        # rubocop:disable Lint/UnusedMethodArgument

      handled = false
      return handled
    end

    protected

      def email_notification( to:,
                              cc: nil,
                              bcc: nil,
                              from:,
                              subject:,
                              current_user:,
                              event:,
                              event_note:,
                              message: '',
                              id:,
                              body:,
                              content_type: nil,
                              send_it: true,
                              email_key_values: {} )

        email_sent = false
        email_sent = EmailHelper.send_email( to: to,
                                             cc: cc,
                                             bcc: bcc,
                                             from: from,
                                             subject: subject,
                                             body: body,
                                             content_type: content_type ) if send_it
        class_name = for_email_class.name
        EmailHelper.log( class_name: class_name,
                         current_user: current_user,
                         event: event,
                         event_note: event_note,
                         id: id,
                         to: to,
                         cc: cc,
                         bcc: bcc,
                         from: from,
                         subject: subject,
                         message: message,
                         body: body,
                         email_sent: email_sent,
                         **email_key_values ) if send_it
      end

      def email_event_notification( to:,
                                    to_note:,
                                    cc: nil,
                                    bcc: nil,
                                    from:,
                                    subject:,
                                    attributes:,
                                    current_user:,
                                    event:,
                                    event_note:,
                                    message: '',
                                    ignore_blank_key_values:,
                                    id:,
                                    return_email_parameters: false,
                                    return_email_body: false,
                                    send_it: true,
                                    email_key_values: nil )

        if email_key_values.blank?
          email_key_values = email_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  to_note: to_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values )
        end
        event_attributes_cache_write( event: event, id: id, behavior: :EmailBehavior )
        body = email_compose_body( message: message, email_key_values: email_key_values )
        email_sent = false
        if send_it
          email_sent = EmailHelper.send_email( to: to, from: from, subject: subject, body: body )
          email_event_notification_failed( to: to,
                                           to_note: to_note,
                                           from: from,
                                           subject: subject,
                                           body: body,
                                           event: event,
                                           id: id ) unless email_sent
        end
        class_name = for_email_class.name
        EmailHelper.log( class_name: class_name,
                         current_user: current_user,
                         event: event,
                         event_note: event_note,
                         id: id,
                         to: to,
                         cc: cc,
                         bcc: bcc,
                         from: from,
                         subject: subject,
                         message: message,
                         body: body,
                         email_sent: email_sent,
                         **email_key_values ) if send_it
        return body if return_email_body
        return nil unless return_email_parameters
        parameters = { to: to,
                       to_note: to_note,
                       cc: cc,
                       bcc: bcc,
                       from: from,
                       subject: subject,
                       message: message,
                       body: body,
                       current_user: current_user,
                       event: event,
                       event_note: event_note,
                       id: id,
                       email_key_values: email_key_values }
        return parameters
      end

      def email_event_notification_failed( to:, to_note:, from:, subject:, body:, event:, id: )
        return unless event == EVENT_CREATE
        return unless to_note == 'RDS'
        EmailHelper.send_email( to: to,
                                from: from,
                                subject: "Event create email failed to send",
                                body: "Event create email failed for id #{id}" )
      end

  end

end
