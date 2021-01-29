# frozen_string_literal: true

class MultipleIngestScriptsJob < ::Hyrax::ApplicationJob

  mattr_accessor :multiple_ingest_scripts_job_debug_verbose
  @@multiple_ingest_scripts_job_debug_verbose = ::Deepblue::IngestIntegrationService.multiple_ingest_scripts_job_debug_verbose

  include JobHelper
  queue_as Hyrax.config.ingest_queue_name

  attr_accessor :ingest_mode, :ingester, :paths_to_scripts

  def perform( ingest_mode:, ingester:, paths_to_scripts:, **options )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "ingest_mode=#{ingest_mode}",
                                           "ingester=#{ingester}",
                                           "paths_to_scripts=#{paths_to_scripts}",
                                           "options=#{options}",
                                           "" ] if multiple_ingest_scripts_job_debug_verbose
    self.ingest_mode = ingest_mode
    self.ingester = ingester
    init_paths_to_scripts paths_to_scripts
    return unless self.paths_to_scripts.present?
    return unless validate_paths_to_scripts
    self.paths_to_scripts.each do |script_path|
      ingest_script_run( path_to_script: script_path )
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def hostname
    ::DeepBlueDocs::Application.config.hostname
  end

  def ingest_script_run( path_to_script: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                          ::Deepblue::LoggingHelper.called_from,
                                           "path_to_script=#{path_to_script}",
                                           "" ] if multiple_ingest_scripts_job_debug_verbose
    return true unless ::Deepblue::IngestIntegrationService.ingest_append_ui_allow_scripts_to_run
    return false if path_to_script.blank?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "IngestAppendScriptJob.perform_now( path_to_script: #{path_to_script}, ingester: #{ingester} )",
                                           "" ] if multiple_ingest_scripts_job_debug_verbose
    IngestScriptJob.perform_now( ingest_mode: ingest_mode,
                                 ingester: ingester,
                                 path_to_script: path_to_script )
    true
  end

  def init_paths_to_scripts( paths )
    @paths_to_scripts = paths if paths.is_a? Array
    @paths_to_scripts = paths.split( "\n" ) if paths.is_a? String
    @paths_to_scripts = @paths_to_scripts.map { |path| path.strip }
    @paths_to_scripts = @paths_to_scripts.select { |path| path.present? }
  end

  def validate_paths_to_scripts
    paths_to_scripts.each do |script_path|
      return false unless File.readable? script_path
    end
    return true
  end

end
