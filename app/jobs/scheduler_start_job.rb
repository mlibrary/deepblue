# frozen_string_literal: true

class SchedulerStartJob < ::Deepblue::DeepblueJob

  mattr_accessor :scheduler_start_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.scheduler_start_job_debug_verbose

  queue_as :default

  attr_accessor :rails_bin_scheduler, :rails_log_scheduler

  # job_delay in seconds
  def perform( autostart: false,
               job_delay: ::Deepblue::SchedulerIntegrationService.scheduler_start_job_default_delay,
               restart: true,
               user_email: '',
               debug_verbose: scheduler_start_job_debug_verbose,
               **options )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "::Deepblue::SchedulerIntegrationService.scheduler_active=#{::Deepblue::SchedulerIntegrationService.scheduler_active}",
                                           "autostart=#{autostart}",
                                           "job_delay=#{job_delay}",
                                           "restart=#{restart}",
                                           "user_email=#{user_email}",
                                           "options=#{options}",
                                           "" ] if debug_verbose
    # return unless ::Deepblue::SchedulerIntegrationService.scheduler_active

    initialize_with( debug_verbose: debug_verbose )
    user_emails = []
    if user_email.present?
      user_emails = Array( user_email )
    end
    log( event: "scheduler start job" )
    @rails_bin_scheduler = Rails.application.root.join( 'bin', 'scheduler.sh' ).to_s
    @rails_log_scheduler = Rails.application.root.join( 'log', 'scheduler.sh.out' ).to_s
    delay_job job_delay
    restarted = false
    pid = scheduler_pid
    if restart
      `kill -15 #{pid}` if pid.present?
      sleep 1.second
      pid = scheduler_pid
      if pid.present?
        msg = "DBD scheduler failed to kill resque-scheduler on #{hostname}"
        scheduler_emails( autostart: autostart, to: user_emails, subject: msg, body: msg )
        return
      end
      restarted = pid.blank?
    elsif pid.present?
      msg = "DBD scheduler already running on #{hostname}"
      scheduler_emails( autostart: autostart, to: user_emails, subject: msg, body: msg )
      return
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rails_bin_scheduler=#{rails_bin_scheduler}",
                                           "rails_log_scheduler=#{rails_log_scheduler}",
                                           "" ] if debug_verbose
    spawn_pid = scheduler_spawn
    retry_count = 0
    while retry_count < 5 # TODO configure retry count
      retry_count += 1
      retry_sleep
      pid = scheduler_pid
      break if pid.present?
    end
    msg_lines = []
    msg_lines << "rails_bin_scheduler = #{rails_bin_scheduler}"
    msg_lines << "rails_log_scheduler = #{rails_log_scheduler}"
    msg_lines << ''
    msg_lines << "spawn_pid = #{spawn_pid}"
    msg_lines << ''
    msg_lines << "retry_count = #{retry_count}"
    subject = if pid.present?
                if restarted
                  "DBD scheduler restarted on #{hostname}"
                else
                  "DBD scheduler started on #{hostname}"
                end
              else
                "DBD scheduler failed to start on #{hostname}"
              end
    body = "#{subject}\n\n#{msg_lines.join("\n")}"
    scheduler_emails( autostart: autostart, to: user_emails, subject: subject, body: body )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: [ { autostart: autostart,
                                         job_delay: job_delay,
                                         restart: restart,
                                         user_email: user_email,
                                         debug_verbose: debug_verbose },
                                         options ] )
    email_failure( targets: user_emails, task_name: self.class.name, exception: e, event: self.class.name )
    raise e
  end

  def delay_job( job_delay )
    sleep job_delay if job_delay > 0
  end

  def hostname
    Rails.configuration.hostname
  end

  def retry_sleep
    sleep 5.seconds # TODO configure sleep time
  end

  def scheduler_email( autostart: false, email_target:, subject:, body: nil )
    subject = subject
    body = body
    body = subject if body.empty?
    email = email_target
    email_sent = ::Deepblue::EmailHelper.send_email( to: email, subject: subject, body: body )
    ::Deepblue::EmailHelper.log( class_name: self.class.name,
                                 current_user: nil,
                                 event: "SchedulerStartJobEmail",
                                 event_note: autostart ? 'autostart' : '',
                                 id: 'NA',
                                 to: email,
                                 subject: subject,
                                 body: body,
                                 email_sent: email_sent )
  end

  def scheduler_emails( autostart: false, to:, subject:, body: '' )
    emails = to | ::Deepblue::SchedulerIntegrationService.scheduler_started_email
    emails.each do |email_target|
      scheduler_email( autostart: autostart, email_target: email_target, subject: subject, body: body )
    end
  end

  def scheduler_pid
    `pgrep -fu #{Process.uid} resque-scheduler`
  end

  def scheduler_spawn
    spawn_pid = spawn( rails_bin_scheduler, :out => rails_log_scheduler, :err => rails_log_scheduler )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "spawn_pid=#{spawn_pid}",
                                           "" ] if debug_verbose
    Process.detach( spawn_pid )
    return spawn_pid
  end

end
