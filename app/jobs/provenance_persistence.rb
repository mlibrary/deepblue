# frozen_string_literal: true

module Deepblue

  module ProvenancePersistenceExt

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
