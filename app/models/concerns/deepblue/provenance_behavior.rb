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

    def attributes_for_provenance_add
      attributes_brief_for_provenance
    end

    def attributes_for_provenance_characterize
      attributes_brief_for_provenance
    end

    def attributes_for_provenance_create
      attributes_all_for_provenance
    end

    def attributes_for_provenance_create_derivative
      attributes_brief_for_provenance
    end

    def attributes_for_provenance_destroy
      attributes_all_for_provenance
    end

    def attributes_for_provenance_ingest
      attributes_all_for_provenance
    end

    def attributes_for_provenance_mint_doi
      attributes_brief_for_provenance
    end

    def attributes_for_provenance_publish
      attributes_all_for_provenance
    end

    def attributes_for_provenance_tombstone
      attributes_all_for_provenance
    end

    def attributes_for_provenance_update
      attributes_all_for_provenance
    end

    def attributes_for_provenance_upload
      attributes_all_for_provenance
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
                    prov_object[:date_created].blank? ? '' : prov_object[:date_created][0]
                  else
                    prov_object[attribute]
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
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes_for_provenance_update,
                                                                  current_user: current_user,
                                                                  event: EVENT_UPDATE,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: false )
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

      prov_key_values = ProvenanceHelper.initialize_prov_key_values( user_email: for_provenance_user( current_user ),
                                                                     event_note: event_note,
                                                                     **added_prov_key_values )
      prov_key_values = map_provenance_attributes!( event: event,
                                                    attributes: attributes,
                                                    ignore_blank_key_values: ignore_blank_key_values,
                                                    **prov_key_values )
      prov_key_values
    end

    def provenance_attribute_values_for_update( current_user:, event_note: '' )
      provenance_attribute_values_for_snapshot( attributes: attributes_for_provenance_update,
                                                current_user: current_user,
                                                event: EVENT_UPDATE,
                                                event_note: event_note,
                                                ignore_blank_key_values: false )
    end

    def provenance_characterize( current_user:, event_note: '', **added_prov_key_values )
      event = EVENT_CHARACTERIZE
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes_for_provenance_add,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: true,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: attributes_for_provenance_characterize,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: true,
                            prov_key_values: prov_key_values )
    end

    def provenance_child_add( current_user:, child_id:, event_note: '', **added_prov_key_values )
      event = EVENT_CHILD_ADD
      added_prov_key_values = { child_id: child_id }.merge added_prov_key_values
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes_for_provenance_add,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: true,
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
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes_for_provenance_add,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: true,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: nil,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: true,
                            prov_key_values: prov_key_values )
    end

    def provenance_create( current_user:, event_note: '' )
      provenance_log_event( attributes: attributes_for_provenance_create,
                            current_user: current_user,
                            event: EVENT_CREATE,
                            event_note: event_note,
                            ignore_blank_key_values: false )
    end

    def provenance_create_derivative( current_user:, event_note: '', **added_prov_key_values )
      event = EVENT_CREATE_DERIVATIVE
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes_for_provenance_add,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: true,
                                                                  **added_prov_key_values )
      provenance_log_event( attributes: attributes_for_provenance_create_derivative,
                            current_user: current_user,
                            event: event,
                            event_note: event_note,
                            ignore_blank_key_values: true,
                            prov_key_values: prov_key_values )
    end

    def provenance_destroy( current_user:, event_note: '' )
      unless DeepBlueDocs::Application.config.provenance_log_redundant_events
        return if for_provenance_event_cache_exist?( event: EVENT_DESTROY )
      end
      provenance_log_event( attributes: attributes_for_provenance_destroy,
                            current_user: current_user,
                            event: EVENT_DESTROY,
                            event_note: event_note,
                            ignore_blank_key_values: false )
    end

    def provenance_ingest( current_user:,
                           event_note: '',
                           ingest_id:,
                           ingester:,
                           ingest_timestamp:,
                           **added_prov_key_values )
      event = EVENT_INGEST
      added_prov_key_values = { ingest_id: ingest_id,
                                ingester: ingester,
                                ingest_timestamp: ingest_timestamp }.merge added_prov_key_values
      prov_key_values = provenance_attribute_values_for_snapshot( attributes: attributes_for_provenance_ingest,
                                                                  current_user: current_user,
                                                                  event: event,
                                                                  event_note: event_note,
                                                                  ignore_blank_key_values: false,
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

    def provenance_mint_doi( current_user:, event_note: '' )
      provenance_log_event( attributes: attributes_for_provenance_mint_doi,
                            current_user: current_user,
                            event: EVENT_MINT_DOI,
                            event_note: event_note,
                            ignore_blank_key_values: true )
    end

    def provenance_publish( current_user:, event_note: '' )
      provenance_log_event( attributes: attributes_for_provenance_publish,
                            current_user: current_user,
                            event: EVENT_PUBLISH,
                            event_note: event_note,
                            ignore_blank_key_values: false )
    end

    def provenance_tombstone( current_user:, event_note: '' )
      provenance_log_event( attributes: attributes_for_provenance_tombstone,
                            current_user: current_user,
                            event: EVENT_TOMBSTONE,
                            event_note: event_note,
                            ignore_blank_key_values: false )
    end

    def provenance_update( current_user:, event_note: '', provenance_attribute_values_before_update: )
      prov_key_values = map_provenance_attributes_for_update( current_user,
                                                              event_note,
                                                              provenance_attribute_values_before_update )
      provenance_log_event( attributes: attributes_for_provenance_update,
                            current_user: current_user,
                            event: EVENT_UPDATE,
                            event_note: event_note,
                            ignore_blank_key_values: false,
                            prov_key_values: prov_key_values )
    end

    def provenance_log_update_after( current_user:, event_note: '' )
      provenance_attribute_values_before_update = attributes_cache_fetch( event: EVENT_UPDATE, id: for_provenance_id )
      # Rails.logger.debug ">>>>>>"
      # Rails.logger.debug "provenance_log_update_after"
      # Rails.logger.debug "provenance_attribute_values_before_update=#{ActiveSupport::JSON.encode provenance_attribute_values_before_update}"
      # Rails.logger.debug ">>>>>>"
      provenance_update( current_user: current_user,
                         event_note: event_note,
                         provenance_attribute_values_before_update: provenance_attribute_values_before_update )
    end

    def provenance_log_update_before( current_user:, event_note: '' )
      provenance_attribute_values_before_update = provenance_attribute_values_for_update( current_user: current_user,
                                                                                          event_note: event_note )
      # Rails.logger.debug ">>>>>>"
      # Rails.logger.debug "provenance_log_update_before"
      # Rails.logger.debug "provenance_attribute_values_before_update=#{ActiveSupport::JSON.encode provenance_attribute_values_before_update}"
      # Rails.logger.debug ">>>>>>"
      attributes_cache_write( event: EVENT_UPDATE_BEFORE,
                              id: for_provenance_id,
                              attributes: provenance_attribute_values_before_update )
    end

    def provenance_upload( current_user:, event_note: '' )
      provenance_log_event( attributes: attributes_for_provenance_upload,
                            current_user: current_user,
                            event: EVENT_UPLOAD,
                            event_note: event_note,
                            ignore_blank_key_values: true )
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

      def update( attributes )
        Rails.logger.debug "ActiveFedora::Persistence.update(#{ActiveSupport::JSON.encode attributes})"
        if respond_to? :provenance_attribute_values_before_update
          provenance_attribute_values_before_update = provenance_attribute_values_for_update( current_user: '' )
          Rails.logger.debug ">>>>>>"
          Rails.logger.debug "provenance_log_update_before"
          Rails.logger.debug "provenance_attribute_values_before_update=#{ActiveSupport::JSON.encode provenance_attribute_values_before_update}"
          Rails.logger.debug ">>>>>>"
        end

        rv = super( attributes )

        if respond_to? :provenance_attribute_values_before_update
          Rails.logger.debug ">>>>>>"
          Rails.logger.debug "provenance_log_update_after"
          Rails.logger.debug "provenance_attribute_values_before_update=#{ActiveSupport::JSON.encode provenance_attribute_values_before_update}"
          Rails.logger.debug ">>>>>>"
          provenance_update( current_user: '',
                             provenance_attribute_values_before_update: provenance_attribute_values_before_update )
        end
        rv
      end

    end

    # def to_pretty_json
    #   JSON.pretty_generate(self)
    # end

  end
end
