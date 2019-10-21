# frozen_string_literal: true

class HeartbeatEmailJob < ::Hyrax::ApplicationJob
  include JobHelper
  queue_as :scheduler

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "" ]
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "heartbeat email" )
    options = {}
    args.each { |key,value| options[key] = value }
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           "options=#{options}",
                                           Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ]
    verbose = job_options_value(options, key: 'verbose', default_value: false )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    hostnames = job_options_value(options, key: 'hostnames', default_value: [], verbose: verbose )
    hostname = ::DeepBlueDocs::Application.config.hostname
    return unless hostnames.include? hostname
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
    ::Deepblue::EmailHelper.send_email( to: email, from: email, subject: subject, body: body )
  end

end
