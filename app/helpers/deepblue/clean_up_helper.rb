# frozen_string_literal: true

module Deepblue

  module CleanUpHelper

    mattr_accessor :clean_up_helper_debug_verbose, default: false

    def self.clean_blacklight_query_cache( increment_day_span: 15,
                                           max_day_spans: 10,
                                           start_day_span: 30,
                                           msg_queue: nil,
                                           task: false,
                                           verbose: false,
                                           debug_verbose: clean_up_helper_debug_verbose )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "increment_day_span=#{increment_day_span}",
                                             "max_day_spans=#{max_day_spans}",
                                             "start_day_span=#{start_day_span}",
                                             "task=#{task}",
                                             "verbose=#{verbose}",
                                             "" ], bold_puts: task if clean_up_helper_debug_verbose
      msg_queue << "start_day_span: #{start_day_span}" unless msg_queue.nil?
      msg_queue << "increment_day_span: #{increment_day_span}" unless msg_queue.nil?
      msg_queue << "max_day_spans: #{max_day_spans}" unless msg_queue.nil?
      spans=Array(0..max_day_spans).reverse
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "spans=#{spans}",
                                             "" ], bold_puts: task if clean_up_helper_debug_verbose
      spans.each do |span|
        days_old=start_day_span+(span*increment_day_span)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "days_old=#{days_old}",
                                               "" ], bold_puts: task if clean_up_helper_debug_verbose
        puts "\n#{days_old}\n" if verbose
        Search.where(['created_at < ? AND user_id IS NULL', Time.zone.today - days_old]).delete_all
      end
    end

  end

end
