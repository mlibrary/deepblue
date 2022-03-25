# frozen_string_literal: true

class ContactFormDashboardController < ApplicationController

  mattr_accessor :mattr_contact_form_dashboard_controller_debug_verbose, default: false

  def self.contact_form_dashboard_controller_debug_verbose
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "" ] if mattr_contact_form_dashboard_controller_debug_verbose
    if Rails.env.production?
      ::Deepblue::CacheService.var_cache_fetch( klass: ContactFormDashboardController,
                                                var: :contact_form_dashboard_controller_debug_verbose,
                                                default_value: mattr_contact_form_dashboard_controller_debug_verbose )
    else
      mattr_contact_form_dashboard_controller_debug_verbose
    end
  end

  def self.contact_form_dashboard_controller_debug_verbose=(value)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "value=#{value}",
                                           "" ] if mattr_contact_form_dashboard_controller_debug_verbose
    if Rails.env.production? && ::Deepblue::CacheService.cache_available
      ::Deepblue::CacheService.var_cache_write( klass: ContactFormDashboardController,
                                                var: :contact_form_dashboard_controller_debug_verbose,
                                                value: value )
    else
      ContactFormDashboardController.mattr_contact_form_dashboard_controller_debug_verbose = value
    end
  end

  def contact_form_dashboard_controller_debug_verbose
    @contact_form_dashboard_controller_debug_verbose ||= ContactFormDashboardController.contact_form_dashboard_controller_debug_verbose
  end

  # use cache to store value, on entry to this instance, check the cache for update, probably want to have a behavior for this

  include Hyrax::Breadcrumbs
  include AdminOnlyControllerBehavior

  with_themed_layout 'dashboard'

  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class, default: ContactFormDashboardPresenter

  attr_accessor :begin_date, :end_date, :log_entries

  attr_reader :action_error

  def action
    debug_verbose = contact_form_dashboard_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "::Hyrax::ContactFormController.akismet_enabled=#{::Hyrax::ContactFormController.akismet_enabled}",
                                           "::Hyrax::ContactFormController.ngr_enabled=#{::Hyrax::ContactFormController.ngr_enabled}",
                                           "::Hyrax::ContactFormController.contact_form_controller_debug_verbose=#{::Hyrax::ContactFormController.contact_form_controller_debug_verbose}",
                                           "ContactFormDashboardController.contact_form_dashboard_controller_debug_verbose=#{ContactFormDashboardController.contact_form_dashboard_controller_debug_verbose}",
                                           "::Hyrax::ContactFormController.contact_form_send_email=#{::Hyrax::ContactFormController.contact_form_send_email}",
                                           "" ] if debug_verbose
    action = params[:commit]
    @action_error = false
    msg = case action
          when t( 'simple_form.actions.contact_form.akismet_enabled' )
            ::Hyrax::ContactFormController.akismet_enabled = true
            action
          when t( 'simple_form.actions.contact_form.akismet_disabled' )
            ::Hyrax::ContactFormController.akismet_enabled = false
            action
          when t( 'simple_form.actions.contact_form.new_google_recaptcha_enabled' )
            ::Hyrax::ContactFormController.ngr_enabled = true
            action
          when t( 'simple_form.actions.contact_form.new_google_recaptcha_disabled' )
            ::Hyrax::ContactFormController.ngr_enabled = false
            action
          when t( 'simple_form.actions.contact_form.debug_controller_verbose_enable' )
            ::Hyrax::ContactFormController.contact_form_controller_debug_verbose = true
            action
          when t( 'simple_form.actions.contact_form.debug_controller_verbose_disable' )
            ::Hyrax::ContactFormController.contact_form_controller_debug_verbose = false
            action
          when t( 'simple_form.actions.contact_form.debug_dashboard_controller_verbose_enable' )
            ContactFormDashboardController.contact_form_dashboard_controller_debug_verbose = true
            action
          when t( 'simple_form.actions.contact_form.debug_dashboard_controller_verbose_disable' )
            ContactFormDashboardController.contact_form_dashboard_controller_debug_verbose = false
            action
          when t( 'simple_form.actions.contact_form.send_email_enabled' )
            ::Hyrax::ContactFormController.contact_form_send_email = true
            action
          when t( 'simple_form.actions.contact_form.send_email_disabled' )
            ::Hyrax::ContactFormController.contact_form_send_email = false
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
                                           "::Hyrax::ContactFormController.akismet_enabled=#{::Hyrax::ContactFormController.akismet_enabled}",
                                           "::Hyrax::ContactFormController.ngr_enabled=#{::Hyrax::ContactFormController.ngr_enabled}",
                                           "::Hyrax::ContactFormController.contact_form_controller_debug_verbose=#{::Hyrax::ContactFormController.contact_form_controller_debug_verbose}",
                                           "ContactFormDashboardController.contact_form_dashboard_controller_debug_verbose=#{ContactFormDashboardController.contact_form_dashboard_controller_debug_verbose}",
                                           "::Hyrax::ContactFormController.contact_form_send_email=#{::Hyrax::ContactFormController.contact_form_send_email}",
                                           "" ] if debug_verbose || ContactFormDashboardController.contact_form_dashboard_controller_debug_verbose
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
                                           "params[:begin_date]=#{params[:begin_date]}",
                                           "params[:end_date]=#{params[:end_date]}",
                                           "::Hyrax::ContactFormController.akismet_enabled=#{::Hyrax::ContactFormController.akismet_enabled}",
                                           "::Hyrax::ContactFormController.ngr_enabled=#{::Hyrax::ContactFormController.ngr_enabled}",
                                           "::Hyrax::ContactFormController.contact_form_controller_debug_verbose=#{::Hyrax::ContactFormController.contact_form_controller_debug_verbose}",
                                           "contact_form_dashboard_controller_debug_verbose=#{contact_form_dashboard_controller_debug_verbose}",
                                           "::Hyrax::ContactFormController.contact_form_send_email=#{::Hyrax::ContactFormController.contact_form_send_email}",
                                           "" ] if contact_form_dashboard_controller_debug_verbose
    @begin_date = ViewHelper.to_date(params[:begin_date])
    @begin_date ||= Date.today - 1.week
    @end_date = ViewHelper.to_date(params[:end_date])
    @end_date ||= Date.tomorrow
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@begin_date=#{@begin_date}",
                                           "@end_date=#{@end_date}",
                                           "" ] if contact_form_dashboard_controller_debug_verbose
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    render 'hyrax/dashboard/show_contact_form_dashboard'
  end

end
