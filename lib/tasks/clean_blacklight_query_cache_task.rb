# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../app/helpers/deepblue/clean_up_helper'

module Deepblue

  class CleanBlacklightQueryCacheTask < AbstractTask

    mattr_accessor :clean_blacklight_query_cache_task_debug_verbose, default: false

    def initialize( options: {} )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "options=#{options}",
                                             "" ], bold_puts: true if clean_blacklight_query_cache_task_debug_verbose
      super( options: options )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@options=#{@options}",
                                             "" ], bold_puts: true if clean_blacklight_query_cache_task_debug_verbose
      @increment_day_span = task_options_value( key: 'increment_day_span', default_value: 15 )
      @max_day_spans = task_options_value( key: 'max_day_spans', default_value: 0 )
      @start_day_span = task_options_value( key: 'start_day_span', default_value: 30 )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@increment_day_span=#{@increment_day_span}",
                                             "@max_day_spans=#{@max_day_spans}",
                                             "@start_day_span=#{@start_day_span}",
                                             "" ], bold_puts: true if clean_blacklight_query_cache_task_debug_verbose
    end

    def run
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@increment_day_span=#{@increment_day_span}",
                                             "@max_day_spans=#{@max_day_spans}",
                                             "@start_day_span=#{@start_day_span}",
                                             "" ], bold_puts: true if clean_blacklight_query_cache_task_debug_verbose
      CleanUpHelper.clean_blacklight_query_cache( msg_handler: msg_handler,
                                                  increment_day_span: @increment_day_span,
                                                  start_day_span: @start_day_span,
                                                  max_day_spans: @max_day_spans,
                                                  task: true,
                                                  verbose: verbose,
                                                  debug_verbose: clean_blacklight_query_cache_task_debug_verbose )
    end

  end

end
