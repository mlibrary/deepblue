# frozen_string_literal: true

require_relative './abstract_export_task'

module DataDen

  class ReexportTask < ::DataDen::AbstractExportTask

    attr_accessor :event

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @sort = true
      @event = option_event
    end

    def option_event
      opt = task_options_value( key: 'event', default_value: nil )
      opt = opt.strip if opt.is_a? String
      msg_handler.msg_verbose "event='#{opt}'"
      return opt
    end

    def run
      debug_verbose
      msg_handler.msg_verbose "msg_handler=#{msg_handler.pretty_inspect}"
      msg_handler.msg_verbose
      msg_handler.msg_verbose "Started..."
      run_find
      noids_sort
      run_pair_exports
      msg_handler.msg_verbose "Finished."
      run_email_targets( subject: 'DataDen::ReexportTask', event: 'ReexportTask' )
    end

    def run_find
      @noids = []
      test_dates_init
      ::DataDen::Status.all.each do |status|
        # msg_handler.msg_verbose "status=#{status.pretty_inspect}" if debug_verbose
        next if status.event == ::DataDen::EVENT_DELETED
        next if event.present? && status.event != event
        # msg_handler.msg_verbose "Filter status.timestamp=#{status.timestamp}"
        # msg_handler.msg_verbose "Filter #{test_date_begin} < #{status.timestamp} < #{test_date_end} ?"
        # msg_handler.msg_verbose "next unless #{test_date_begin} <= #{status.timestamp} = #{test_date_begin <= status.timestamp}"
        # msg_handler.msg_verbose "next unless #{status.timestamp} <= #{test_date_end} = #{status.timestamp <= test_date_end}"
        next unless @test_date_begin <= status.timestamp
        next unless status.timestamp <= @test_date_end

        @noids << status.noid
      end
    end

  end

end
