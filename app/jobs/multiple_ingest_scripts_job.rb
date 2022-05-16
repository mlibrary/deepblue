# frozen_string_literal: true

class MultipleIngestScriptsJob < ::Hyrax::ApplicationJob

  mattr_accessor :multiple_ingest_scripts_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.multiple_ingest_scripts_job_debug_verbose

  mattr_accessor :scripts_allowed_path_extensions, default: [ '.yml', '.yaml' ]

  mattr_accessor :scripts_allowed_path_prefixes,
                 default: [ '/deepbluedata-prep/', './data/reports/', '/deepbluedata-globus/upload/' ]

  include JobHelper # see JobHelper for :by_request_only, :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as Hyrax.config.ingest_queue_name

  attr_accessor :ingest_mode, :ingester, :paths_to_scripts

  def perform( ingest_mode:, ingester:, paths_to_scripts:, **options )
    timestamp_begin
    email_targets << ingester if ingester.present?
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
    email_results
  rescue Exception => e # rubocop:disable Lint/RescueException
    # Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    # Rails.logger.error e.backtrace.join("\n")
    # raise e
    queue_exception_msgs e
    email_failure( exception: e, targets: [ingester] )
    raise e
  end

  def hostname
    Rails.configuration.hostname
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
    job_msg_queue << "Finished processing #{path_to_script} at #{DateTime.now}"
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
      return false unless validate_path_to_script script_path
    end
    return true
  end

  def validate_path_to_script( path )
    file = path
    return false unless queue_msg_unless?( file.present?, "ERROR: file path empty." )
    return false unless queue_msg_unless?( File.exist?( file ), "ERROR: file '#{file}' not found." )
    ext = File.extname file
    return false unless queue_msg_unless?( scripts_allowed_path_extensions.include?( ext ),
                                           "ERROR: expected file '#{file}' to have one of these extensions:",
                                           more_msgs: scripts_allowed_path_extensions )
    allowed = false
    scripts_allowed_path_prefixes.each do |prefix|
      if file.start_with? prefix
        allowed = true
        break
      end
    end
    return false unless queue_msg_unless?( allowed,
                                           "ERROR: expected file '#{file}' path to start with:",
                                           more_msgs: scripts_allowed_path_prefixes )
    return true
  end

end
