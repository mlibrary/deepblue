# frozen_string_literal: true

class MultipleIngestScriptsJob < ::Deepblue::DeepblueJob

  mattr_accessor :multiple_ingest_scripts_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.multiple_ingest_scripts_job_debug_verbose

  mattr_accessor :scripts_allowed_path_extensions, default: [ '.yml', '.yaml' ]

  mattr_accessor :scripts_allowed_path_prefixes,
                 default: [ '/deepbluedata-prep/', './data/reports/', '/deepbluedata-globus/upload/' ]

  include JobHelper # see JobHelper for :by_request_only, :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as Hyrax.config.ingest_queue_name

  attr_accessor :ingest_mode, :ingester, :paths_to_scripts

  def perform( ingest_mode:,
               ingester:,
               paths_to_scripts:,
               debug_verbose: multiple_ingest_scripts_job_debug_verbose,
               **options )

    msg_handler.debug_verbose = debug_verbose || multiple_ingest_scripts_job_debug_verbose
    initialize_with( debug_verbose: debug_verbose, options: options )
    email_targets << ingester if ingester.present?
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                                 ::Deepblue::LoggingHelper.called_from,
                                 "ingest_mode=#{ingest_mode}",
                                 "ingester=#{ingester}",
                                 "paths_to_scripts=#{paths_to_scripts}",
                                 "options=#{options}",
                                 "" ] if msg_handler.debug_verbose
    self.ingest_mode = ingest_mode
    self.ingester = ingester
    init_paths_to_scripts paths_to_scripts
    return unless self.paths_to_scripts.present?
    return unless validate_paths_to_scripts
    self.paths_to_scripts.each do |script_path|
      ingest_script_run( path_to_script: script_path )
    end
    email_results( msg_handler: msg_handler, debug_verbose: debug_verbose )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    msg_handler.msg_exception e
    email_failure( exception: e, targets: [ingester], msg_handler: msg_handler, debug_verbose: debug_verbose )
    raise e
  end

  def hostname
    Rails.configuration.hostname
  end

  def ingest_script_run( path_to_script: )
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "path_to_script=#{path_to_script}",
                                  "" ] if msg_handler.debug_verbose
    return true unless ::Deepblue::IngestIntegrationService.ingest_append_ui_allow_scripts_to_run
    return false if path_to_script.blank?
    msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                                  ::Deepblue::LoggingHelper.called_from,
                                  "IngestAppendScriptJob.perform_now( path_to_script: #{path_to_script}, ingester: #{ingester} )",
                                  "" ] if msg_handler.debug_verbose
    IngestScriptJob.perform_now( ingest_mode: ingest_mode,
                                 ingester: ingester,
                                 path_to_script: path_to_script )
    msg_handler.msg "Finished processing #{path_to_script} at #{DateTime.now}"
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
    return false unless msg_handler.msg_error_unless?( file.present?, msg: "file path empty." )
    return false unless msg_handler.msg_error_unless?( File.exist?(file), msg: "file '#{file}' not found." )
    ext = File.extname file
    return false unless msg_handler.msg_error_unless?( scripts_allowed_path_extensions.include?( ext ),
                                                       msg: ["expected file '#{file}' to have one of these extensions:"] +
                                                         scripts_allowed_path_extensions )
    allowed = false
    scripts_allowed_path_prefixes.each do |prefix|
      if file.start_with? prefix
        allowed = true
        break
      end
    end
    return false unless msg_handler.msg_error_unless?( allowed,
                                                       msg: ["expected file '#{file}' path to start with:"] +
                                                         scripts_allowed_path_prefixes )
    return true
  end

end
