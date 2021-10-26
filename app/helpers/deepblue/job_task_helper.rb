# frozen_string_literal: true

module Deepblue

  module JobTaskHelper

    mattr_accessor  :job_task_helper_debug_verbose, default: false

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    mattr_accessor :about_to_expire_embargoes_job_debug_verbose,    default: false
    mattr_accessor :abstract_rake_task_job_debug_verbose,           default: false
    mattr_accessor :deactivate_expired_embargoes_job_debug_verbose, default: false
    mattr_accessor :deepblue_job_debug_verbose,                     default: false
    mattr_accessor :export_documentation_job_debug_verbose,         default: false
    mattr_accessor :fedora_accessible_job_debug_verbose,            default: false
    mattr_accessor :globus_errors_report_job_debug_verbose,         default: false
    mattr_accessor :heartbeat_job_debug_verbose,                    default: false
    mattr_accessor :heartbeat_email_job_debug_verbose,              default: false
    mattr_accessor :monthly_analytics_report_job_debug_verbose,     default: false
    mattr_accessor :monthly_events_report_job_debug_verbose,        default: false
    mattr_accessor :rake_task_job_debug_verbose,                    default: false
    mattr_accessor :run_job_task_debug_verbose,                     default: false
    mattr_accessor :scheduler_start_job_debug_verbose,              default: false
    mattr_accessor :update_condensed_events_job_debug_verbose,      default: false
    mattr_accessor :user_stat_importer_job_debug_verbose,           default: false
    mattr_accessor :works_report_job_debug_verbose,                 default: false

    mattr_accessor :allowed_job_tasks,             default: [ "tmp:clean" ].freeze
    mattr_accessor :job_failure_email_subscribers, default: []

    def self.email_exec_results( targets:,
                                 subscription_service_id: nil,
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
      targets = ::Deepblue::EmailSubscriptionService.merge_targets_and_subscribers( targets: targets,
                                                                                    subscription_service_id: subscription_service_id )
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

    def self.email_merge_targets( subscription_service_id:, targets: )
      return targets unless subscription_service_id.present?
      ::Deepblue::EmailSubscriptionService.merge_targets_and_subscribers( targets: targets,
                                                                  subscription_service_id: subscription_service_id )
    end

    def self.email_failure( targets:,
                            subscription_service_id: nil,
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
      targets = email_merge_targets( subscription_service_id: subscription_service_id, targets: targets )
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
                            subscription_service_id: nil,
                            task_name:,
                            event:,
                            event_note: '',
                            messages: [],
                            timestamp_begin: nil,
                            timestamp_end: DateTime.now )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "targets=#{targets}",
                                             "subscription_service_id=#{subscription_service_id}",
                                             "task_name=#{task_name}",
                                             "event=#{event}",
                                             "event_note=#{event_note}",
                                             "messages=#{messages}",
                                             "timestamp_begin=#{timestamp_begin}",
                                             "timestamp_end=#{timestamp_end}",
                                             "" ] if job_task_helper_debug_verbose
      targets = email_merge_targets( subscription_service_id: subscription_service_id, targets: targets )
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

    def self.has_email_targets( job:, options: job.options, debug_verbose: false )
      subscription_service_id = job.job_options_value( options,
                                                       key: 'subscription_service_id',
                                                       default_value: nil,
                                                       verbose: job.verbose || debug_verbose )
      job.subscription_service_id = subscription_service_id if job.respond_to? :subscription_service_id=
      return if subscription_service_id.blank?
      targets = job.email_targets
      targets = ::Deepblue::EmailSubscriptionService.merge_targets_and_subscribers( targets: targets,
                                                                subscription_service_id: subscription_service_id )
      job.email_targets = targets
    end

    def self.has_options( *args, job:, debug_verbose: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if debug_verbose || job_task_helper_debug_verbose
      job.options = initialize_options_from( *args, debug_verbose: debug_verbose )
    end

    def self.hostname
      ::DeepBlueDocs::Application.config.hostname
    end

    def self.hostname_allowed( job:, options: job.options, debug_verbose: false )
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                       "options=#{options}",
      #                                        "" ] if debug_verbose || job_task_helper_debug_verbose
      job.hostnames = job.job_options_value( options,
                                             key: 'hostnames',
                                             default_value: [],
                                             verbose: job.verbose || debug_verbose )
      job.hostname = self.hostname
      job.hostnames.include? job.hostname
    end

    def self.initialize_options_from( *args, debug_verbose: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "args=#{args}",
                                             "" ] if debug_verbose || job_task_helper_debug_verbose
      options = {}
      return options unless args.present?
      args = args[0] while ( args.is_a?( Array ) && 1 == args.length )
      args.each do |key,value|
        options[key.to_s] = value
      end
      options = options.with_indifferent_access
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "options=#{options}",
                                             "" ] if debug_verbose || job_task_helper_debug_verbose
      return options
    end

    def self.is_quiet( job:, options: job.options, debug_verbose: false )
      job.quiet = job.job_options_value( options, key: 'quiet', default_value: false, verbose: debug_verbose )
      if job.quiet
        job.verbose = false
      else
        job.verbose = job.job_options_value( options, key: 'verbose', default_value: false )
        ::Deepblue::LoggingHelper.debug "verbose=#{job.verbose}" if job.verbose
      end
    end

    def self.is_verbose( job:, options: job.options, default_value: false, debug_verbose: false )
      job.verbose = job.job_options_value( options, key: 'verbose', default_value: default_value, verbose: debug_verbose )
      ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if job.verbose || debug_verbose
    end

    def self.job_task_puts( str = '', msg_queue = nil )
      if msg_queue
        msg_queue << str
      else
        puts str
      end
    end

    def self.options_from_args( *args )
      options = {}
      args.each { |key,value| options[key.to_s] = value }
      options
    end

    def self.options_parse( options_str )
      return options_str if options_str.is_a? Hash
      return {} if options_str.blank?
      ActiveSupport::JSON.decode options_str
    rescue ActiveSupport::JSON.parse_error => e
      return { 'error': e, 'options_str': options_str }
    end

    def self.options_value( options, key:, default_value: nil, verbose: false, msg_queue: nil )
      return default_value if options.blank?
      return default_value unless options.key? key
      job_task_puts "set key #{key} to #{options[key]}", msg_queue if verbose
      return options[key]
    end

    def self.send_email( email_target:,
                         from: ::Deepblue::EmailHelper.notification_email_from,
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
      email_sent = ::Deepblue::EmailHelper.send_email( to: email_target,
                                                       from: from,
                                                       subject: subject,
                                                       body: body,
                                                       content_type: content_type )
      ::Deepblue::EmailHelper.log( class_name: self.class.name,
                                   current_user: nil,
                                   event: event,
                                   event_note: event_note,
                                   id: id,
                                   to: email_target,
                                   from: from,
                                   subject: subject,
                                   body: body,
                                   email_sent: email_sent )
    end

  end

end
