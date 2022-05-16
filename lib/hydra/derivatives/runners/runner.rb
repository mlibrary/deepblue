
# monkey

module Hydra

  module Derivatives
    class Runner

      HYDRA_DERIVATIVES_RUNNER_DEBUG_VERBOSE = false # Rails.configuration.hydra_derivatives_runner_debug_verbose # monkey

      class << self
        attr_writer :output_file_service
      end

      # Use the output service configured for this class or default to the global setting
      def self.output_file_service
        @output_file_service || Hydra::Derivatives.output_file_service
      end

      class << self
        attr_writer :source_file_service
      end

      # Use the source service configured for this class or default to the global setting
      def self.source_file_service
        @source_file_service || Hydra::Derivatives.source_file_service
      end

      # @param [String, ActiveFedora::Base] object_or_filename path to the source file, or an object
      # @param [Hash] options options to pass to the encoder
      # @options options [Array] :outputs a list of desired outputs, each entry is a hash that has :label (optional), :format and :url
      def self.create(object_or_filename, options)
        # begin monkey
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "self.class.name=#{self.class.name}",
                                               "object_or_filename=#{object_or_filename}",
                                               "options=#{options}",
                                               # "" ]  + caller_locations(1,40) if HYDRA_DERIVATIVES_RUNNER_DEBUG_VERBOSE
                                               "" ] if HYDRA_DERIVATIVES_RUNNER_DEBUG_VERBOSE
        # monkey end
        source_file(object_or_filename, options) do |f|
          transform_directives(options.delete(:outputs)).each do |instructions|
            # begin monkey
            processor = processor_class.new(f.path,
                                            instructions.merge(source_file_service: source_file_service),
                                            output_file_service: output_file_service)
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "processor.class.name=#{processor.class.name}",
                                                   "" ] if HYDRA_DERIVATIVES_RUNNER_DEBUG_VERBOSE
            processor_class.timeout = Rails.configuration.derivative_timeout if processor_class.respond_to? :timeout=
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "processor.class.name=#{processor.class.name}",
                                                   "processor_class.timeout=#{processor_class.timeout if processor_class.respond_to? :timeout}",
                                                   # "processor.class.timeout=#{processor.class.timeout if processor.class.respond_to? :timeout}",
                                                   "" ] if HYDRA_DERIVATIVES_RUNNER_DEBUG_VERBOSE
            processor.process
            # monkey end
          end
        end
      end

      # Override this method if you need to add any defaults
      def self.transform_directives(options)
        options
      end

      def self.source_file(object_or_filename, options, &block)
        source_file_service.call(object_or_filename, options, &block)
      end

      def self.processor_class
        raise "Overide the processor_class method in a sub class"
      end
    end
  end

end
