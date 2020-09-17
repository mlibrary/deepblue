module Hydra
  module Derivatives
    class Runner
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

      def self.create(object_or_filename, options)
        source_file(object_or_filename, options) do |f|
          transform_directives(options.delete(:outputs)).each do |instructions|
            processor_class.new(f.path,
                                instructions.merge(source_file_service: source_file_service),
                                output_file_service: output_file_service).process
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
