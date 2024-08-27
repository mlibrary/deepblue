# frozen_string_literal: true

require_relative '../services/deepblue/about_to_expire_embargoes_service'

class AboutToExpireEmbargoesJob < AbstractRakeTaskJob

  mattr_accessor :about_to_expire_embargoes_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.about_to_expire_embargoes_job_debug_verbose

  mattr_accessor :default_args, default: { by_request_only: false,
                                           from_dashboard: '',
                                           email_owner: true,
                                           expiration_lead_days: 7,
                                           is_quiet: false,
                                           skip_file_sets: true,
                                           test_mode: false,
                                           task: false,
                                           verbose: false }


  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

about_to_deactivate_embargoes_job:
  # Run once a day, fifteen minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M  H
  cron: '15 5 * * *'
  # rails_env: production
  class: AboutToExpireEmbargoesJob
  queue: scheduler
  description: About to deactivate embargoes job.
  args:
    email_owner: true
    test_mode: false
    verbose: true

END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  def perform( *args )
    initialized = initialize_from_args( args: args, debug_verbose: about_to_expire_embargoes_job_debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "initialized=#{initialized}",
                                           "" ] if msg_handler.debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: event_name )
    return unless initialized
    email_owner          = job_options_value( key: 'email_owner',          default_value: default_args[:email_owner] )
    expiration_lead_days = job_options_value( key: 'expiration_lead_days', default_value: default_args[:expiration_lead_days] )
    skip_file_sets       = job_options_value( key: 'skip_file_sets',       default_value: default_args[:skip_file_sets] )
    test_mode            = job_options_value( key: 'test_mode',            default_value: default_args[:test_mode] )
    ::Deepblue::AboutToExpireEmbargoesService.new( email_owner: email_owner,
                                                   expiration_lead_days: expiration_lead_days,
                                                   msg_handler: msg_handler,
                                                   skip_file_sets: skip_file_sets,
                                                   test_mode: test_mode,
                                                   debug_verbose: msg_handler.debug_verbose ).run
    timestamp_end = DateTime.now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                                           "timestamp_end=#{timestamp_end}",
                                           "" ] if msg_handler.debug_verbose
    email_results( task_name: task_name, event: event_name )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args, rails_log: true )
    email_failure( task_name: task_name, exception: e, event: event_name )
    raise e
  end

end
