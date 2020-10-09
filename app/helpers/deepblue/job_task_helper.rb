# frozen_string_literal: true

module Deepblue

  module JobTaskHelper

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    @@job_task_helper_debug_verbose = false
    @@run_job_task_debug_verbose = false

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

    mattr_accessor  :run_job_task_debug_verbose,
                    :about_to_expire_embargoes_job_debug_verbose,
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
                                 messages: [],
                                 timestamp_begin: nil,
                                 timestamp_end: DateTime.now )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "targets=#{targets}",
                                             "exec_str=#{exec_str}",
                                             "rv=#{rv}",
                                             "event=#{event}",
                                             "event_note=#{event_note}",
                                             "messages=#{messages}",
                                             "timestamp_begin=#{timestamp_begin}",
                                             "timestamp_end=#{timestamp_end}",
                                             "" ] if job_task_helper_debug_verbose
      return if targets.blank?
      timestamp_end = DateTime.now if timestamp_end.blank?
      body =<<-END_BODY
#{timestamp_begin.blank? ? "" : "Began: #{timestamp_begin}<br/>"}
#{timestamp_end.blank? ? "" : "Ended: #{timestamp_end}<br/>"}
#{messages.empty? ? "" : "Messages:<br/>\n<pre>\n#{messages.join("\n")}\n</pre><br/>"}
<br/>
#{exec_str} returned:<br/>
<pre>
#{rv}
</pre>
END_BODY
      subject = "DBD rake #{exec_str} from #{hostname} failed"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "subject=#{subject}",
                                             "body=#{body}",
                                             "" ] if job_task_helper_debug_verbose
      targets.each do |email|
        send_email( email_target: email,
                    content_type: 'text/html',
                    task_name: exec_str,
                    subject: subject,
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
                            messages: [],
                            timestamp_begin: nil,
                            timestamp_end: DateTime.now )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "targets=#{targets}",
                                             "task_name=#{task_name}",
                                             "exception=#{exception}",
                                             "event=#{event}",
                                             "event_note=#{event_note}",
                                             "messages=#{messages}",
                                             "timestamp_begin=#{timestamp_begin}",
                                             "timestamp_end=#{timestamp_end}",
                                             "" ] if job_task_helper_debug_verbose
      return if targets.blank?
      timestamp_end = DateTime.now if timestamp_end.blank?
      body =<<-END_BODY
#{task_name} on #{hostname} failed.<br/>
#{timestamp_begin.blank? ? "" : "Began: #{timestamp_begin}<br/>"}
#{timestamp_end.blank? ? "" : "Ended: #{timestamp_end}<br/>"}
<br/>
Exception raised:<br/>
<pre>
#{exception.class} #{exception.message}

#{exception.backtrace[0..20].join("\n")}
</pre>
<br/>
#{messages.empty? ? "" : "Messages:<br/>\n<pre>\n#{messages.join("\n")}\n</pre><br/>"}
END_BODY
      subject = "DBD #{task_name} from #{hostname} failed"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "subject=#{subject}",
                                             "body=#{body}",
                                             "" ] if job_task_helper_debug_verbose
      targets.each do |email|
        send_email( email_target: email,
                    content_type: 'text/html',
                    task_name: task_name,
                    subject: subject,
                    body: body,
                    event: event,
                    event_note: event_note,
                    timestamp_begin: timestamp_begin,
                    timestamp_end: timestamp_end )
      end
    end

    def self.email_results( targets:,
                            task_name:,
                            event:,
                            event_note: '',
                            messages: [],
                            timestamp_begin: nil,
                            timestamp_end: DateTime.now )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "targets=#{targets}",
                                             "task_name=#{task_name}",
                                             "event=#{event}",
                                             "event_note=#{event_note}",
                                             "messages=#{messages}",
                                             "timestamp_begin=#{timestamp_begin}",
                                             "timestamp_end=#{timestamp_end}",
                                             "" ] if job_task_helper_debug_verbose
      return if targets.blank?
      timestamp_end = DateTime.now if timestamp_end.blank?
      body =<<-END_BODY
#{task_name} on #{hostname} ran successfully.<br/>
#{timestamp_begin.blank? ? "" : "Began: #{timestamp_begin}<br/>"}
#{timestamp_end.blank? ? "" : "Ended: #{timestamp_end}<br/>"}
<br/>
#{messages.empty? ? "" : "Messages:<br/>\n<pre>\n#{messages.join("\n")}\n</pre><br/>"}
      END_BODY
      subject = "DBD #{task_name} on #{hostname} was successful"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "subject=#{subject}",
                                             "body=#{body}",
                                             "" ] if job_task_helper_debug_verbose
      targets.each do |email|
        send_email( email_target: email,
                    content_type: 'text/html',
                    task_name: task_name,
                    subject: subject,
                    body: body,
                    event: event,
                    event_note: event_note,
                    timestamp_begin: timestamp_begin,
                    timestamp_end: timestamp_end )
      end
    end

    def self.hostname
      ::DeepBlueDocs::Application.config.hostname
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
