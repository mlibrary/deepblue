# frozen_string_literal: true

require_relative '../services/deepblue/deactivate_expired_embargoes_service'

class DeactivateExpiredEmbargoesJob < AbstractRakeTaskJob

  mattr_accessor :deactivate_expired_embargoes_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.deactivate_expired_embargoes_job_debug_verbose

  mattr_accessor :default_args, default: { by_request_only: false,
                                           from_dashboard: '',
                                           is_quiet: false,
                                           email_owner: true,
                                           skip_file_sets: true,
                                           test_mode: false,
                                           task: false,
                                           verbose: false }

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

deactivate_expired_embargoes_job:
  # Run once a day, five minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M H
  cron: '5 5 * * *'
  # rails_env: production
  class: DeactivateExpiredEmbargoesJob
  queue: scheduler
  description: Deactivate embargoes job.
  args:
    email_owner: true
    test_mode: false
    verbose: true

END_OF_SCHEDULER_ENTRY


  queue_as :scheduler

  def perform( *args )
    # timestamp_begin
    # msg_handler.debug_verbose = deactivate_expired_embargoes_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           ::Deepblue::LoggingHelper.obj_class( 'args', args ),
                                           "" ] if deactivate_expired_embargoes_job_debug_verbose
    initialized = initialize_from_args( *args, debug_verbose: deactivate_expired_embargoes_job_debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "initialized=#{initialized}",
                                           "" ] if deactivate_expired_embargoes_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: event_name )
    return unless initialized
    email_owner    = job_options_value( key: 'email_owner',    default_value: default_args[:email_owner] )
    skip_file_sets = job_options_value( key: 'skip_file_sets', default_value: default_args[:skip_file_sets] )
    test_mode      = job_options_value( key: 'test_mode',      default_value: default_args[:test_mode] )
    ::Deepblue::DeactivateExpiredEmbargoesService.new( email_owner: email_owner,
                                                       job_msg_queue: msg_handler.msg_queue,
                                                       skip_file_sets: skip_file_sets,
                                                       test_mode: test_mode,
                                                       verbose: verbose ).run
    timestamp_end = DateTime.now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                                           "timestamp_end=#{timestamp_end}",
                                           "" ] if deactivate_expired_embargoes_job_debug_verbose
    email_results( task_name: task_name, event: event_name )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args, rails_log: true )
    email_failure( task_name: task_name, exception: e, event: event_name )
    raise e
  end

end
