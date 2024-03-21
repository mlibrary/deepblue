# frozen_string_literal: true

module Deepblue

  module JobTaskHelper

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :job_task_helper_debug_verbose,                  default: false

    mattr_accessor :about_to_expire_embargoes_job_debug_verbose,    default: false
    mattr_accessor :abstract_rake_task_job_debug_verbose,           default: false
    mattr_accessor :clean_blacklight_query_cache_job_debug_verbose, default: false
    mattr_accessor :deactivate_expired_embargoes_job_debug_verbose, default: false
    mattr_accessor :deepblue_job_debug_verbose,                     default: false
    mattr_accessor :doi_pending_report_job_debug_verbose,           default: false
    mattr_accessor :ensure_doi_minted_job_debug_verbose,            default: false
    mattr_accessor :export_documentation_job_debug_verbose,         default: false
    mattr_accessor :export_log_files_job_debug_verbose,             default: false
    mattr_accessor :fedora_accessible_job_debug_verbose,            default: false
    mattr_accessor :fedora_check_and_update_index_job_debug_verbose, default: false
    mattr_accessor :globus_errors_report_job_debug_verbose,         default: false
    mattr_accessor :globus_status_report_job_debug_verbose,         default: false
    mattr_accessor :heartbeat_job_debug_verbose,                    default: false
    mattr_accessor :heartbeat_email_job_debug_verbose,              default: false
    mattr_accessor :jira_new_ticket_job_debug_verbose,              default: false
    mattr_accessor :job_helper_debug_verbose,                       default: false
    mattr_accessor :monthly_analytics_report_job_debug_verbose,     default: false
    mattr_accessor :monthly_events_report_job_debug_verbose,        default: false
    mattr_accessor :new_service_request_ticket_job_debug_verbose,   default: false
    mattr_accessor :rake_task_job_debug_verbose,                    default: false
    mattr_accessor :reset_condensed_events_job_debug_verbose,       default: false
    mattr_accessor :resolrize_job_debug_verbose,                    default: false   
    mattr_accessor :run_job_task_debug_verbose,                     default: false
    mattr_accessor :scheduler_start_job_debug_verbose,              default: false
    mattr_accessor :update_condensed_events_job_debug_verbose,      default: false
    mattr_accessor :user_stat_importer_job_debug_verbose,           default: false
    mattr_accessor :work_find_and_fix_job_debug_verbose,            default: false
    mattr_accessor :work_impact_report_job_debug_verbose,           default: false
    mattr_accessor :works_report_job_debug_verbose,                 default: false

    mattr_accessor :allowed_job_tasks,             default: [ "tmp:clean" ].freeze
    mattr_accessor :allowed_job_task_matching,     default: [].freeze
    mattr_accessor :job_failure_email_subscribers, default: []

    def self.email_exec_results( targets:,
                                 subscription_service_id: nil,
                                 exec_str:,
                                 rv:,
                                 event:,
                                 event_note: '',
                                 messages: [],
                                 timestamp_begin: nil,
                                 timestamp_end: DateTime.now,
                                 msg_handler: nil,
                                 debug_verbose: job_task_helper_debug_verbose )

      debug_verbose = debug_verbose ||
        job_task_helper_debug_verbose ||
        (msg_handler.nil? ? false : msg_handler.debug_verbose)
      to_console = (msg_handler.nil? ? false : msg_handler.to_console)
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
                                             "" ], bold_puts: to_console if debug_verbose
      targets = ::Deepblue::EmailSubscriptionService.merge_targets_and_subscribers( targets: targets,
                                                                                    subscription_service_id: subscription_service_id )
      targets.delete_if { |x| x.blank? }
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
                                             "" ], bold_puts: to_console if debug_verbose
      targets = targets.uniq
      targets.each do |email|
        send_email( email_target: email,
                    content_type: ::Deepblue::EmailHelper::TEXT_HTML,
                    task_name: exec_str,
                    subject: subject,
                    body: body,
                    event: event,
                    event_note: event_note,
                    msg_handler: msg_handler,
                    timestamp_begin: timestamp_begin,
                    timestamp_end: timestamp_end )
      end
    end

    def self.email_merge_targets( subscription_service_id:, targets: )
      return targets unless subscription_service_id.present?
      ::Deepblue::EmailSubscriptionService.merge_targets_and_subscribers( targets: targets,
                                                                  subscription_service_id: subscription_service_id )
    end

    def self.email_lines_to_html( lines:, tag: nil, join: nil )
      return "<br/>" if lines.blank?
      html_lines = []
      lines.each do |line|
        if tag.present?
          html_lines << "<#{tag}>#{line.chomp}<#{tag}><br/>"
        else
          html_lines << "#{line.chomp}<br/>"
        end
      end
      return html_lines if join.blank?
      return html_lines.join( join )
    end

    def self.email_task_args_to_html( task_args: )
      return "<br/>" if task_args.blank?
      return "#{task_args.pretty_inspect}<br/>"
    end

    def self.email_failure( targets:,
                            subscription_service_id: nil,
                            task_name:,
                            task_args: nil,
                            exception:,
                            event:,
                            event_note: '',
                            messages: [],
                            timestamp_begin: nil,
                            timestamp_end: DateTime.now,
                            msg_handler: nil,
                            debug_verbose: job_task_helper_debug_verbose )

      debug_verbose = debug_verbose ||
        job_task_helper_debug_verbose ||
        (msg_handler.nil? ? false : msg_handler.debug_verbose)
      to_console = (msg_handler.nil? ? false : msg_handler.to_console)
      messages = msg_handler.msg_queue if messages.blank? && msg_handler.present?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "targets=#{targets}",
                                             "task_name=#{task_name}",
                                             "task_args=#{task_args}",
                                             "exception=#{exception}",
                                             "event=#{event}",
                                             "event_note=#{event_note}",
                                             "messages=#{messages}",
                                             "timestamp_begin=#{timestamp_begin}",
                                             "timestamp_end=#{timestamp_end}",
                                             "" ], bold_puts: to_console if debug_verbose
      targets = email_merge_targets( subscription_service_id: subscription_service_id, targets: targets )
      targets.delete_if { |x| x.blank? }
      return if targets.blank?
      timestamp_end = DateTime.now if timestamp_end.blank?
      backtrace = exception&.backtrace
      if backtrace.is_a? Array
        backtrace = backtrace[0..30] if bactrace.size > 30
      else
        backtrace = []
      end
      body =<<-END_BODY
