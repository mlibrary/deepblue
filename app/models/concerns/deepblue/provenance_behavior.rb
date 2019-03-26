# frozen_string_literal: true

module Deepblue

  require_relative './abstract_event_behavior'

  class ProvenanceLogError < AbstractEventError
  end

  module ProvenanceBehavior
    include AbstractEventBehavior

    def attributes_all_for_provenance
      %i[]
    end

    def attributes_brief_for_provenance
      %i[]
    end

    def attributes_virus_for_provenance
      attributes_brief_for_provenance
    end

    def attributes_update_for_provenance
      attributes_all_for_provenance
    end

    def attributes_for_provenance_add
      return attributes_brief_for_provenance, IGNORE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_characterize
      return attributes_brief_for_provenance, IGNORE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_create
      return attributes_all_for_provenance, USE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_create_derivative
      return attributes_brief_for_provenance, USE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_destroy
      return attributes_all_for_provenance, USE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_fixity_check
      return attributes_brief_for_provenance, IGNORE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_ingest
      return attributes_all_for_provenance, USE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_migrate
      return attributes_brief_for_provenance, IGNORE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_mint_doi
      return attributes_all_for_provenance, USE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_publish
      return attributes_all_for_provenance, USE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_tombstone
      return attributes_all_for_provenance, USE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_unpublish
      return attributes_all_for_provenance, USE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_update
      return attributes_update_for_provenance, IGNORE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_update_version
      return attributes_update_for_provenance, IGNORE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_upload
      return attributes_all_for_provenance, USE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_virus_scan
      return attributes_virus_for_provenance, IGNORE_BLANK_KEY_VALUES
    end

    def attributes_for_provenance_workflow
      return attributes_brief_for_provenance, IGNORE_BLANK_KEY_VALUES
    end

    def attributes_cache_fetch( event:, id: for_provenance_id )
      key = attributes_cache_key( event: event, id: id )
      rv = Rails.cache.fetch( key )
      rv
    end

    def attributes_cache_key( event:, id: )
      "#{id}.#{event}"
    end

    def attributes_cache_write( event:, id: for_provenance_id, attributes: )
      key = attributes_cache_key( event: event, id: id )
      Rails.cache.write( key, attributes )
    end

    def for_provenance_event_cache_exist?( event:, id: for_provenance_id )
      key = for_provenance_event_cache_key( event: event, id: id )
      rv = Rails.cache.exist?( key )
      rv
    end

    def for_provenance_event_cache_fetch( event:, id: for_provenance_id )
      key = for_provenance_event_cache_key( event: event, id: id )
      rv = Rails.cache.fetch( key )
      rv
    end

    def for_provenance_event_cache_key( event:, id: )
      "#{id}.#{event}.provenance"
    end

    def for_provenance_event_cache_write( event:, id: for_provenance_id, value: DateTime.now )
      key = for_provenance_event_cache_key( event: event, id: id )
      Rails.cache.write( key, value, expires_in: 12.hours )
    end

    def for_provenance_class
      for_provenance_object.class
    end

    def for_provenance_id
      for_provenance_object.id
    end

    def for_provenance_ignore_empty_attributes
      true
    end

    def for_provenance_object
      self
    end

    def for_provenance_route
      "route to #{for_provenance_object.id}"
    end

    def for_provenance_user( current_user )
      return '' if current_user.blank?
      return current_user if current_user.is_a? String
      EmailHelper.user_email_from( current_user )
    end

    def map_provenance_attributes!( event:, attributes:, ignore_blank_key_values:, **prov_key_values )
      prov_object = for_provenance_object
      # prov_object_class = prov_object.class.name
      if attributes.present?
        attributes.each do |attribute|
          next if map_provenance_attributes_override!( event: event,
                                                       attribute: attribute,
                                                       ignore_blank_key_values: ignore_blank_key_values,
                                                       prov_key_values: prov_key_values )
          value = case attribute.to_s
                  when 'id'
                    for_provenance_id
                  when 'location'
                    for_provenance_route
                  when 'route'
                    for_provenance_route
                  when 'date_created'
                    prov_object[:date_created].blank? ? '' : prov_object[:date_created]
                  else
                    if prov_object.has_attribute? attribute
                      prov_object[attribute]
                    else
                      'MISSING_ATTRIBUTE'
                    end
                    # begin
                    #   prov_object[attribute]
                    # rescue Exception => e
                    #   puts "attribute='#{attribute}' #{e}"
                    #   raise e
                    # end
                  end
          value = '' if value.nil?
          if ignore_blank_key_values
            prov_key_values[attribute] = value if value.present?
          else
            prov_key_values[attribute] = value
          end
        end
      end
      prov_key_values
    end

    def map_provenance_attributes_for_update( current_user, event_note, provenance_attribute_values_before_update )
      Rails.logger.debug ">>>>>>"
      Rails.logger.debug "map_provenance_attributes_for_update"
      Rails.logger.debug "provenance_attribute_values_before_update=#{ActiveSupport::JSON.encode provenance_attribute_values_before_update}"
      Rails.logger.debug ">>>>>>"
      return nil if provenance_attribute_values_before_update.blank?
      attributes, ignore_blank_key_values = attributes_for_provenance_update
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: EVENT_UPDATE,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values )
      # only the changed values
      Rails.logger.debug ">>>>>>"
      Rails.logger.debug "map_provenance_attributes_for_update"
      Rails.logger.debug "before reject=#{ActiveSupport::JSON.encode prov_key_values}"
      Rails.logger.debug ">>>>>>"
      prov_key_values.reject! { |attribute, value| value == provenance_attribute_values_before_update[attribute] }
      Rails.logger.debug ">>>>>>"
      Rails.logger.debug "map_provenance_attributes_for_update"
      Rails.logger.debug "after reject=#{ActiveSupport::JSON.encode prov_key_values}"
      Rails.logger.debug ">>>>>>"
      prov_key_values
    end

    # override this if there is anything extra to add
    # return true if handled
    def map_provenance_attributes_override!( event:,                    # rubocop:disable Lint/UnusedMethodArgument
                                             attribute:,                # rubocop:disable Lint/UnusedMethodArgument
                                             ignore_blank_key_values:,  # rubocop:disable Lint/UnusedMethodArgument
                                             prov_key_values: )         # rubocop:disable Lint/UnusedMethodArgument

      handled = false
      return handled
    end

    def provenance_attribute_values_for_snapshot( attributes:,
                                                  current_user:,
                                                  event:,
                                                  event_note:,
                                                  ignore_blank_key_values:,
                                                  **added_prov_key_values )

      prov_key_values = ProvenanceHelper.logger_initialize_key_values(user_email: for_provenance_user(current_user ),
                                                                      event_note: event_note,
                                                                      **added_prov_key_values )
      prov_key_values = map_provenance_attributes!( event: event,
                                                    attributes: attributes,
                                                    ignore_blank_key_values: ignore_blank_key_values,
                                                    **prov_key_values )
      prov_key_values
    end

    def provenance_attribute_values_for_update( current_user:, event_note: '' )
      attributes, _ignore_blank_key_values = attributes_for_provenance_update
      provenance_attribute_values_for_snapshot( attributes: attributes,
                                                current_user: current_user,
                                                event: EVENT_UPDATE,
                                                event_note: event_note,
                                                ignore_blank_key_values: false )
    end

    def provenance_characterize( current_user:, event_note: '', calling_class:, **added_prov_key_values )
      event = EVENT_CHARACTERIZE
      attributes, ignore_blank_key_values = attributes_for_provenance_add
      added_prov_key_values = { calling_class: calling_class }.merge added_prov_key_values
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      attributes, ignore_blank_key_values = attributes_for_provenance_characterize
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values,
                            prov_key_values: prov_key_values )
    end

    def provenance_child_add( current_user:, child_id:, event_note: '', **added_prov_key_values )
      event = EVENT_CHILD_ADD
      added_prov_key_values = { child_id: child_id }.merge added_prov_key_values
      attributes, ignore_blank_key_values = attributes_for_provenance_add
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: nil,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: true,
                            prov_key_values: prov_key_values )
    end

    def provenance_child_remove( current_user:, child_id:, event_note: '', **added_prov_key_values )
      event = EVENT_CHILD_REMOVE
      added_prov_key_values = { child_id: child_id }.merge added_prov_key_values
      attributes, ignore_blank_key_values = attributes_for_provenance_add
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: nil,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: true,
                            prov_key_values: prov_key_values )
    end

    def provenance_create( current_user:, event_note: '' )
      attributes, ignore_blank_key_values = attributes_for_provenance_create
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: EVENT_CREATE,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values )
    end

    def provenance_create_derivative( current_user:, event_note: '', calling_class:, **added_prov_key_values )
      event = EVENT_CREATE_DERIVATIVE
      attributes, ignore_blank_key_values = attributes_for_provenance_add
      added_prov_key_values = { calling_class: calling_class }.merge added_prov_key_values
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      attributes, ignore_blank_key_values = attributes_for_provenance_create_derivative
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values,
                            prov_key_values: prov_key_values )
    end

    def provenance_destroy( current_user:, event_note: '' )
      unless DeepBlueDocs::Application.config.provenance_log_redundant_events
        return if for_provenance_event_cache_exist?( event: EVENT_DESTROY )
      end
      attributes, ignore_blank_key_values = attributes_for_provenance_destroy
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: EVENT_DESTROY,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values )
    end

    def provenance_fixity_check( current_user:,
                                 event_note: '',
                                 fixity_check_status:,
                                 fixity_check_note:,
                                 **added_prov_key_values )
      event = EVENT_FIXITY_CHECK
      attributes, ignore_blank_key_values = attributes_for_provenance_fixity_check
      added_prov_key_values = { fixity_check_status: fixity_check_status,
                                fixity_check_note: fixity_check_note }.merge added_prov_key_values
      event_note = fixity_check_status if event_note.blank?
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: nil,
                            event: event,
                            current_user: current_user,
                            event_note: event_note,
                            ignore_blank_key_values: false,
                            prov_key_values: prov_key_values )
    end

    def provenance_ingest( current_user:,
                           event_note: '',
                           calling_class:,
                           ingest_id:,
                           ingester:,
                           ingest_timestamp:,
                           **added_prov_key_values )
      event = EVENT_INGEST
      attributes, ignore_blank_key_values = attributes_for_provenance_ingest
      added_prov_key_values = { calling_class: calling_class,
                                ingest_id: ingest_id,
                                ingester: ingester,
                                ingest_timestamp: ingest_timestamp }.merge added_prov_key_values
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: nil,
                            event: event,
                            current_user: current_user,
                            event_note: event_note,
                            ignore_blank_key_values: false,
                            prov_key_values: prov_key_values )
    end

    def provenance_log_for_event( attributes: [],
                                  current_user:,
                                  event:,
                                  event_note: '',
                                  ignore_blank_key_values: false,
                                  **prov_key_values )

      raise ProvenanceLogError( "Unknown provenance log event: #{event}" ) unless EVENTS.contains( event )
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values,
                            prov_key_values: prov_key_values )
    end

    def provenance_migrate( current_user:, event_note: '', migrate_direction:, parent_id: nil, **added_prov_key_values )
      event = EVENT_MIGRATE
      attributes, ignore_blank_key_values = attributes_for_provenance_migrate
      added_prov_key_values = if parent_id.present?
                                { migrate_direction: migrate_direction, parent_id: parent_id }.merge added_prov_key_values
                              else
                                { migrate_direction: migrate_direction }.merge added_prov_key_values
                              end
      event_note = migrate_direction if event_note.blank?
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: nil,
                            event: event,
                            current_user: current_user,
                            event_note: event_note,
                            ignore_blank_key_values: false,
                            prov_key_values: prov_key_values )
    end

    def provenance_mint_doi( current_user:, event_note: '' )
      attributes, ignore_blank_key_values = attributes_for_provenance_mint_doi
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: EVENT_MINT_DOI,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values )
    end

    def provenance_publish( current_user:, event_note: '', message: '' )
      attributes, ignore_blank_key_values = attributes_for_provenance_publish
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: EVENT_PUBLISH,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  message: message )
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: EVENT_PUBLISH,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values,
                            prov_key_values: prov_key_values )
    end

    def provenance_tombstone( current_user:,
                              event_note: '',
                              epitaph:,
                              depositor_at_tombstone:,
                              visibility_at_tombstone: )

      attributes, ignore_blank_key_values = attributes_for_provenance_tombstone
      event = EVENT_TOMBSTONE
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: false,
                                                                  epitaph: epitaph,
                                                                  depositor_at_tombstone: depositor_at_tombstone,
                                                                  visibility_at_tombstone: visibility_at_tombstone )
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values,
                            prov_key_values: prov_key_values )
    end

    def provenance_unpublish( current_user:, event_note: '' )
      attributes, ignore_blank_key_values = attributes_for_provenance_unpublish
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: EVENT_UNPUBLISH,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values )
    end

    def provenance_update( current_user:, event_note: '', **added_prov_key_values )
      attributes, ignore_blank_key_values = attributes_for_provenance_update
      event = EVENT_UPDATE
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values,
                            prov_key_values: prov_key_values )
    end

    def provenance_log_update_after( current_user:, event_note: '', update_attr_key_values: nil )
      # LoggingHelper.bold_debug [ "provenance_log_update_after", 'update_attr_key_values:', update_attr_key_values ]
      update_attr_key_values = ProvenanceHelper.update_attribute_key_values( curation_concern: for_provenance_object,
                                                                             **update_attr_key_values )
      # LoggingHelper.bold_debug [ "provenance_log_update_after", 'update_attr_key_values:', update_attr_key_values ]
      provenance_update( current_user: current_user, event_note: event_note, **update_attr_key_values ) if update_attr_key_values.present?
    end

    def provenance_log_update_before( form_params: )
      # LoggingHelper.bold_debug [ "provenance_log_update_before",
      #                            ActiveSupport::JSON.encode( form_params ),
      #                            'form_params:',
      #                            form_params ]
      update_attr_key_values = ProvenanceHelper.form_params_to_update_attribute_key_values( curation_concern: for_provenance_object,
                                                                                            form_params: form_params )
      # LoggingHelper.bold_debug [ "provenance_log_update_before", 'update_attr_key_values:', update_attr_key_values ]
      update_attr_key_values
    end

    def provenance_update_version( current_user:,
                                   event_note: '',
                                   new_create_date:,
                                   new_revision_id:,
                                   prior_create_date:,
                                   prior_revision_id:,
                                   revision_id:,
                                   **added_prov_key_values )
      attributes, ignore_blank_key_values = attributes_for_provenance_update_version
      event = EVENT_UPDATE_VERSION
      added_prov_key_values = { new_create_date: new_create_date,
                                new_revision_id: new_revision_id,
                                prior_create_date: prior_create_date,
                                prior_revision_id: prior_revision_id,
                                revision_id: revision_id }.merge added_prov_key_values
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: attributes,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: ignore_blank_key_values,
                            prov_key_values: prov_key_values )
    end

    def provenance_upload( current_user:, event_note: '' )
      provenance_log_event( attributes: attributes_for_provenance_upload,
                            current_user: current_user,
                            event: EVENT_UPLOAD,
                            event_note: event_note,
                            ignore_blank_key_values: true )
    end

    def provenance_virus_scan( current_user: nil,
                               event_note: '',
                               scan_result:,
                               **added_prov_key_values )
      event = EVENT_VIRUS_SCAN
      attributes, ignore_blank_key_values = attributes_for_provenance_virus_scan
      added_prov_key_values = { scan_result: scan_result }.merge added_prov_key_values
      event_note = scan_result if event_note.blank?
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: nil,
                            event: event,
                            current_user: current_user,
                            event_note: event_note,
                            ignore_blank_key_values: false,
                            prov_key_values: prov_key_values )
    end

    def provenance_workflow( current_user: nil,
                             event_note: '',
                             workflow_name:,
                             workflow_state_prior:,
                             workflow_state:,
                             **added_prov_key_values )
      event = EVENT_WORKFLOW
      attributes, ignore_blank_key_values = attributes_for_provenance_workflow
      added_prov_key_values = { workflow_name: workflow_name,
                                workflow_state_prior: workflow_state_prior,
                                workflow_state: workflow_state }.merge added_prov_key_values
      event_note = workflow_state if event_note.blank?
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: ignore_blank_key_values,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: nil,
                            event: event,
                            current_user: current_user,
                            event_note: event_note,
                            ignore_blank_key_values: false,
                            prov_key_values: prov_key_values )
    end

    protected

      def provenance_log_event( attributes:,
                                current_user:,
                                event:,
                                event_note:,
                                ignore_blank_key_values:,
                                id: for_provenance_id,
                                prov_key_values: nil )

        if prov_key_values.blank?
          prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes,
                                                                      current_user: current_user,
                                                                      event: event,
                                                                      event_note: event_note,
                                                                      ignore_blank_key_values: ignore_blank_key_values )
        end
        class_name = for_provenance_class.name
        for_provenance_event_cache_write( event: event, id: id )
        ProvenanceHelper.log( class_name: class_name, id: id, event: event, event_note: event_note, **prov_key_values )
      end

  end

