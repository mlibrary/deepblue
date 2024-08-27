# frozen_string_literal: true

class GlobusDashboardController < ApplicationController

  mattr_accessor :globus_dashboard_controller_debug_verbose,
                 default: ::Deepblue::GlobusIntegrationService.globus_dashboard_controller_debug_verbose

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
  self.presenter_class = GlobusDashboardPresenter

  # attr_accessor :edit_report_textarea, :report_file_path
  # attr_accessor :controller_path, :request
  # @controller_path = ''
  # @request = {}

  def globus_status
    @globus_status ||= globus_status_init
  end

  def globus_status_init
    msg_handler = ::Deepblue::MessageHandler.new( verbose: false,
                                                  debug_verbose: globus_dashboard_controller_debug_verbose )
    rv = ::Deepblue::GlobusService.globus_status( include_disk_usage: false, msg_handler: msg_handler )
    begin
      rv.yaml_save # TODO: revisit
    rescue Exception => e
      Rails.logger.error "#{e.class} -- #{e.message} at #{e.backtrace[0]}"
      ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                             "globus_status_init #{e.class}: #{e.message} at #{e.backtrace[0]}",
                                             "" ] + e.backtrace # error
    end
    return rv
  end

  def run_action
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "params[:work_id]=#{params[:work_id]}",
                                           "" ] if globus_dashboard_controller_debug_verbose
    action = params[:commit]
    case action
    when MsgHelper.t('hyrax.globus.submit.clean')
      return run_clean
    when MsgHelper.t('hyrax.globus.submit.copy')
      return run_copy
    else
      return redirect_to( globus_dashboard_path, alert: "Unknown action '#{action}'" )
    end
  end

  def run_clean
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:work_id]=#{params[:work_id]}",
                                           "" ] if globus_dashboard_controller_debug_verbose
    dirs = globus_clean_download( params[:work_id] )
    redirect_to( globus_dashboard_path, notice: globus_clean_msg( dirs ) )
  end

  def run_copy
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:work_id]=#{params[:work_id]}",
                                           "" ] if globus_dashboard_controller_debug_verbose
    globus_copy_job( params[:work_id] )
    redirect_to( globus_dashboard_path, notice: "Globus copy job started for work id '#{params[:work_id]}'" )
  end

  def show
    show_render
  end

  def show_render
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    @view_presenter = @presenter
    render 'hyrax/dashboard/show_globus_dashboard'
  end

  def globus_bounce_external_link_off_server?
    ::Deepblue::GlobusIntegrationService.globus_bounce_external_link_off_server
  end

  def globus_copy_complete?( concern_id )
    ::Deepblue::GlobusService.globus_copy_complete?( concern_id )
  end

  def globus_copy_job( concern_id, user_email: nil )
    ::GlobusCopyJob.perform_later( concern_id: concern_id,
         user_email: user_email,
         delay_per_file_seconds: ::Deepblue::GlobusIntegrationService.globus_debug_delay_per_file_copy_job_seconds )
    globus_ui_delay
  end

  def globus_clean_download( concern_id )
    ::GlobusCleanJob.perform_later( concern_id, clean_download: true )
    dirs = []
    dirs << ::Deepblue::GlobusService.globus_target_download_dir( concern_id )
    dirs << ::Deepblue::GlobusService.globus_target_prep_dir( concern_id )
    dirs << ::Deepblue::GlobusService.globus_target_prep_tmp_dir( concern_id )
    globus_ui_delay
    return dirs
  end

  def globus_clean_msg( dir )
    dirs = dir.join( MsgHelper.t( 'data_set.globus_clean_join_html' ) )
    rv = MsgHelper.t( 'data_set.globus_clean', dirs: dirs )
    return rv
  end

  def globus_clean_prep( concern_id )
    ::GlobusCleanJob.perform_later( concern_id, clean_download: false )
    globus_ui_delay
  end

  def globus_download_enabled?
    ::Deepblue::GlobusIntegrationService.globus_enabled
  end

  def globus_download_dir_du( concern_id: )
    ::Deepblue::GlobusService.globus_download_dir_du( concern_id: concern_id )
  end

  def globus_prep_dir_du( concern_id: )
    ::Deepblue::GlobusService.globus_prep_dir_du( concern_id: concern_id )
  end

  def globus_prep_tmp_dir_du( concern_id: )
    ::Deepblue::GlobusService.globus_prep_tmp_dir_du( concern_id: concern_id )
  end

  def globus_enabled?
    ::Deepblue::GlobusIntegrationService.globus_enabled
  end

  def globus_error_file_exists?( concern_id )
    ::Deepblue::GlobusService.globus_error_file_exists? concern_id
  end

  def globus_external_url( concern_id )
    ::Deepblue::GlobusService.globus_external_url concern_id
  end

  def globus_files_available?( concern_id )
    ::Deepblue::GlobusService.globus_files_available? concern_id
  end

  def globus_files_prepping?( concern_id )
    ::Deepblue::GlobusService.globus_files_prepping? concern_id
  end

  def globus_last_error_msg( concern_id )
    ::Deepblue::GlobusService.globus_error_file_contents concern_id
  end

  def globus_locked?( concern_id )
    ::Deepblue::GlobusService.globus_locked?( concern_id )
  end

  def globus_ui_delay( delay_seconds: ::Deepblue::GlobusIntegrationService.globus_after_copy_job_ui_delay_seconds )
    sleep delay_seconds if delay_seconds.positive?
  end

end
