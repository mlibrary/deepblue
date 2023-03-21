# frozen_string_literal: true

module Deepblue

  class ZipContentsPath < DerivativePath

    mattr_accessor :zip_contents_path_debug_verbose, default: false

    class << self

      def path_for_reference( object, destination_name: "zip_contents", debug_verbose: zip_contents_path_debug_verbose )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "object=#{object}",
                                               "destination_name=#{destination_name}",
                                               "" ] if debug_verbose
        contents_path = new( object, destination_name )
        rv = contents_path.zip_contents_path
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if debug_verbose
        return rv
      end

      # # @param [ActiveFedora::Base or String] object either the AF object or its id
      # # @return [Array<String>] Array of paths to derivatives for this object.
      # def derivatives_for_reference(object)
      #   new(object).all_paths
      # end

    end

    # @param [ActiveFedora::Base, String] object either the AF object or its id
    def initialize( object, destination_name = nil )
      super( object, destination_name )
    end

    def zip_contents_path
      destination_path
    end

    def extension
      ".txt"
    end

  end

end
