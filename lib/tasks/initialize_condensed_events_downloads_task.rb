# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_report_task'
  require_relative '../../app/services/deepblue/work_impact_reporter'

  class InitializeCondensedEventsDownloadsTask < AbstractReportTask

    attr_accessor :force, :only_published, :clean_work_events

    def initialize( options: {}, msg_handler: nil, msg_queue: nil, debug_verbose: false )
      super( options: options, msg_handler: msg_handler, msg_queue: msg_queue, debug_verbose: debug_verbose )
    end

    def run

      @force = task_options_value( key: 'force',
                                   default_value: true ) # AnalyticsHelper::DEFAULT_FORCED )
      @only_published = task_options_value( key: 'only_published',
                                            default_value: AnalyticsHelper::DEFAULT_ONLY_PUBLISHED )
      @clean_work_events = task_options_value( key: 'clean_work_events',
                                               default_value: AnalyticsHelper::DEFAULT_CLEAN_WORK_EVENTS )

      @task_id = task_options_value( key: 'task_id', default_value: nil )
      if @task_id.present?
        @msg_handler = MsgHelper.msg_handler_queue_to_file( task_id: @task_id, verbose: verbose )
      end

      set_quiet( quiet: @quiet )
      AnalyticsHelper.initialize_condensed_event_downloads( force: force,
                                                            only_published: only_published,
                                                            incremental_clean_work_events: clean_work_events,
                                                            msg_handler: msg_handler )
    end

  end

end
