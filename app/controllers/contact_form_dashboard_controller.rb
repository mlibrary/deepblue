# frozen_string_literal: true

class ContactFormDashboardController < ApplicationController

  mattr_accessor :contact_form_dashboard_debug_verbose, default: true

  include Hyrax::Breadcrumbs
  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class
  self.presenter_class = ContactFormDashboardPresenter

  attr_accessor :begin_date, :end_date, :log_entries

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if contact_form_dashboard_debug_verbose
    action = params[:commit]
    @action_error = false
    msg = case action
          when t( 'simple_form.actions.contact_form.akismet_enable' )
            ::Hyrax::ContactFormController.akismet_enabled = true
            ::Hyrax::ContactFormController.ngr_enabled = false
          when t( 'simple_form.actions.contact_form.akismet_disable' )
            ::Hyrax::ContactFormController.akismet_enabled = false
          when t( 'simple_form.actions.contact_form.new_google_recaptcha_enabled' )
            ::Hyrax::ContactFormController.ngr_enabled = true
            ::Hyrax::ContactFormController.akismet_enabled = false
          when t( 'simple_form.actions.contact_form.new_google_recaptcha_disabled' )
            ::Hyrax::ContactFormController.ngr_enabled = false
          when t( 'simple_form.actions.contact_form.debug_controller_verbose_enable' )
            ::Hyrax::ContactFormController.contact_form_controller_debug_verbose = true
          when t( 'simple_form.actions.contact_form.debug_controller_verbose_disable' )
            ::Hyrax::ContactFormController.contact_form_controller_debug_verbose = false
          else
            @action_error = true
            "Unkown action #{action}"
          end
    if action_error
      redirect_to contact_form_dashboard_path, alert: msg
    else
      redirect_to contact_form_dashboard_path, notice: msg
    end
  end

  def log_entries
    @log_entries ||= ::Hyrax::ContactFormHelper.log_entries( begin_date: begin_date, end_date: end_date ).reverse!
  end

  def log_parse_entry( entry )
    ::Hyrax::ContactFormHelper.log_parse_entry entry
  end

  def log_key_values_to_table( key_values, parse: false )
    ::Hyrax::ContactFormHelper.log_key_values_to_table( key_values, parse: parse )
  end

  def show
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "" ] if contact_form_dashboard_debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'hyrax/dashboard/show_contact_form_dashboard'
  end

end
