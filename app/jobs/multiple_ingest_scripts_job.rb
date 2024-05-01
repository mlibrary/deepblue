# frozen_string_literal: true

class MultipleIngestScriptsJob < ::Deepblue::DeepblueJob

  mattr_accessor :multiple_ingest_scripts_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.multiple_ingest_scripts_job_debug_verbose

  mattr_accessor :scripts_allowed_path_extensions, default: [ '.yml', '.yaml' ]

  mattr_accessor :scripts_allowed_path_prefixes,
                 default: [ "#{::Deepblue::GlobusIntegrationService.globus_prep_dir}",
                            "#{::Deepblue::GlobusIntegrationService.globus_upload_dir}",
                            './data/',
                            "/Volumes/ulib-dbd-prep/"] +
                   Rails.configuration.shared_drive_mounts

  queue_as Hyrax.config.ingest_queue_name

  attr_accessor :ingest_mode, :ingester, :paths_to_scripts, :paths_to_scripts_invalid

  def perform( ingest_mode:,
               ingester:,
               paths_to_scripts:,
               debug_verbose: multiple_ingest_scripts_job_debug_verbose,
               **options )

    msg_handler.debug_verbose = debug_verbose || multiple_ingest_scripts_job_debug_verbose
    initialize_with( debug_verbose: debug_verbose, options: options )
    email_targets << ingester if ingester.present?
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "ingest_mode=#{ingest_mode}",
                             "ingester=#{ingester}",
                             "paths_to_scripts=#{paths_to_scripts}",
                             "options=#{options}",
                             "" ] if debug_verbose
    @ingest_mode = ingest_mode
    @ingester = ingester
    begin # until true for break
      init_paths_to_scripts paths_to_scripts
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "self.paths_to_scripts=#{self.paths_to_scripts}",
                               "self.paths_to_scripts.present?=#{self.paths_to_scripts.present?}",
                               "" ] if debug_verbose
      break unless self.paths_to_scripts.present?
      break unless validate_paths_to_scripts
      self.paths_to_scripts.each do |script_path|
        ingest_script_run( path_to_script: script_path )
      end
    end until true # for break
    perform_email_results
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    puts e.message
    puts e.backtrace.pretty_inspect
    # msg_handler.msg_exception( e, force_to_console: true )
    job_status_register( exception: e, rails_log: true, args: { ingest_mode: ingest_mode,
                                                                ingester: ingester,
                                                                paths_to_scripts: paths_to_scripts,
                                                                debug_verbose: debug_verbose,
                                                                options: options } )
    email_failure( exception: e, targets: [ingester] )
    raise e
  end

  def perform_email_results
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "" ] if debug_verbose
    email_results
  end

  def hostname
    Rails.configuration.hostname
  end

  def ingest_script_run( path_to_script: )
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "path_to_script=#{path_to_script}",
                             "" ] if msg_handler.debug_verbose
    return true unless ::Deepblue::IngestIntegrationService.ingest_append_ui_allow_scripts_to_run
    return false if path_to_script.blank?
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "IngestScriptJob.perform_now( path_to_script: #{path_to_script}, ingester: #{ingester} )",
                              "" ] if msg_handler.debug_verbose
    job = IngestScriptJob.job_or_instantiate( ingest_mode: ingest_mode,
                                              ingester: ingester,
                                              path_to_script: path_to_script,
                                              child_job: true,
                                              verbose: verbose )
    job.msg_handler = msg_handler
    job.perform_now
    # IngestScriptJob.perform_now( ingest_mode: ingest_mode,
    #                              ingester: ingester,
    #                              path_to_script: path_to_script )
    msg_handler.msg "Finished processing #{path_to_script} at #{DateTime.now}"
    true
  end

  def init_paths_to_scripts( paths )
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "paths=#{paths}",
                             "" ] if debug_verbose
    @paths_to_scripts = paths if paths.is_a? Array
    @paths_to_scripts = paths.split( "\n" ) if paths.is_a? String
    @paths_to_scripts = @paths_to_scripts.map { |path| path.strip }
    @paths_to_scripts = @paths_to_scripts.select { |path| path.present? }
  end

  def validate_paths_to_scripts
    @paths_to_scripts_invalid = []
    paths_to_scripts.each do |script_path|
      next if validate_path_to_script script_path
      @paths_to_scripts_invalid << script_path
    end
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "@paths_to_scripts_invalid=#{@paths_to_scripts_invalid}",
                             "" ] if debug_verbose
    @paths_to_scripts_invalid.blank?
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
