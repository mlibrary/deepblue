# frozen_string_literal: true

module Deepblue

  class AbstractFixer

    mattr_accessor :abstract_fixer_debug_verbose, default: FindAndFixService.abstract_fixer_debug_verbose
    mattr_accessor :find_and_fix_default_verbose, default: FindAndFixService.find_and_fix_default_verbose

    mattr_accessor :default_filter_in, default: true

    attr_accessor :filter, :ids_fixed, :prefix

    attr_accessor :msg_handler

    def initialize( filter: nil, msg_handler:, prefix: )
      @msg_handler = msg_handler
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "filter=#{filter}",
                               "prefix=#{prefix}",
                               "" ] if abstract_fixer_debug_verbose && debug_verbose
      @ids_fixed = []
      @filter = filter
      @msg_handler = msg_handler
      @prefix = prefix
    end

    def add_id_fixed( id )
      @ids_fixed << id
    end

    def debug_verbose
      msg_handler.debug_verbose
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
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "msg=#{msg}", "" ] if debug_verbose
      # msg = prefix + msg
      # if msg_handler.present?
      #   msg_handler.msg msg
      # elsif @msg_handler.present?
      #   @msg_handler.msg msg
      # end
      msg_handler.msg( msg, prefix: prefix )
    end

    def msg_verbose( msg )
      msg_handler.msg_verbose( msg, prefix: prefix )
    end

  end

end
