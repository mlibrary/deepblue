# frozen_string_literal: true

class IngestAppendScriptMonitorJob < ::Deepblue::DeepblueJob

  mattr_accessor :ingest_append_script_monitor_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_append_script_monitor_job_debug_verbose

  mattr_accessor :ingest_append_script_monitor_job_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_append_script_monitor_job_verbose

  mattr_accessor :ingest_append_script_max_restarts_base,
                 default: ::Deepblue::IngestIntegrationService.ingest_append_script_max_restarts_base
  mattr_accessor :ingest_append_script_monitor_wait_duration,
                 default: ::Deepblue::IngestIntegrationService.ingest_append_script_monitor_wait_duration

  @@bold_puts = false

  EVENT = 'ingest append script monitor'

  attr_accessor :ingest_script
  attr_accessor :ingester
  attr_accessor :job_id
  attr_accessor :max_appends
  attr_accessor :max_restarts
  attr_accessor :max_restarts_base
  attr_accessor :options
  attr_accessor :run_count
  attr_accessor :monitor_wait_duration

  def perform( id: nil,
               ingest_mode: 'append',
               ingester:,
               max_appends:,
               max_restarts_base: ingest_append_script_max_restarts_base,
               path_to_script:,
               monitor_wait_duration: ingest_append_script_monitor_wait_duration,
               **options )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "ingest_mode=#{ingest_mode}",
                                           "ingester=#{ingester}",
                                           "max_appends=#{max_appends}",
                                           "max_restarts_base=#{max_restarts_base}",
                                           "path_to_script=#{path_to_script}",
                                           "monitor_wait_duration=#{monitor_wait_duration}",
                                           "options=#{options}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose

    msg_handler.debug_verbose = ingest_append_script_monitor_job_debug_verbose
    msg_handler.verbose = ingest_append_script_monitor_job_verbose || msg_handler.verbose
    initialize_with( id: id, debug_verbose: msg_handler.debug_verbose, options: options )
    email_targets << ingester if ingester.present?
    @run_count = 0
    @max_appends = max_appends
    msg_handler.msg_verbose "max_appends=#{@max_appends}"
    @max_restarts_base = max_restarts_base
    msg_handler.msg_verbose "max_restarts_base=#{@max_restarts_base}"
    @monitor_wait_duration = monitor_wait_duration
    msg_handler.msg_verbose "monitor_wait_duration=#{@monitor_wait_duration}"
    @ingester = ingester
    @options = options
    @options ||= {}
    @ingest_script = ingest_script_with( id: id, initial_yaml_file_path: path_to_script )
    @file_set_count = @ingest_script.file_set_count
    msg_handler.msg_verbose "file_set_count=#{@file_set_count}"
    @max_restarts = @max_restarts_base
    if max_appends > 0
      @max_restarts += ( @file_set_count / max_appends ).to_i
    end
    @ingest_script.script_section[:max_restarts] = @max_restarts
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@max_appends=#{@max_appends}",
                                           "@ingest_script.max_appends=#{@ingest_script.max_appends}",
                                           "@max_restarts=#{@max_restarts}",
                                           "@ingest_script.script_section[:max_restarts]=#{@ingest_script.script_section[:max_restarts]}",
                                           "@ingest_script=#{@ingest_script}",
                                           "@ingest_script.ingest_script_path=#{@ingest_script&.ingest_script_path}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    @ingest_script.touch # save the script
    if Rails.env.development?
      run { |reload_script| new_job( reload_script: reload_script ).perform_now }
    else
      run { |reload_script| new_job( reload_script: reload_script ).enqueue }
    end
    update_messages_from_ingest_script_log
    @ingest_script.move_to_finished( save: true ) if @ingest_script.finished?
    # TODO: email the results stored in ingest script to user
    # ingest_script.script_section[:email_after_msg_lines]
    # It looks like the move when finished is actually copying...
    email_results( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    report_error( e, "IngestAppendScriptMonitorJob.perform" )
    job_status_register( exception: e,
                         args: { id: id,
                                 ingest_mode: ingest_mode,
                                 ingester: ingester,
                                 max_appends: max_appends,
                                 max_restarts_base: max_restarts_base,
                                 path_to_script: path_to_script,
                                 monitor_wait_duration: monitor_wait_duration,
                                 options: options } )
    email_failure( task_name: self.class.name, exception: e, event: EVENT )
    raise e
  end

  def ingest_script_with( id:, initial_yaml_file_path: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "initial_yaml_file_path=#{initial_yaml_file_path}",
                                           "" ] if ingest_append_script_monitor_job_debug_verbose
    @ingest_script = IngestScript.append( curation_concern_id: id,
                                          initial_yaml_file_path: initial_yaml_file_path,
                                          max_appends: max_appends,
                                          run_count: run_count )
  rescue Exception => e
    msg_handler.msg_error "IngestAppendScriptMonitorJob.ingest_script_with(#{initial_yaml_file_path}) #{e.class}: #{e.message}"
    raise e
  end

  def keep_running?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "false if @ingest_script.finished?=#{@ingest_script.finished?}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    return false if @ingest_script.finished?
    retries_exhausted = retries_exhausted?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "false if retries_exhausted=#{retries_exhausted}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    return false if retries_exhausted
    if !Rails.env.development?
      rv =  ::Deepblue::JobsHelper.job_running?( job_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv (::Deepblue::JobsHelper.job_running?( job_id ))=#{rv}",
                                             "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
      return rv
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "true",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    return true
  end

  def log_save
    msg_handler.msg_verbose msg_handler.here
    @ingest_script.log_save( msg_handler.msg_queue )
  end

  def new_job( reload_script: false )
    msg_handler.msg_verbose msg_handler.here
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "reload_script=#{reload_script}",
                                           "ingest_script_path=#{@ingest_script.ingest_script_path}",
                                           "max_appends=#{@max_appends}",
                                           "ingester=#{ingester}",
                                           "run_count=#{@run_count}",
                                           "options=#{options}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    job = IngestAppendScriptJob.send( :job_or_instantiate,
                                      ingest_script_path: @ingest_script.ingest_script_path,
                                      ingester: ingester,
                                      max_appends: @max_appends,
                                      run_count: @run_count,
                                      **options )
    @job_id = job.job_id
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job=#{job}",
                                           "job_id=#{@job_id}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    reload_ingest_script if reload_script
    return job
  rescue Exception => e
    report_error( e, "IngestAppendScriptMonitorJob.new_job(#{reload_script})" )
    raise e
  end

  def report_error( e, msg, puts_backtrace: false )
    msg_handler.msg_error "#{msg} #{e.class}: #{e.message}"
    @ingest_script.touch if @ingest_script.present?
    # @ingest_script.touch if @ingest_script.present?
    puts e.backtrace[0..30].pretty_inspect if puts_backtrace
  end

  def reload_ingest_script( save_log: false )
    msg_handler.msg_verbose msg_handler.here
    msg_handler.msg_verbose msg_handler.called_from
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "save_log=#{save_log}",
                                           "@ingest_script.ingest_script_path=#{@ingest_script&.ingest_script_path}",
                                           "@run_count=#{@run_count}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    @ingest_script = IngestScript.reload( ingest_script: @ingest_script,
                                          max_appends: @max_appends,
                                          run_count: @run_count )
    log_save if save_log
    return @ingest_script
  end

  def retries_exhausted?
    @run_count > @max_restarts_base
  end

  def run( &block )
    msg_handler.msg_verbose msg_handler.here
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@run_count=#{@run_count}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    finished = @ingest_script.finished?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "finished=#{finished}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    retry_flag = false
    while !finished do
      begin
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "@run_count=#{@run_count}",
                                               "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
        run_retry( retry_flag: retry_flag, &block )
        finished = reload_ingest_script.finished? || retries_exhausted?
      rescue Exception => e # rubocop:disable Lint/RescueException
        report_error( e, "IngestAppendScriptMonitorJob.run" )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "Exception caught during run.",
                                               "e=#{e.class.name}",
                                               "e.message=#{e.message}",
                                               "e.backtrace:" ] + e.backtrace,
                                             bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
        finished = reload_ingest_script.finished? || retries_exhausted?
        raise e if finished
        retry_flag = true
      end
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Job finished: job_id=#{job_id} after #{@run_count} runs.",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
  end

  def run_retry( retry_flag:, &block )
    msg_handler.msg_verbose msg_handler.here
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "retry_flag=#{retry_flag}",
                                           "@run_count=#{@run_count}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    @run_count = @run_count + 1
    yield( reload_script: retry_flag )
    reload_ingest_script
    keep_running = keep_running?
    while keep_running do
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@run_count=#{@run_count}",
                                             "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
      run_sleep
      @run_count = @run_count + 1
      yield( reload_script: true )
      reload_ingest_script
      keep_running = keep_running?
      if retries_exhausted?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "@run_count=#{@run_count}",
                                               "retries_exhausted",
                                               "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
      end
    end
  end

  def run_sleep
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Rails.env.development?=#{Rails.env.development?}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    return if Rails.env.development?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "sleep monitor_wait_duration=#{monitor_wait_duration}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    sleep monitor_wait_duration
  end

  def update_messages_from_ingest_script_log
    msg_handler.msg_verbose msg_handler.here
    reload_ingest_script( save_log: true )
    return if msg_handler.msg_queue.nil?
    # @ingest_script = IngestScript.reload( ingest_script: @ingest_script )
    log = []
    run_count = @ingest_script.run_count
    for index in 1..run_count do
      run_log = @ingest_script.log_indexed( index )
      log.concat run_log if run_log.present?
    end
    msg_handler.msg_queue.concat log
  end

end
