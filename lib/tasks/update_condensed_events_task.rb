# frozen_string_literal: true

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_task'

  class UpdateCondensedEventsTask < AbstractTask

    attr_accessor :options

    def initialize( options: )
      super( options: options )
    end

    def run
      # TODO parse date range
      date_begin = task_options_value( key: 'date_begin', default_value: nil )
      date_end = task_options_value( key: 'date_end', default_value: nil, )
      date_range = nil
      if date_begin.present? || date_end.present?
        date_begin = ReportHelper.to_datetime( date: date_begin, msg_handler: msg_handler )
        date_end = ReportHelper.to_datetime( date: date_end, msg_handler: msg_handler )
        if date_begin.blank? || date_end.blank?
          date_range_all = ::AnalyticsHelper.date_range_all
          date_begin = date_range_all.first if date_begin.blank?
          date_end = date_range_all.last if date_end.blank?
        end
        date_range = date_begin..date_end
      end
      ::AnalyticsHelper.update_current_month_condensed_events( date_range: date_range, msg_handler: msg_handler )
      ::AnalyticsHelper.updated_condensed_event_work_downloads( msg_handler: msg_handler )
    end

  end

end
