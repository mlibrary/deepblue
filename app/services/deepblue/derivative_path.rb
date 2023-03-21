# frozen_string_literal: true

module Deepblue

  class DerivativePath

    mattr_accessor :derivative_path_debug_verbose, default: false

    attr_reader :id, :destination_name

    # @param [ActiveFedora::Base, String] object either the AF object or its id
    def initialize( object, destination_name = nil )
      @id = object.id if object.respond_to? :id
      @id ||= object.to_s
      @destination_name = destination_name
    end

    def destination_path
      debug_verbose = derivative_path_debug_verbose
      pp = path_prefix
      fn = file_name
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "path_prefix=#{pp}",
                                             "file_name=#{fn}",
                                             "@destination_name=#{@destination_name}",
                                             "" ] if debug_verbose
      rv = "#{pp}-#{fn}" # TODO
      return rv
    end

    # @return [String] Returns the root path where derivatives will be generated into.
    def root_path
      Pathname.new( destination_path ).dirname
    end

    # @return <Pathname> Full prefix of the path for object.
    def path_prefix
      debug_verbose = derivative_path_debug_verbose
      derivative_path = Hyrax.config.derivatives_path
      pp = pair_path
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "derivative_path=#{derivative_path}",
                                             "pair_path=#{pp}",
                                             "" ] if debug_verbose
      rv = Pathname.new( derivative_path ).join( pp ) # TODO
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if debug_verbose
      rv
    end

    def pair_path
      id.split('').each_slice(2).map(&:join).join('/')
    end

    def file_name
      return "" if @destination_name.blank?
      @destination_name + extension
    end

    def extension
      ''
    end

  end

end
