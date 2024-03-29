# monkey

module Hydra::Derivatives::Processors

  class Document < Processor

    mattr_accessor :hydra_derivatives_processors_document_debug_verbose,
                   default: Rails.configuration.hydra_derivatives_processors_document_debug_verbose

    include ShellBasedProcessor

    def self.encode(path, format, outdir)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "timeout=#{timeout}",
                                             # "" ] + caller_locations(1,20) if hydra_derivatives_processors_document_debug_verbose
                                             "" ] if hydra_derivatives_processors_document_debug_verbose
      execute "#{Hydra::Derivatives.libreoffice_path} --invisible --headless --convert-to #{format} --outdir #{outdir} #{Shellwords.escape(path)}"
    end

    # Converts the document to the format specified in the directives hash.
    # TODO: file_suffix and options are passed from ShellBasedProcessor.process but are not needed.
    #       A refactor could simplify this.
    def encode_file(_file_suffix, _options = {})
      convert_to_format
    ensure
      FileUtils.rm_f(converted_file)
    end

    private

      # For jpeg files, a pdf is created from the original source and then passed to the Image processor class
      # so we can get a better conversion with resizing options. Otherwise, the ::encode method is used.
      def convert_to_format
        if directives.fetch(:format) == "jpg"
          # begin monkey
          processor = Hydra::Derivatives::Processors::Image.new(converted_file, directives)
          processor.timeout = timeout
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "timeout=#{timeout}",
                                                 "processor.timeout=#{processor.timeout}",
                                                 "" ] if hydra_derivatives_processors_document_debug_verbose
          processor.process
          # end monkey
        else
          output_file_service.call(File.read(converted_file), directives)
        end
      end

      def converted_file
        @converted_file ||= if directives.fetch(:format) == "jpg"
                              convert_to("pdf")
                            else
                              convert_to(directives.fetch(:format))
                            end
      end

      def convert_to(format)
        self.class.encode(source_path, format, Hydra::Derivatives.temp_file_base)
        File.join(Hydra::Derivatives.temp_file_base, [File.basename(source_path, ".*"), format].join('.'))
      end

  end

end
