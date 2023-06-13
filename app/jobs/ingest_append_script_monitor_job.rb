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
  INITIAL_WAIT_DURATION = 30
  INITIAL_WAIT_COUNT = 1
  INITIAL_WAIT_DEBUG_VERBOSE = false

  attr_accessor :child_job_id
  attr_accessor :id
  attr_accessor :ingest_script
  attr_accessor :ingest_mode
  attr_accessor :ingester
  attr_accessor :max_appends
  attr_accessor :max_restarts
  attr_accessor :max_restarts_base
  attr_accessor :options
  attr_accessor :path_to_script
  attr_accessor :restart
  attr_accessor :run_count
  attr_accessor :monitor_wait_duration
  attr_accessor :monitor_wait_count

  def perform( id: nil,
               ingest_mode: 'append',
               ingester:,
               max_appends:,
               max_restarts_base: ingest_append_script_max_restarts_base,
               monitor_wait_duration: ingest_append_script_monitor_wait_duration,
               path_to_script:,
               restart:,
               **options )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "ingest_mode=#{ingest_mode}",
                                           "ingester=#{ingester}",
                                           "max_appends=#{max_appends}",
                                           "max_restarts_base=#{max_restarts_base}",
                                           "monitor_wait_duration=#{monitor_wait_duration}",
                                           "path_to_script=#{path_to_script}",
                                           "restart=#{restart}",
                                           "options=#{options}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose

    msg_handler.debug_verbose = ingest_append_script_monitor_job_debug_verbose
    msg_handler.verbose = ingest_append_script_monitor_job_verbose || msg_handler.verbose
    initialize_with( id: id, debug_verbose: msg_handler.debug_verbose, options: options )
    @ingest_mode = ingest_mode
    @ingester = ingester
    email_targets << ingester if ingester.present?
    @max_appends = max_appends
    msg_handler.msg_verbose "max_appends=#{@max_appends}"
    @max_restarts_base = max_restarts_base
    msg_handler.msg_verbose "max_restarts_base=#{@max_restarts_base}"
    @monitor_wait_count = 0
    @monitor_wait_duration = monitor_wait_duration
    if 2 > @monitor_wait_duration
      @monitor_wait_duration = 2
    end
    msg_handler.msg_verbose "monitor_wait_duration=#{@monitor_wait_duration}"
    @path_to_script = path_to_script
    msg_handler.msg_verbose "path_to_script=#{@path_to_script}"
    @restart = restart
    msg_handler.msg_verbose "restart=#{@restart}"
    perform_init_rest
    if Rails.env.development?
      run { |reload_script| new_job( reload_script: reload_script ).perform_now }
    else
      run { |reload_script| new_job( reload_script: reload_script ).enqueue }
    end
    @ingest_script.active = false
    update_messages_from_ingest_script_log
    @ingest_script.monitor_job_end_timestamp = timestamp_end.to_formatted_s(:db)
    @ingest_script.script_section[:monitor_job_run_timestamp] = ''
    @ingest_script.script_section[:monitor_job_rerun_timestamp] = ''
    @ingest_script.monitor_job_begin_timestamp = ''
    @ingest_script.script_section[:monitor_child_job_begin_timestamp] = ''
    @ingest_script.job_begin_timestamp = ''
    @ingest_script.touch
    @ingest_script.move_to_finished( save: true, source: self.class.name ) if child_job_finished?
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
                                 monitor_wait_duration: monitor_wait_duration,
                                 path_to_script: path_to_script,
                                 restart: restart,
                                 options: options } )
    email_failure( task_name: self.class.name, exception: e, event: EVENT )
    raise e
  end

  def perform_init_rest
    @ingest_script = ingest_script_with( id: @id,
                                         initial_yaml_file_path: @path_to_script,
                                         max_appends: @max_appends,
                                         restart: @restart )
    @ingest_script.monitor_job_id = self.job_id
    @ingest_script.monitor_job_begin_timestamp = timestamp_begin.to_formatted_s(:db)
    @file_set_count = @ingest_script.file_set_count
    msg_handler.msg_verbose "file_set_count=#{@file_set_count}"
    if @restart
      @run_count = @ingest_script.run_count
      @ingest_script.finished = false
    else
      @run_count = 0
      @max_restarts ||= 0
      @ingest_script.max_restarts = @max_restarts_base
      if @max_appends > 0
        @max_restarts += ( @file_set_count / @max_appends ).to_i
      end
    end
    @ingest_script.active = true
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script.monitor_job_id=#{@ingest_script.monitor_job_id}",
                                           "@restart=#{@restart}",
                                           "@run_count=#{@run_count}",
                                           "@max_appends=#{@max_appends}",
                                           "@ingest_script.max_appends=#{@ingest_script.max_appends}",
                                           "@max_restarts=#{@max_restarts}",
                                           "@ingest_script.script_section[:max_restarts]=#{@ingest_script.script_section[:max_restarts]}",
                                           "@ingest_script=#{@ingest_script}",
                                           "@ingest_script.ingest_script_path=#{@ingest_script&.ingest_script_path}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    @ingest_script.touch( source: self.class.name ) # save the script
  end

  def child_job_running?
    return false if Rails.env.development?
    return false unless child_job_started?
    debug_verbose = INITIAL_WAIT_DEBUG_VERBOSE || ingest_append_script_monitor_job_debug_verbose
    rv = @child_job_id.present? && ::Deepblue::JobsHelper.job_running?( @child_job_id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@child_job_id=#{@child_job_id}",
                                           "child_job_running? true if rv=#{rv}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    return true if rv
    jobs = ::Deepblue::JobsHelper.jobs_running_by_class( klass: IngestAppendScriptJob )
    keys = ['payload', 'args', 'arguments', 'ingest_script_path' ]
    value = @ingest_script&.ingest_script_path
    jobs.select { |job| value == ::Deepblue::JobsHelper.job_value_by_keys( job: job, keys: keys ) }
    rv = jobs.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script&.ingest_script_path=#{@ingest_script&.ingest_script_path}",
                                           "child_job_running?=#{rv}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    return rv
  end

  def child_job_ended?
    rv = @ingest_script.job_end_timestamp.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script.job_end_timestamp.present?=#{rv}",
                                           "child_job_ended?=#{rv}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    return rv
  end

  def child_job_finished?
    rv = @ingest_script.finished?
    # return !child_job_running?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script.finished?=#{rv}",
                                           "child_job_finished?=#{rv}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    return rv
  end

  def child_job_started?
    rv = @ingest_script.job_begin_timestamp.present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script.job_begin_timestamp.present?=#{rv}",
                                           "child_job_started?=#{rv}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    return rv
  end

  def child_job_waiting_to_started?
    monitor_child_job_begin_timestamp = @ingest_script.script_section[:monitor_child_job_begin_timestamp]
    job_begin_timestamp = @ingest_script.job_begin_timestamp
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "monitor_child_job_begin_timestamp=#{monitor_child_job_begin_timestamp}",
                                           "job_begin_timestamp=#{job_begin_timestamp}",
                                           "child_job_waiting_to_started?=#{monitor_child_job_begin_timestamp.present? && job_begin_timestamp.blank?}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    monitor_child_job_begin_timestamp.present? && job_begin_timestamp.blank?
  end

  def ingest_script_with( id:, initial_yaml_file_path:, max_appends:, restart: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "initial_yaml_file_path=#{initial_yaml_file_path}",
                                           "max_appends=#{max_appends}",
                                           "restart=#{restart}",
                                           "" ] if ingest_append_script_monitor_job_debug_verbose
    @ingest_script = IngestScript.append( curation_concern_id: id,
                                          initial_yaml_file_path: initial_yaml_file_path,
                                          max_appends: max_appends,
                                          restart: restart,
                                          run_count: run_count,
                                          source: "#{self.class.name}.ingest_script_with" )
  rescue Exception => e
    msg_handler.msg_error "IngestAppendScriptMonitorJob.ingest_script_with(#{id},#{initial_yaml_file_path},#{restart}) #{e.class}: #{e.message}"
    raise e
  end

  def ingest_status
    status = IngestStatus.where( cc_id: id )
    return "Not found" if status.nil?
    # return "Ingest status: cc_id=#{status.cc_id}, cc_type=#{status.cc_type}, status=#{status}, status_date=#{status.status_date}"
    return status
  end

  def keep_running?
    verbose_debug = ingest_append_script_monitor_job_debug_verbose
    return false unless File.exist? @path_to_script
    child_job_running = child_job_running?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "keep_running? true if child_job_running=#{child_job_running}",
                                           "" ], bold_puts: @@bold_puts if verbose_debug
    return true if child_job_running
    finished = child_job_finished?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "keep_running? false if finished=#{finished}",
                                           "" ], bold_puts: @@bold_puts if verbose_debug
    retries_exhausted = retries_exhausted?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "keep_running? false if retries_exhausted=#{retries_exhausted}",
                                           "" ], bold_puts: @@bold_puts if verbose_debug
    return false if retries_exhausted
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "keep_running?=true (fall through)",
                                           "" ], bold_puts: @@bold_puts if verbose_debug
    return false if finished
    return true
  end

  def log_save
    msg_handler.msg_verbose msg_handler.here
    @ingest_script.log_save( msg_handler.msg_queue, source: self.class.name )
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
    child_job = IngestAppendScriptJob.send( :job_or_instantiate,
                                            id: id,
                                            ingest_script_path: @ingest_script.ingest_script_path,
                                            ingester: ingester,
                                            max_appends: @max_appends,
                                            restart: @restart,
                                            run_count: @run_count,
                                            **options )
    @child_job_id = child_job.job_id
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "child_job=#{child_job}",
                                           "@child_job_id=#{@child_job_id}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    if Rails.env.production?
      sleep INITIAL_WAIT_DURATION
    end
    reload_ingest_script if reload_script
    return child_job
  rescue Exception => e
    report_error( e, "IngestAppendScriptMonitorJob.new_job(#{reload_script})" )
    raise e
  end

  def report_error( e, msg, puts_backtrace: false )
    msg_handler.msg_error "#{msg} #{e.class}: #{e.message}"
    @ingest_script.touch( source: self.class.name ) if @ingest_script.present?
    # @ingest_script.touch( source: self.class.name ) if @ingest_script.present?
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
                                          run_count: @run_count,
                                          source: "#{self.class.name}.reload_ingest_script" )
    log_save if save_log
    return @ingest_script
  end

  def retries_exhausted?
    rv = @run_count > @max_restarts_base
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "retries_exhausted? @run_count > @max_restarts_base=#{rv}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    return rv
  end

  def run( &block )
    debug_verbose = ingest_append_script_monitor_job_debug_verbose
    msg_handler.msg_verbose msg_handler.here
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@run_count=#{@run_count}",
                                           "ingest_status=#{ingest_status}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    @ingest_script.script_section[:monitor_job_run_timestamp] = timestamp_now
    @ingest_script.script_section[:monitor_job_rerun_timestamp] = ''
    @ingest_script.script_section[:monitor_child_job_begin_timestamp] = ''
    @ingest_script.job_begin_timestamp = ''
    @ingest_script.touch
    stop_running = retries_exhausted? || child_job_finished?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "stop_running=#{stop_running}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    retry_flag = false
    while !stop_running do
      begin
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "@run_count=#{@run_count}",
                                               "ingest_status=#{ingest_status}",
                                               "" ], bold_puts: @@bold_puts if debug_verbose
        run_retry( retry_flag: retry_flag, &block )
        reload_ingest_script
        stop_running = retries_exhausted? || child_job_finished?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "stop_running=#{stop_running}",
                                               "" ], bold_puts: @@bold_puts if debug_verbose
      rescue Exception => e # rubocop:disable Lint/RescueException
        report_error( e, "IngestAppendScriptMonitorJob.run" )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "Exception caught during run.",
                                               "e=#{e.class.name}",
                                               "e.message=#{e.message}",
                                               "e.backtrace:" ] + e.backtrace,
                                             bold_puts: @@bold_puts if debug_verbose
        reload_ingest_script
        stop_running = retries_exhausted? || child_job_finished?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "stop_running=#{stop_running}",
                                               "" ], bold_puts: @@bold_puts if debug_verbose
        raise e if stop_running
        retry_flag = true
      end
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Job finished: @child_job_id=#{@child_job_id} after #{@run_count} runs.",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
  end

  def run_retry( retry_flag:, &block )
    debug_verbose = ingest_append_script_monitor_job_debug_verbose
    msg_handler.msg_verbose msg_handler.here
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "retry_flag=#{retry_flag}",
                                           "@run_count=#{@run_count}",
                                           "ingest_status=#{ingest_status}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    if retry_flag
      @ingest_script.script_section[:monitor_job_run_timestamp] = timestamp_now
    else
      @ingest_script.script_section[:monitor_job_rerun_timestamp] = timestamp_now
    end
    @ingest_script.script_section[:monitor_child_job_begin_timestamp] = timestamp_now
    @ingest_script.touch
    @run_count = @run_count + 1
    yield( reload_script: retry_flag )
    reload_ingest_script
    keep_running = keep_running?
    while keep_running do
      run_sleep
      child_job_running = child_job_running?
      child_job_waiting_to_started = child_job_waiting_to_started?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "child_job_running=#{child_job_running}",
                                             "child_job_waiting_to_started=#{child_job_waiting_to_started}",
                                             "@run_count=#{@run_count}",
                                             "ingest_status=#{ingest_status}",
                                             "" ], bold_puts: @@bold_puts if debug_verbose
      if !child_job_running && !child_job_waiting_to_started?
        @run_count = @run_count + 1
        yield( reload_script: true )
      end
      reload_ingest_script
      keep_running = keep_running?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@run_count=#{@run_count}",
                                             "keep_running=#{keep_running}",
                                             "ingest_status=#{ingest_status}",
                                             "" ], bold_puts: @@bold_puts if debug_verbose
    end
  end

  def run_sleep
    debug_verbose = INITIAL_WAIT_DEBUG_VERBOSE || ingest_append_script_monitor_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Rails.env.development?=#{Rails.env.development?}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    return if Rails.env.development?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "sleep monitor_wait_count=#{monitor_wait_count}",
                                           "sleep monitor_wait_duration=#{monitor_wait_duration}",
                                           "" ], bold_puts: @@bold_puts if debug_verbose
    wait_duration = monitor_wait_duration
    if INITIAL_WAIT_COUNT < @monitor_wait_count && INITIAL_WAIT_DURATION > wait_duration
      wait_duration = INITIAL_WAIT_DURATION
    end
    sleep wait_duration
    @monitor_wait_count += 1
  end

  def timestamp_now
    DateTime.now.to_formatted_s(:db)
  end

  def update_messages_from_ingest_script_log
    msg_handler.msg_verbose msg_handler.here
    reload_ingest_script( save_log: true )
    return if msg_handler.msg_queue.nil?
    # @ingest_script = IngestScript.reload( ingest_script: @ingest_script,
    #                                       source: "#{self.class.name}.update_messages_from_ingest_script_log" )
    log = []
    run_count = @ingest_script.run_count
    for index in 1..run_count do
      run_log = @ingest_script.log_indexed( index )
      log.concat run_log if run_log.present?
    end
    msg_handler.msg_queue.concat log
  end

end
