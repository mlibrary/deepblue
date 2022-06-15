# frozen_string_literal: true

module Deepblue

  class AbstractFixer

    mattr_accessor :abstract_fixer_debug_verbose, default: FindAndFixService.abstract_fixer_debug_verbose
    mattr_accessor :find_and_fix_default_verbose, default: FindAndFixService.find_and_fix_default_verbose

    mattr_accessor :default_filter_in, default: true

    attr_accessor :debug_verbose, :filter, :ids_fixed, :prefix, :verbose

    attr_accessor :msg_handler

    def initialize( debug_verbose: abstract_fixer_debug_verbose,
                    filter: nil,
                    msg_handler:,
                    prefix:,
                    verbose: find_and_fix_default_verbose )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "filter=#{filter}",
                                             "prefix=#{prefix}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      @debug_verbose = debug_verbose
      @ids_fixed = []
      @filter = filter
      @msg_handler = msg_handler
      @prefix = prefix
      @verbose = verbose
    end

    def add_id_fixed( id )
      @ids_fixed << id
    end

    def fix( curation_concern: )
      raise "Attempt to call abstract method."
    end

    def fix_include?( curation_concern: )
      return true if filter.nil?
      return filter.include?( curation_concern.date_modified ) if curation_concern.date_modified.present?
      return default_filter_in
    end

    def msg( msg )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "msg=#{msg}",
                                             "" ], bold_puts: msg_handler.to_console if debug_verbose
      # msg = prefix + msg
      # if msg_handler.present?
      #   msg_handler.msg msg
      # elsif @msg_handler.present?
      #   @msg_handler.msg msg
      # end
      msg_handler.msg( msg, prefix: prefix )
    end

    def msg_verbose( msg )
      msg_handler.msg( msg, prefix: prefix ) if verbose
    end

  end

end
