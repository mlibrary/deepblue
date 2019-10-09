# frozen_string_literal: true

class HeartbeatEmailJob < ::Hyrax::ApplicationJob
  queue_as :scheduler

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "" ]
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "heartbeat email" )
    hostname = ::DeepBlueDocs::Application.config.hostname
    ::DeepBlueDocs::Application.config.scheduler_heartbeat_email_targets.each do |email_target|
      heartbeat_email( email_target: email_target, hostname: hostname )
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def heartbeat_email( email_target:, hostname: )
    # subject = ::Deepblue::EmailHelper.t( "hyrax.email.deactivate_embargo.subject", title: title )
    subject = "DBD scheduler heartbeat from #{hostname}"
    body = subject
    email = email_target
    ::Deepblue::EmailHelper.log( class_name: self.class.name,
                                 current_user: nil,
                                 event: "Heartbeat email",
                                 event_note: '',
                                 id: 'NA',
                                 to: email,
                                 from: email,
                                 subject: subject,
                                 body: body )
    ::Deepblue::EmailHelper.send_email( to: email, from: email, subject: subject, body: body ) unless test_mode
  end

end
