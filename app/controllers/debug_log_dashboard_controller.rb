# frozen_string_literal: true

class DebugLogDashboardController < ApplicationController

  mattr_accessor :debug_log_dashboard_controller_debug_verbose, default: false

  # use cache to store value, on entry to this instance, check the cache for update, probably want to have a behavior for this

  include Hyrax::Breadcrumbs
  include AdminOnlyControllerBehavior
  include BeginEndDateControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class, default: DebugLogDashboardPresenter

  attr_accessor :log_entries

  attr_reader :action_error

  def action
    debug_verbose = debug_log_dashboard_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if debug_verbose
    action = params[:commit]
    @action_error = false
    msg = case action
          when t( 'simple_form.actions.debug_log.akismet_enabled' )
            action
          else
            @action_error = true
            "Unkown action #{action}"
          end
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "msg=#{msg}",
                                           "" ] if debug_verbose
    if action_error
      redirect_to debug_log_dashboard_path, alert: msg
    else
      redirect_to debug_log_dashboard_path, notice: msg
    end
  end

  def log_entries
    @log_entries ||= ::Deepblue::DebugLogHelper.log_entries( begin_date: begin_date, end_date: end_date ).reverse!
  end

  def log_parse_entry( entry )
    ::Deepblue::DebugLogHelper.log_parse_entry entry
  end

  def log_key_values_to_table( key_values, parse: false )
    ::Deepblue::DebugLogHelper.log_key_values_to_table( key_values, parse: parse )
  end

  def show
    debug_verbose = debug_log_dashboard_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if debug_verbose
    begin_end_date_init_from_parms
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'hyrax/dashboard/show_debug_log_dashboard'
  end

end
