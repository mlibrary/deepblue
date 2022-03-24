# frozen_string_literal: true

module Deepblue

  class ProvenancePath

    mattr_accessor :provenance_path_debug_verbose, default: false

    attr_reader :id, :destination_name

    class << self

      # Path on file system where derivative file is stored
      # @param [ActiveFedora::Base or String] object either the AF object or its id
      def path_for_reference( object )
        pp = new( object, "provenance" )
        rv = pp.provenance_path
        return rv
      end

      # # @param [ActiveFedora::Base or String] object either the AF object or its id
      # # @return [Array<String>] Array of paths to derivatives for this object.
      # def derivatives_for_reference(object)
      #   new(object).all_paths
      # end

    end

    attr_reader :id, :destination_name

    # @param [ActiveFedora::Base, String] object either the AF object or its id
    def initialize( object, destination_name = nil )
      @id = object.id if object.respond_to? :id
      @id ||= object.to_s
      @destination_name = destination_name
    end

    def provenance_path
      rv = "#{path_prefix}-#{file_name}" # TODO
      return rv
    end

    # def all_paths
    #   Dir.glob(root_path.join("*")).select do |path|
    #     path.start_with?(path_prefix.to_s)
    #   end
    # end

    private

      # @return [String] Returns the root path where derivatives will be generated into.
      def root_path
        Pathname.new( provenance_path ).dirname
      end

      # @return <Pathname> Full prefix of the path for object.
      def path_prefix
        Pathname.new( Hyrax.config.derivatives_path ).join( pair_path ) # TODO
      end

      def pair_path
        id.split('').each_slice(2).map(&:join).join('/')
      end

      def file_name
        return unless destination_name
        destination_name + extension
      end

      def extension
        ".log"
      end

  end

end
