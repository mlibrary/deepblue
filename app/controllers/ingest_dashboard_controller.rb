# frozen_string_literal: true

class IngestDashboardController < ApplicationController

  mattr_accessor :ingest_dashboard_controller_debug_verbose, default: false

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
  self.presenter_class = IngestDashboardPresenter

  attr_accessor :ingest_mode, :paths_to_scripts

  def load_paths_to_scripts
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:ingest_script_file_paths_textarea]=#{params[:ingest_script_file_paths_textarea]}",
                                           "" ] if ingest_dashboard_controller_debug_verbose
    @paths_to_scripts = []
    lines = params[:ingest_script_file_paths_textarea]
    return if lines.blank?
    lines = lines.split( "\n" )
    lines = lines.map { |line| line.strip }
    @paths_to_scripts = lines.select { |line| line.present? }
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "paths_to_scripts=#{paths_to_scripts}",
                                           "" ] if ingest_dashboard_controller_debug_verbose
  end

  def run_ingests_job
    action = params[:commit]
    @ingest_mode = case action
                   when MsgHelper.t( 'simple_form.actions.ingest.run_append_ingests_job' )
                     'append'
                   when MsgHelper.t( 'simple_form.actions.ingest.run_populate_ingests_job' )
                     'populate'
                   else
                     'error'
                   end
    load_paths_to_scripts
    msg = valid_paths_to_scripts
    return redirect_to( ingest_dashboard_path, alert: msg ) unless msg.blank?
    msg = start_multiple_ingest_scripts_job
    if msg.present?
      if msg.start_with? "Error"
        return redirect_to( ingest_dashboard_path, notice: msg )
      else
        return redirect_to( ingest_dashboard_path, alert: msg )
      end
    else
      return redirect_to ingest_dashboard_path
    end
  end

  def show
    show_render
  end

  def show_render
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    @view_presenter = @presenter
    render 'hyrax/dashboard/show_ingest_dashboard'
  end

  def start_multiple_ingest_scripts_job
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "paths_to_scripts=#{paths_to_scripts}",
                                           "" ] if ingest_dashboard_controller_debug_verbose
   if paths_to_scripts.present?
      MultipleIngestScriptsJob.perform_later( ingest_mode: ingest_mode,
                                              ingester: current_user.email,
                                              paths_to_scripts: paths_to_scripts )
      return "Started ingest scripts:<br/>#{paths_to_scripts.join("<br/>")}"
    end
    "No file script paths specified."
  end

  def valid_paths_to_scripts
    found = []
    not_found = []
    paths_to_scripts.each do |script_path|
      if File.readable? script_path
        found << script_path
      else
        not_found << script_path
      end
    end
    return "Found:<br/>#{found.join("<br/>")}<br/>Not found:<br/>#{not_found.join("<br/>")}" if not_found.present?
    return ''
  end

end
