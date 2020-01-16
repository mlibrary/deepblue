# frozen_string_literal: true

module Deepblue

  require_relative './abstract_event_behavior'

  class EmailError < AbstractEventError
  end

  module EmailBehavior
    include AbstractEventBehavior

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

    def email_address_rds
      rv = EmailHelper.notification_email # will be nil on developer's machine
      rv
    end

    def email_address_rds_deepblue
      rv = EmailHelper.contact_email
      rv
    end

    def email_address_user( current_user )
      rv = EmailHelper.user_email_from current_user
      rv
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
      attributes, ignore_blank_key_values = attributes_for_email_event_create_rds
      email_key_values = {}
      email_key_values = map_email_attributes!( event: EVENT_CREATE,
                                                attributes: attributes,
                                                ignore_blank_key_values: ignore_blank_key_values,
                                                **email_key_values )
      email_event_notification( to: email_address_rds,
                                to_note: 'RDS',
                                from: email_address_rds,
                                subject: Deepblue::EmailHelper.t( "hyrax.email.subject.work_created" ),
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
      to_from = email_address_user( current_user )
      work_title = title.join( ' ' )
      work_url = data_set_url
      work_depositor = ::Deepblue::EmailHelper.depositor( curation_concern: self )
      # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
      #                                      Deepblue::LoggingHelper.called_from,
      #                                      "to_from=#{to_from}",
      #                                      "work_title=#{work_title}",
      #                                      "work_url=#{work_url}",
      #                                      "work_depositor=#{work_depositor}",
      #                                      "" ]
      body = ::Deepblue::EmailHelper.t( 'hyrax.email.notify_user_work_created_html',
                                        title: ::Deepblue::EmailHelper.escape_html( work_title ),
                                        work_url: work_url,
                                        depositor: work_depositor )
      email_notification( to: to_from,
                          from: to_from,
                          content_type: "text/html",
                          subject: Deepblue::EmailHelper.t( "hyrax.email.subject.work_created" ),
                          body: body,
                          current_user: current_user,
                          event: EVENT_CREATE,
                          event_note: event_note,
                          id: for_email_id )
    end

    def email_event_destroy_rds( current_user:, event_note: '' )
      attributes, ignore_blank_key_values = attributes_for_email_event_destroy_rds
      email_event_notification( to: email_address_rds,
                                to_note: 'RDS',
                                from: email_address_rds,
                                subject: Deepblue::EmailHelper.t( "hyrax.email.subject.work_deleted" ),
                                attributes: attributes,
                                current_user: current_user,
                                event: EVENT_DESTROY,
                                event_note: event_note,
                                id: for_email_id,
                                ignore_blank_key_values: ignore_blank_key_values )
    end

    def email_event_globus_rds( current_user:, event_note: )
      attributes, ignore_blank_key_values = attributes_for_email_event_globus_rds
      email_event_notification( to: email_address_rds,
                                to_note: 'RDS',
                                from: email_address_rds,
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
      email_event_notification( to: email_address_rds,
                                to_note: 'RDS',
                                from: email_address_rds,
                                subject: Deepblue::EmailHelper.t( "hyrax.email.subject.work_published" ),
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
      work_title = ::Deepblue::EmailHelper.work_title work: self
      work_title = ::Deepblue::EmailHelper.escape_html( work_title )
      work_url = data_set_url
      work_depositor = ::Deepblue::EmailHelper.depositor( curation_concern: self )
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           #"to_from=#{to_from}",
                                           "work_title=#{work_title}",
                                           "work_url=#{work_url}",
                                           "work_depositor=#{work_depositor}",
                                           "" ]
      # for the work's authoremail
      body = ::Deepblue::EmailHelper.t( 'hyrax.email.notify_user_work_published_html',
                                        title: work_title,
                                        work_url: work_url,
                                        depositor: work_depositor )
      email_notification( to: work_depositor,
                          from: work_depositor,
                          content_type: "text/html",
                          subject: Deepblue::EmailHelper.t( "hyrax.email.subject.work_published" ),
                          body: body,
                          current_user: current_user,
                          event: EVENT_PUBLISH,
                          event_note: event_note,
                          id: for_email_id )
      return if work_depositor == self.depositor
      work_depositor = self.depositor
      body = Deepblue::EmailHelper.t( 'hyrax.email.notify_user_work_published_html',
                                      title: work_title,
                                      work_url: work_url,
                                      depositor: work_depositor )
      email_notification( to: work_depositor,
                          from: work_depositor,
                          content_type: "text/html",
                          subject: Deepblue::EmailHelper.t( "hyrax.email.subject.work_published" ),
                          body: body,
                          current_user: current_user,
                          event: EVENT_PUBLISH,
                          event_note: event_note,
                          id: for_email_id )
    end

    def email_event_unpublish_rds( current_user:, event_note: '' )
      attributes, ignore_blank_key_values = attributes_for_email_event_unpublish_rds
      email_event_notification( to: email_address_rds,
                                to_note: 'RDS',
                                from: email_address_rds,
                                subject: Deepblue::EmailHelper.t( "hyrax.email.subject.work_unpublished" ),
                                attributes: attributes,
                                current_user: current_user,
                                event: EVENT_UNPUBLISH,
                                event_note: event_note,
                                id: for_email_id,
                                ignore_blank_key_values: ignore_blank_key_values )
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

        EmailHelper.send_email( to: to, from: from, subject: subject, body: body, content_type: content_type ) if send_it
        class_name = for_email_class.name
        EmailHelper.log( class_name: class_name,
                         current_user: current_user,
                         event: event,
                         event_note: event_note,
                         id: id,
                         to: to,
                         from: from,
                         subject: subject,
                         message: message,
                         body: body,
                         **email_key_values ) if send_it
      end

      def email_event_notification( to:,
                                    to_note:,
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
        EmailHelper.send_email( to: to, from: from, subject: subject, body: body ) if send_it
        class_name = for_email_class.name
        EmailHelper.log( class_name: class_name,
                         current_user: current_user,
                         event: event,
                         event_note: event_note,
                         id: id,
                         to: to,
                         from: from,
                         subject: subject,
                         message: message,
                         body: body,
                         **email_key_values ) if send_it
        return nil unless return_email_parameters
        parameters = { to: to,
                       to_note: to_note,
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

  end

end
