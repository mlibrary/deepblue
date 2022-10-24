# frozen_string_literal: true

class GlobusDashboardController < ApplicationController

  mattr_accessor :globus_dashboard_controller_debug_verbose, default: false

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
    rv = ::Deepblue::GlobusIntegrationService.globus_status( msg_handler: msg_handler )
    return rv
  end

  def run_action
    action = params[:commit]
    case action
    when MsgHelper.t( 'simple_form.actions.report.run_report_job' )
      return run_report_task_job
    else
      return redirect_to( globus_dashboard_path, alert: "Unknown action '#{action}'" )
    end
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