#{task_name} on #{hostname} failed.<br/>
#{timestamp_begin.blank? ? "" : "Began: #{timestamp_begin}<br/>"}
#{timestamp_end.blank? ? "" : "Ended: #{timestamp_end}<br/>"}
Task args:<br/>
#{email_task_args_to_html( task_args: task_args)}
<br/>
Exception raised:<br/>
<code>#{exception.class} #{exception.message}<code><br/>
<br/>
#{email_lines_to_html( lines: backtrace, tag: 'code', join: "\n" )}
<br/>
#{email_lines_to_html( lines: messages, tag: 'code', join: "\n" )}
END_BODY
      subject = "DBD #{task_name} from #{hostname} failed"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "subject=#{subject}",
                                             "body=#{body}",
                                             "" ], bold_puts: to_console if debug_verbose
      targets = targets.uniq
      targets.each do |email|
        send_email( email_target: email,
                    content_type: ::Deepblue::EmailHelper::TEXT_HTML,
                    task_name: task_name,
                    subject: subject,
                    body: body,
                    event: event,
                    event_note: event_note,
                    msg_handler: msg_handler,
                    timestamp_begin: timestamp_begin,
                    timestamp_end: timestamp_end )
      end
    end

    def self.email_failure_targets( from_dashboard: [],
                                    msg_handler: nil,
                                    targets: [],
                                    debug_verbose: job_task_helper_debug_verbose )

      debug_verbose = debug_verbose ||
                    job_task_helper_debug_verbose ||
                    (msg_handler.nil? ? false : msg_handler.debug_verbose)
      to_console = (msg_handler.nil? ? false : msg_handler.to_console)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "targets=#{targets}",
                                             "from_dashboard=#{from_dashboard}",
                                             "job_failure_email_subscribers=#{job_failure_email_subscribers}",
                                             "" ], bold_puts: to_console if debug_verbose
      targets = Array(targets)
      from_dashboard = Array(from_dashboard)
      rv = job_failure_email_subscribers | targets | from_dashboard
      rv.delete_if { |x| x.blank? }
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ], bold_puts: to_console if debug_verbose
      return rv
    end

    def self.email_results( targets:,
                            subscription_service_id: nil,
                            task_name:,
                            event:,
                            event_note: '',
                            messages: [], # TODO: msg_handler should superceded messages
                            timestamp_begin: nil,
                            timestamp_end: DateTime.now,
                            msg_handler: nil,
                            debug_verbose: job_task_helper_debug_verbose )

      debug_verbose = debug_verbose ||
        job_task_helper_debug_verbose ||
        (msg_handler.nil? ? false : msg_handler.debug_verbose)
      to_console = (msg_handler.nil? ? false : msg_handler.to_console)
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
                                             "" ], bold_puts: to_console if debug_verbose
      targets = email_merge_targets( subscription_service_id: subscription_service_id, targets: targets )
      targets.delete_if { |x| x.blank? }
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
                                             "" ], bold_puts: to_console if debug_verbose
      targets = targets.uniq
      targets.each do |email|
        send_email( email_target: email,
                    content_type: ::Deepblue::EmailHelper::TEXT_HTML,
                    task_name: task_name,
                    subject: subject,
                    body: body,
                    event: event,
                    event_note: event_note,
                    msg_handler: msg_handler,
                    timestamp_begin: timestamp_begin,
                    timestamp_end: timestamp_end )
      end
    end

    # def self.has_email_targets( job:,
    #                             options: job.options,
    #                             msg_handler: nil,
    #                             debug_verbose: job_task_helper_debug_verbose )
    #
    #   debug_verbose = debug_verbose && job_task_helper_debug_verbose
    #   subscription_service_id = job.job_options_value( options,
    #                                                    key: 'subscription_service_id',
    #                                                    default_value: nil )
    #   job.subscription_service_id = subscription_service_id if job.respond_to? :subscription_service_id=
    #   return if subscription_service_id.blank?
    #   targets = job.email_targets
    #   targets = ::Deepblue::EmailSubscriptionService.merge_targets_and_subscribers( targets: targets,
    #                                                             subscription_service_id: subscription_service_id )
    #   job.email_targets = targets
    # end

    # def self.has_options( *args, job:, msg_handler: nil, debug_verbose: job_task_helper_debug_verbose )
    #   debug_verbose = debug_verbose && job_task_helper_debug_verbose
    #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                          ::Deepblue::LoggingHelper.called_from,
    #                                          "" ] if debug_verbose
    #   job.options = initialize_options_from( *args, debug_verbose: debug_verbose )
    # end

    def self.hostname
      Rails.configuration.hostname
    end

    # def self.hostname_allowed( job:,
    #                            msg_handler: nil,
    #                            options:,
    #                            debug_verbose: job_task_helper_debug_verbose,
    #                            task: false,
    #                            verbose: false )
    #
    #   debug_verbose = debug_verbose && job_task_helper_debug_verbose
    #   # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
    #   #                                        ::Deepblue::LoggingHelper.called_from,
    #   #                                       "options=#{options}",
    #   #                                        "" ] if debug_verbose
    #   return true unless job.job_options_key?( options, key: 'hostnames' )
    #   # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
    #   #                                        ::Deepblue::LoggingHelper.called_from,
    #   #                                       "options=#{options}",
    #   #                                        "" ] if debug_verbose
    #   job.hostnames = job.job_options_value( key: 'hostnames', default_value: [] )
    #   job.hostname = self.hostname
    #   # puts "hostname=#{self.hostname}"
    #   job.hostnames.include? job.hostname
    # end

    def self.initialize_options_from( *args, debug_verbose: job_task_helper_debug_verbose )
      debug_verbose = debug_verbose && job_task_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "args=#{args}",
                                             "" ] if debug_verbose
      options = {}
      unless args.present?
        options = options.with_indifferent_access
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "options=#{options}",
                                               "" ] if debug_verbose
        return options.with_indifferent_access
      end
      args = normalize_args( *args, debug_verbose: debug_verbose )
      args.each do |key,value|
        options[key.to_s] = value
      end
      options = options.with_indifferent_access
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "options=#{options}",
                                             "" ] if debug_verbose
      return options
    end

    def self.normalize_args( *args, debug_verbose: job_task_helper_debug_verbose )
      debug_verbose = debug_verbose && job_task_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "args=#{args}",
                                             "" ] if debug_verbose
      return args if args.is_a? Hash
      return args if args.is_a? ActiveSupport::HashWithIndifferentAccess
      # Don't want to strip outermost array unless the its of the form [[[x,y]]], so it doesn't strip if [[x,y]]
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "args=#{args}",
                                             "args.is_a?( Array )=#{args.is_a?( Array )}",
                                             "args.length=#{args.length}",
                                             "" ] if debug_verbose
      if ( args.is_a?( Array ) && 1 == args.length  )
        arg0 = args[0]
        if ( arg0.is_a?( Array ) && ( arg0[0].is_a?( String ) || arg0[0].is_a?( Symbol ) ) )
          # skip
        else
          args = args[0]
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "args=#{args}",
                                             "" ] if debug_verbose
      return args
    end

    def self.normalize_args2( *args, debug_verbose: job_task_helper_debug_verbose )
      debug_verbose ||= job_task_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "args=#{args}",
                                             "" ], bold_puts: true if debug_verbose
      return args if args.is_a? Hash
      # Don't want to strip outermost array unless the its of the form [[[x,y]]], so it doesn't strip if [[x,y]]
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "args=#{args}",
                                             "args.is_a?( Array )=#{args.is_a?( Array )}",
                                             "args.length=#{args.length}",
                                             "args[0]=#{args[0]}",
                                             "args[0].is_a?( Array )=#{args[0].is_a?( Array )}",
                                             "args[0].length=#{args[0].length}",
                                             "" ], bold_puts: true if debug_verbose
      while ( args.is_a?( Array ) && 1 == args.length && args[0].is_a?( Array ) && 1 == args[0].length ) do
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "args=#{args}",
                                               "args.is_a?( Array )=#{args.is_a?( Array )}",
                                               "args[0]=#{args[0]}",
                                               "args.length=#{args.length}",
                                               "args[0].is_a?( Array )=#{args[0].is_a?( Array )}",
                                               "args[0].length=#{args[0].length}",
                                               "" ], bold_puts: true if debug_verbose
        args = args[0]
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "args=#{args}",
                                             "" ], bold_puts: true if debug_verbose
      return args
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

    def self.options_value( options, key:, default_value: nil, verbose: false, msg_handler: nil )
      return default_value if options.blank?
      return default_value unless options.key? key
      msg_handler.msg_verbose "set key #{key} to #{options[key]}" if verbose
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
                         msg_handler: nil,
                         timestamp_begin: nil,
                         timestamp_end: DateTime.now  )

      hostname = Rails.configuration.hostname if hostname.nil?
      subject = MsgHelper.t( 'hyrax.email.subject.default', task_name: task_name, hostname: hostname ) if subject.blank?
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
                                   content_type: content_type,
                                   email_sent: email_sent )
    end

    def self.resque_worker_payload(job)
      HashHelper.get( job, 'payload', {} )
    end

    def self.resque_worker_args(job)
      args = HashHelper.get( HashHelper.get(job,'payload',{}), 'args', [] )
      return [] if args.size < 1
      return args[0]
    end

    def self.resque_worker_arguments(job)
      HashHelper.get( resque_worker_args(job), 'arguments', [] )
    end

    def self.resque_worker_argument(job,index,default=nil)
      arguments = resque_worker_arguments(job)
      return default unless index < arguments.size
      return arguments[index]
    end

    def self.resque_worker_argument?(job,index,value)
      resque_worker_argument(job,index) == value
    end

    def self.resque_worker_job_class(job)
      HashHelper.get( resque_worker_args(job), 'job_class', '' )
    end

    def self.resque_worker_job_class?(job,job_class)
      resque_worker_job_class(job) == job_class
    end

    def self.resque_worker_job_for_id?( job, id )
      queue = job['queue']
      case queue
      when 'globus_copy'
        return false unless resque_worker_job_class?(job,'GlobusCopyJob')
        return resque_worker_argument?(job,0,id)
      else
        false
      end
    end

    # def self.to_console_init( job:, options: job.options, debug_verbose: job_task_helper_debug_verbose )
    #   debug_verbose = debug_verbose || job_task_helper_debug_verbose
    #   rv = job.job_options_value( options, key: 'to_console', default_value: false, verbose: false )
    #   ::Deepblue::LoggingHelper.debug "to_console=#{rv}" if debug_verbose
    #   return rv
    # end

  end

end
