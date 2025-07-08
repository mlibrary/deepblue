# frozen_string_literal: true

class GlobusDashboardController < ApplicationController

  mattr_accessor :globus_dashboard_controller_debug_verbose,
                 default: ::Deepblue::GlobusIntegrationService.globus_dashboard_controller_debug_verbose

  include ActiveSupport::Concern
  include Blacklight::Base
  include Blacklight::AccessControls::Catalog
  include Hyrax::Breadcrumbs
  include AdminOnlyControllerBehavior
  include ::Deepblue::GlobusControllerBehavior

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

  def globus_clean_msg( dir )
    dirs = dir.join( MsgHelper.t( 'data_set.globus_clean_join_html' ) )
    rv = MsgHelper.t( 'data_set.globus_clean', dirs: dirs )
    return rv
  end

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
    dirs = globus_clean_download( id: params[:work_id] )
    redirect_to( globus_dashboard_path, notice: globus_clean_msg( dirs ) )
  end

  def run_copy
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:work_id]=#{params[:work_id]}",
                                           "" ] if globus_dashboard_controller_debug_verbose
    globus_copy_job( id: params[:work_id] )
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

end
