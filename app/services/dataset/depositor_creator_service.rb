# frozen_string_literal: true

module Dataset

  class DepositorCreatorService

    mattr_accessor :depositor_creator_service_debug_verbose, default: false

    def self.depositor_creator_to_params( depositor_creator )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "depositor_creator=#{depositor_creator}",
                                             "" ] if depositor_creator_service_debug_verbose
      rv = "0"
      if ( depositor_creator.present? )
        rv = "1" if "true" == depositor_creator
        rv = "1" if "1" == depositor_creator
      end
      return { depositor_creator: rv }
    end

  end

end
