# frozen_string_literal: true

module Deepblue

  module JobTaskHelper

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    @@job_task_helper_debug_verbose = false

    mattr_accessor  :job_task_helper_debug_verbose

    @@about_to_expire_embargoes_job_debug_verbose = false
    @@abstract_rake_task_job_debug_verbose = false
    @@characterize_job_debug_verbose = false
    @@deactivate_expired_embargoes_job_debug_verbose = false
    @@heartbeat_job_debug_verbose = false
    @@heartbeat_email_job_debug_verbose = false
    @@ingest_job_debug_verbose = false
    @@rake_task_job_debug_verbose = false
    @@works_report_job_debug_verbose = false

    mattr_accessor  :about_to_expire_embargoes_job_debug_verbose,
                    :abstract_rake_task_job_debug_verbose,
                    :characterize_job_debug_verbose,
                    :deactivate_expired_embargoes_job_debug_verbose,
                    :heartbeat_job_debug_verbose,
                    :heartbeat_email_job_debug_verbose,
                    :ingest_job_debug_verbose,
                    :rake_task_job_debug_verbose,
                    :works_report_job_debug_verbose


    @@allowed_job_tasks = [ "tmp:clean" ].freeze

    mattr_accessor  :allowed_job_tasks



    def self.initialize_options_from( *args )
      options = {}
      args.each { |key,value| options[key] = value }
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "timestamp_begin=#{timestamp_begin}",
                                             "options=#{options}",
                                             "" ] if job_task_helper_debug_verbose
    end

    def self.email_exec_results( targets:,
                                 exec_str:,
                                 rv:,
                                 event:,
                                 event_note: '',
                                 timestamp_begin: nil,
                                 timestamp_end: DateTime.now )

      return if targets.blank?
      # TODO: integrate timestamps
      body = "#{exec_str} returned:\n<pre>\n#{rv}\n</pre>\n";
      targets.each do |email|
        send_email( email_target: email,
                    content_type: 'text/html',
                    task_name: exec_str,
                    body: body,
                    event: event,
                    event_note: event_note,
                    timestamp_begin: timestamp_begin,
                    timestamp_end: timestamp_end )
      end
    end

    def self.email_failure( targets:,
                            task_name:,
                            exception:,
                            event:,
                            event_note: '',
                            timestamp_begin: nil,
                            timestamp_end: DateTime.now )

      return if targets.blank?
      # TODO: integrate timestamps
      error_body = "#{exception.class} #{exception.message}\n\n#{exception.backtrace[0..20].join("\n")}"
      body = "#{exec_str} returned:\n<pre>#{error_body}\n</pre>\n";
      targets.each do |email|
        send_email( email_target: email,
                    content_type: 'text/html',
                    task_name: task_name,
                    subject: "DBD #{task_name} from #{hostname} failed",
                    body: body,
                    event: event,
                    event_note: event_note,
                    timestamp_begin: timestamp_begin,
                    timestamp_end: timestamp_end )
      end
    end

    def self.send_email( email_target:,
                         content_type: nil,
                         hostname: nil,
                         task_name:,
                         subject: nil,
                         body: nil,
                         event:,
                         event_note: '',
                         id: 'NA',
                         timestamp_begin: nil,
                         timestamp_end: DateTime.now  )

      hostname = ::DeepBlueDocs::Application.config.hostname if hostname.nil?
      subject = "DBD #{task_name} from #{hostname}" if subject.blank?
      # TODO: integrate timestamps
      body = subject if body.blank?
      email = email_target
      email_sent = ::Deepblue::EmailHelper.send_email( to: email,
                                                       from: email,
                                                       subject: subject,
                                                       body: body,
                                                       content_type: content_type )
      ::Deepblue::EmailHelper.log( class_name: self.class.name,
                                   current_user: nil,
                                   event: event,
                                   event_note: event_note,
                                   id: id,
                                   to: email,
                                   from: email,
                                   subject: subject,
                                   body: body,
                                   email_sent: email_sent )
    end

  end

end
