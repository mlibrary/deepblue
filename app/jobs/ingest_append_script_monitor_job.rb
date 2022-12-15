# frozen_string_literal: true

# bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']
class IngestAppendScriptMonitorJob < ::Deepblue::DeepblueJob

  mattr_accessor :ingest_append_script_monitor_job_debug_verbose, default: true
  @@bold_puts = true

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
    @ingest_script = ingest_script_with( id: id, initial_yaml_file_path: path_to_script )
    @run_count = 0
    run_in_dev if Rails.env.development?
    run_and_monitor_prod unless Rails.env.development?
    email_results( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
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
    msg_handler.msg_error "IngestAppendContentService.call(#{initial_yaml_file_path}) #{e.class}: #{e.message}"
    raise e
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
    @ingest_script = IngestScript.reload( ingest_script: @ingest_script, run_count: @run_count ) if reload_script
    return job
  rescue Exception => e
    puts e.backtrace[0..30].pretty_inspect
    raise e
  end

  def run_and_monitor_prod
    @wait_duration = 1 if @wait_duration < 1
    new_job.perform_later
    keep_running = job_running?( job_id )
    while keep_running do
      sleep wait_duration
      keep_running = job_running?( job_id )
      unless keep_running
        @run_count = @run_count + 1
        if @run_count > @max_restarts
          keep_running = false
        else
          new_job( reload_script: true ).perform_later
          keep_running = job_running?( job_id )
        end
      end
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Job finished: job_id=#{job_id} after #{@run_count} runs.",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    update_messages_from_ingest_script_log
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    raise e
  end

  def run_in_dev
    new_job.perform_now
    @run_count = 1
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Job finished: job_id=#{job_id} after #{@run_count} runs.",
                                           "" ], bold_puts: @@bold_puts if ingest_append_script_monitor_job_debug_verbose
    update_messages_from_ingest_script_log
  end

  def update_messages_from_ingest_script_log
    @ingest_script = IngestScript.reload( ingest_script: @ingest_script )
    log = @ingest_script.log
    msg_queue = msg_handler.msg_queue
    # TODO: add backed up logs
    msg_handler.msg_queue = msg_queue + log
  end

end
