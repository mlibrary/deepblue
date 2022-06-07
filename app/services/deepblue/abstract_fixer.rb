# frozen_string_literal: true

module Deepblue

  class AbstractFixer

    mattr_accessor :abstract_fixer_debug_verbose, default: FindAndFixService.abstract_fixer_debug_verbose
    mattr_accessor :find_and_fix_default_verbose, default: FindAndFixService.find_and_fix_default_verbose

    mattr_accessor :default_filter_in, default: true

    attr_accessor :debug_verbose, :filter, :ids_fixed, :prefix, :verbose, :task

    attr_accessor :msg_queue

    def initialize( debug_verbose: abstract_fixer_debug_verbose,
                    filter: nil,
                    msg_queue: nil,
                    prefix:,
                    task: false,
                    verbose: find_and_fix_default_verbose )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "filter=#{filter}",
                                             "prefix=#{prefix}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: task if debug_verbose
      @debug_verbose = debug_verbose
      @ids_fixed = []
      @filter = filter
      @msg_queue = msg_queue
      @prefix = prefix
      @task = task
      @verbose = verbose
    end

    def add_id_fixed( id )
      @ids_fixed << id
    end

    def add_msg( msg, messages: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "msg=#{msg}",
                                             "" ], bold_puts: task if debug_verbose
      messages ||= @msg_queue
      messages << prefix + msg
    end

    def fix( curation_concern:, messages: )
      raise "Attempt to call abstract method."
    end

    def fix_include?( curation_concern:, messages: )
      return true if filter.nil?
      return filter.include?( curation_concern.date_modified ) if curation_concern.date_modified.present?
      return default_filter_in
    end

  end

end
