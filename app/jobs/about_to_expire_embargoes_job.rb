# frozen_string_literal: true

require_relative '../services/deepblue/about_to_expire_embargoes_service'

class AboutToExpireEmbargoesJob < AbstractRakeTaskJob

  mattr_accessor :about_to_expire_embargoes_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.about_to_expire_embargoes_job_debug_verbose

  mattr_accessor :default_args, default: { email_owner: true,
                                           expiration_lead_days: 7,
                                           skip_file_sets: true,
                                           test_mode: false,
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

  include JobHelper # see JobHelper for :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as :scheduler

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           ::Deepblue::LoggingHelper.obj_class( 'args', args ),
                                           "" ] if about_to_expire_embargoes_job_debug_verbose
    initialized = initialize_from_args *args
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "initialized=#{initialized}",
                                           "" ] if about_to_expire_embargoes_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: event_name )
    email_owner          = options_value( key: 'email_owner',          default_value: default_args[:email_owner] )
    expiration_lead_days = options_value( key: 'expiration_lead_days', default_value: default_args[:expiration_lead_days] )
    skip_file_sets       = options_value( key: 'skip_file_sets',       default_value: default_args[:skip_file_sets] )
    test_mode            = options_value( key: 'test_mode',            default_value: default_args[:test_mode] )
    ::Deepblue::AboutToExpireEmbargoesService.new( email_owner: email_owner,
                                                   expiration_lead_days: expiration_lead_days,
                                                   job_msg_queue: job_msg_queue,
                                                   skip_file_sets: skip_file_sets,
                                                   test_mode: test_mode,
                                                   verbose: verbose ).run
    timestamp_end = DateTime.now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_msg_queue=#{job_msg_queue}",
                                           "timestamp_end=#{timestamp_end}",
                                           "" ] if about_to_expire_embargoes_job_debug_verbose
    email_results( task_name: task_name, event: event_name )
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace[0..20].join("\n")
    email_failure( task_name: task_name, exception: e, event: event_name )
    raise e
  end

end
