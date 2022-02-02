# This module points the FileSet to the location of the technical metdata.
# By default, the file holding the metadata is :original_file and the terms
# are listed under ::characterization_terms.
# Implementations may define their own terms or use a different source file, but
# any terms must be set on the ::characterization_proxy by the Hydra::Works::CharacterizationService
#
# class MyFileSet
#   include Hyrax::FileSetBehavior
# end
#
# MyFileSet.characterization_proxy = :master_file
# MyFileSet.characterization_terms = [:term1, :term2, :term3]
module Hyrax
  module FileSet
    module Characterization
      extend ActiveSupport::Concern

      included do
        mattr_accessor :hyrax_file_set_characterization_debug_verbose, default: false

        class_attribute :characterization_terms, :characterization_proxy
        self.characterization_terms = [
          :format_label,
          :file_size,
          :height,
          :width,
          :filename,
          :well_formed,
          :page_count,
          :file_title,
          :last_modified,
          :original_checksum,
          :duration,
          :sample_rate
        ]
        self.characterization_proxy = :original_file

        # delegate(*characterization_terms, to: :characterization_proxy)

        def characterization_proxy
          send(self.class.characterization_proxy) || NullCharacterizationProxy.new
        end

        def characterization_proxy?
          !characterization_proxy.is_a?(NullCharacterizationProxy)
        end

        def mime_type
          @mime_type ||= characterization_proxy.mime_type
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          @mime_type = MIME::Types['text/plain']
        end

        def format_label
          return characterization_proxy.format_label
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return ""
        end

        def file_size
          return characterization_proxy.file_size
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return 0
        end

        def height
          return characterization_proxy.height
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return 0
        end

        def width
          return characterization_proxy.width
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return 0
        end

        def filename
          return characterization_proxy.filename
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return ""
        end

        def well_formed
          return characterization_proxy.well formed
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return false
        end

        def page_count
          return characterization_proxy.page_count
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return 0
        end

        def file_title
          return characterization_proxy.file_title
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return ""
        end

        def last_modified
          return characterization_proxy.last_modified
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return nil
        end

        def original_checksum
          return characterization_proxy.original_checksum
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return ""
        end

        def duration
          return characterization_proxy.duration
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return nil
        end

        def sample_rate
          return characterization_proxy.sample_rate
        rescue Ldp::Gone => g
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Ignoring Ldp::Gone",
                                                 "" ] if hyrax_file_set_characterization_debug_verbose
          return nil
       end

      end

      class NullCharacterizationProxy
        def method_missing(*_args)
          []
        end

        def respond_to_missing?(_method_name, _include_private = false)
          super
        end

        def mime_type; end
      end
    end
  end
end
