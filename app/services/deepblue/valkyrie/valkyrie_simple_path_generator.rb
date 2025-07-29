# frozen_string_literal: true
module Deepblue
  ##
  # Provide "simple", paths for the valkyrie disk storage adapter.
  #
  # By default, Valkyrie does bucketed/pairtree style paths. Since some of our
  # older on-disk file storage does not do this, we need this to provide
  # backward compatibility.
  class ValkyrieSimplePathGenerator

    mattr_accessor :deepblue_valkyrie_simple_path_generator_debug_verbose, default: false

    attr_reader :base_path

    def initialize(base_path:)
      @base_path = base_path
    end

    def generate(resource:, file:, original_filename:) # rubocop:disable Lint/UnusedMethodArgument
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "base_path=#{base_path}",
                                             "resource.class.name=#{resource.class.name}",
                                             "resource.id=#{resource.id}",
                                             "file.class.name=#{file.class.name}",
                                             "original_filename.class.name=#{original_filename.class.name}",
                                             "original_filename=#{original_filename}",
                                             "" ] if deepblue_valkyrie_simple_path_generator_debug_verbose
      Pathname.new(base_path).join(resource.id, original_filename)
    end
  end
end
