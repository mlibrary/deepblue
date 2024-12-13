# frozen_string_literal: true

class ReportDashboardController < ApplicationController

  mattr_accessor :report_dashboard_controller_debug_verbose, default: false

  include ActiveSupport::Concern
  include Blacklight::Base
  include Blacklight::AccessControls::Catalog
  include Hyrax::Breadcrumbs
  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class
  self.presenter_class = ReportDashboardPresenter

  attr_accessor :edit_report_textarea, :report_file_path
  # attr_accessor :controller_path, :request
  # @controller_path = ''
  # @request = {}

  def report_file_path
    @report_file_path ||= load_report_file_path
  end

  def load_edit_report_textarea
    return if @edit_report_textarea.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:edit_report_textarea]=#{params[:edit_report_textarea]}",
                                           "" ] if report_dashboard_controller_debug_verbose
    @edit_report_textarea = ''
    @edit_report_textarea = params[:edit_report_textarea] if params[:edit_report_textarea].present?
  end

  def load_report_file_path
    return if @report_file_path.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:report_file_path]=#{params[:report_file_path]}",
                                           "" ] if report_dashboard_controller_debug_verbose
    @report_file_path = ''
    @report_file_path = params[:report_file_path] if params[:report_file_path].present?
    @report_file_path
  end

  def run_action
    load_edit_report_textarea
    load_report_file_path
    action = params[:commit]
    case action
    when MsgHelper.t( 'simple_form.actions.report.run_report_job' )
      return run_report_task_job
    when MsgHelper.t( 'simple_form.actions.report.run_load_report_script' )
      return run_load_report_script
    when MsgHelper.t( 'simple_form.actions.report.run_save_report_script' )
      return run_save_report_script
    else
      return redirect_to( report_dashboard_path, alert: "Unknown action '#{action}'" )
    end
  end

  def run_load_report_script
    return redirect_to( report_dashboard_path, alert: "No report script file path specfied." ) unless report_file_path.present?
    return redirect_to( report_dashboard_path, alert: "#{report_file_path} not found." ) unless File.exist? report_file_path
    rv = []
    File.open( report_file_path, "r" ) { |f| rv = f.readlines }
    @edit_report_textarea = rv.join("")
    show_render
  end

  def run_report_task_job
    return redirect_to( report_dashboard_path, alert: "No report script file path specfied." ) unless report_file_path.present?
    msg = start_report_task_job
    if msg.present?
      if msg.start_with? "Error"
        return redirect_to( report_dashboard_path, notice: msg )
      else
        return redirect_to( report_dashboard_path, alert: msg )
      end
    else
      return redirect_to report_dashboard_path
    end
  end

  def run_save_report_script
    return redirect_to( report_dashboard_path, alert: "No report script file path specfied." ) unless report_file_path.present?
    write_script
    show_render
  end

  def show
    load_edit_report_textarea
    load_report_file_path
    show_render
  end

  def show_render
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    @view_presenter = @presenter
    render 'hyrax/dashboard/show_report_dashboard'
  end

  def start_report_task_job
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "report_file_path=#{report_file_path}",
                                           "" ] if report_dashboard_controller_debug_verbose
   if report_file_path.present?
     ReportTaskJob.perform_later(reporter: current_user.email, report_file_path: report_file_path )
      return "Started report job: #{report_file_path}"
    end
    "No report file path specified."
  end

  def valid_report_file_path
    return "Report file not found: '#{report_file_path}'" unless File.readable? report_file_path
    return ''
  end

  def write_script
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "report_file_path=#{report_file_path}",
                                           "" ] if report_dashboard_controller_debug_verbose
    File.open( report_file_path, "w" ) do |out|
      out.puts params[:edit_report_textarea]
    end
    report_file_path
  end

end