end

module ActiveFedora
  module PersistenceExt

    def self.prepended( base )
      base.singleton_class.prepend( ClassMethods )
    end

    module ClassMethods

      # def update( attributes )
      #   Rails.logger.debug "ActiveFedora::Persistence.update(#{ActiveSupport::JSON.encode attributes})"
      #   if respond_to? :provenance_attribute_values_before_update
      #     provenance_attribute_values_before_update = provenance_attribute_values_for_update( current_user: '' )
      #     Rails.logger.debug ">>>>>>"
      #     Rails.logger.debug "provenance_log_update_before"
      #     Rails.logger.debug "provenance_attribute_values_before_update=#{ActiveSupport::JSON.encode provenance_attribute_values_before_update}"
      #     Rails.logger.debug ">>>>>>"
      #   end
      #
      #   rv = super( attributes )
      #
      #   if respond_to? :provenance_attribute_values_before_update
      #     Rails.logger.debug ">>>>>>"
      #     Rails.logger.debug "provenance_log_update_after"
      #     Rails.logger.debug "provenance_attribute_values_before_update=#{ActiveSupport::JSON.encode provenance_attribute_values_before_update}"
      #     Rails.logger.debug ">>>>>>"
      #     provenance_update( current_user: '',
      #                        provenance_attribute_values_before_update: provenance_attribute_values_before_update )
      #   end
      #   rv
      # end

    end

    # def to_pretty_json
    #   JSON.pretty_generate(self)
    # end

  end
end
