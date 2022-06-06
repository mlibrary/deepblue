# frozen_string_literal: true

class EmailDashboardController < ApplicationController

  mattr_accessor :email_dashboard_controller_debug_verbose, default: false

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
  self.presenter_class = EmailDashboardPresenter

  attr_accessor :begin_date, :end_date, :log_entries

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if email_dashboard_controller_debug_verbose
    action = params[:commit]
    @action_error = false
    msg = case action
          when t( 'simple_form.actions.email_management.reload_email_templates' )
            action_reload_email_templates
          else
            @action_error = true
            "Unkown action #{action}"
          end
    if action_error
      redirect_to email_dashboard_path, alert: msg
    else
      redirect_to email_dashboard_path, notice: msg
    end
  end

  def action_reload_email_templates
    ::Deepblue::WorkViewContentService.load_email_templates
    "Reloaded email templates."
  end

  def log_entries
    @log_entries ||= ::Deepblue::LogFileHelper.log_entries( log_file_path: ::EmailLogger.log_file,
                                                            begin_date: begin_date,
                                                            end_date: end_date,
                                                            raw_key_values: true ).reverse!
  end

  def log_parse_entry( entry )
    ::Deepblue::LogFileHelper.log_parse_entry entry
  end

  def log_key_values_to_table( key_values, parse: false )
    ::Deepblue::LogFileHelper.log_key_values_to_table( key_values, parse: parse )
  end

  def show
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "" ] if email_dashboard_controller_debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if email_dashboard_controller_debug_verbose
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'hyrax/dashboard/show_email_dashboard'
  end

end
