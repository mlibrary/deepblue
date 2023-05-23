# frozen_string_literal: true

module BeginEndDateControllerBehavior

  mattr_accessor :begin_end_date_controller_behavior_debug_verbose, default: false

  attr_accessor :begin_date, :end_date

  def begin_date_default
    Date.today - 1.week
  end

  def begin_date_parm
    begin_date.strftime("%Y-%m-%d")
  end

  def end_date_parm
    end_date.strftime("%Y-%m-%d")
  end

  def begin_date_value
    return "" if begin_date.blank?
    return begin_date.strftime("%Y-%m-%d")
  end

  def end_date_value
    return "" if end_date.blank?
    return end_date.strftime("%Y-%m-%d")
  end

  def end_date_default
    Date.tomorrow
  end

  def begin_end_date_init_from_parms( debug_verbose: begin_end_date_controller_behavior_debug_verbose )
    debug_verbose ||= begin_end_date_controller_behavior_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "" ] if debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= begin_date_default
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= end_date_default
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if debug_verbose
  end

  def params_begin_date
    params[:begin_date]
  end

  def params_end_date
    params[:end_date]
  end

end
