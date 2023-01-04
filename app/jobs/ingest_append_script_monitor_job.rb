# frozen_string_literal: true

# bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']
class IngestAppendScriptMonitorJob < ::Deepblue::DeepblueJob

  mattr_accessor :ingest_append_script_monitor_job_debug_verbose, default: true
  @@bold_puts = false

  EVENT = 'ingest append script monitor'

  attr_accessor :ingest_script
  attr_accessor :ingester
  attr_accessor :job_id
  attr_accessor :max_restarts
  attr_accessor :options
  attr_accessor :run_count
  attr_accessor :wait_duration

  def perform( id: nil,
               ingest_mode: 'append',
               ingester:,
               max_restarts: 5,
               path_to_script:,
               wait_duration: 1,
               **options )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "ingest_mode=#{ingest_mode}",
                                           "ingester=#{ingester}",
                                           "max_restarts=#{max_restarts}",
                                           "path_to_script=#{path_to_script}",
                                           "wait_duration=#{wait_duration}",
                                           "options=#{options}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose

    msg_handler.debug_verbose = ingest_append_script_monitor_job_debug_verbose
    initialize_with( id: id, debug_verbose: msg_handler.debug_verbose, options: options )
    email_targets << ingester if ingester.present?
    max_restarts ||= 5
    @max_restarts = max_restarts
    wait_duration ||= 1
    @wait_duration = wait_duration
    @ingester = ingester
    @options = options
    @options ||= {}
    @ingest_script = ingest_script_with( id: id, initial_yaml_file_path: path_to_script )
    @run_count = 0
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
                                 max_restarts: max_restarts,
                                 path_to_script: path_to_script,
                                 wait_duration: wait_duration,
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
    @ingest_script = IngestScript.append( curation_concern_id: id, initial_yaml_file_path: initial_yaml_file_path )
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

  def new_job( reload_script: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "reload_script=#{reload_script}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    job = IngestAppendScriptJob.send( :job_or_instantiate,
                                      ingest_script_path: @ingest_script.ingest_script_path,
                                      ingester: ingester,
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

  def reload_ingest_script
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@run_count=#{@run_count}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    @ingest_script = IngestScript.reload( ingest_script: @ingest_script, run_count: @run_count )
    @ingest_script.log_save( msg_handler.msg_queue )
    return @ingest_script
  end

  def retries_exhausted?
    @run_count > @max_restarts
  end

  def run( &block )
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
                                           "sleep wait_duration=#{wait_duration}",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    sleep wait_duration
  end

  def update_messages_from_ingest_script_log
    return if msg_handler.msg_queue.nil?
    @ingest_script = IngestScript.reload( ingest_script: @ingest_script )
    log = []
    run_count = @ingest_script.run_count
    for index in 1..run_count do
      run_log = @ingest_script.log_indexed( index )
      log.concat run_log if run_log.present?
    end
    msg_handler.msg_queue.concat log
  end

end
