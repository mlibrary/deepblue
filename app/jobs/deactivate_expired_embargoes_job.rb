# frozen_string_literal: true

require_relative '../services/deepblue/deactivate_expired_embargoes_service'

class DeactivateExpiredEmbargoesJob < ::Hyrax::ApplicationJob

  mattr_accessor :deactivate_expired_embargoes_job_debug_verbose
  deactivate_expired_embargoes_job_debug_verbose = ::Deepblue::JobTaskHelper.deactivate_expired_embargoes_job_debug_verbose

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


  include JobHelper # see JobHelper for :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end
  queue_as :scheduler

  def perform( *args )
    timestamp_begin
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           ::Deepblue::LoggingHelper.obj_class( 'args', args ),
                                           "" ] if deactivate_expired_embargoes_job_debug_verbose
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: "deactivate_expired_embargoes" )
    options = ::Deepblue::JobTaskHelper.initialize_options_from *args
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           "options=#{options}",
                                           ::Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ] if deactivate_expired_embargoes_job_debug_verbose
    verbose = job_options_value(options, key: 'verbose', default_value: false )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    email_owner = job_options_value(options, key: 'email_owner', default_value: true )
    ::Deepblue::LoggingHelper.debug "email_owner=#{email_owner}" if verbose
    skip_file_sets = job_options_value(options, key: 'skip_file_sets', default_value: true )
    ::Deepblue::LoggingHelper.debug "@skip_file_sets=#{skip_file_sets}" if verbose
    test_mode = job_options_value(options, key: 'test_mode', default_value: false )
    ::Deepblue::LoggingHelper.debug "test_mode=#{test_mode}" if verbose
    ::Deepblue::DeactivateExpiredEmbargoesService.new( email_owner: email_owner,
                                                       skip_file_sets: skip_file_sets,
                                                       test_mode: test_mode,
                                                       verbose: verbose ).run
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
