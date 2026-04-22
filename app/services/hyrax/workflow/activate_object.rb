# frozen_string_literal: true
module Hyrax
  module Workflow
    module ActivateObject

      mattr_accessor :workflow_activate_object_debug_verbose, default: true

      ##
      # This is a built in function for workflow, setting the +#state+
      # of the target to the Fedora +active+ status URI
      #
      # @param target [#state] an instance of a model with a +#state+ property;
      #   e.g. a {Hyrax::Work}
      #
      # @return [RDF::Vocabulary::Term] the Fedora Resource Status 'active' term
      def self.call(target:, **args)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                               # ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                               "target.class.name=#{target.class.name}",
                                               "args=#{args.pretty_inspect}",
                                               "args[:user]=#{args[:user]}",
                                               "" ] if workflow_activate_object_debug_verbose
        target.state = Hyrax::ResourceStatus::ACTIVE
        if target.respond_to?(:workflow_publish)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                                 "publish",
                                                 "target.class.name=#{target.class.name}",
                                                 "" ] if workflow_activate_object_debug_verbose
          target.workflow_publish( current_user: args[:user], event_note: "#{self.class.name}" )
        end
      end
    end
  end
end
