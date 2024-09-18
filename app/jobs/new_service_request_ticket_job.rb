# frozen_string_literal: true

class NewServiceRequestTicketJob < ::Deepblue::DeepblueJob

  mattr_accessor :debug_email_fritx, default: false

  mattr_accessor :new_service_request_ticket_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.new_service_request_ticket_job_debug_verbose

  def self.has_service_request?( curation_concern: )
    return false unless ::Deepblue::TeamdynamixService.active
    rv = ::Deepblue::TeamdynamixService.has_service_request? curation_concern: curation_concern
    return rv
  rescue Exception => e
    email_failure( targets: [ "fritx@umich.edu" ], task_name: "NewServiceRequestTicketJob.has_service_request?", exception: e, event: self.class.name )
  end

  def email_body( subject:, msg_handler: )
    ::Deepblue::EmailHelper.build_email_body( subject: subject, msg_handler: msg_handler )
  end

  def ensure_msg_queue( msg_handler:, debug_verbose: )
    return unless debug_email_fritx
    ::Deepblue::MessageHandler.ensure_msg_queue( msg_handler: msg_handler, debug_verbose: debug_verbose )
  end

  def send_fritx_email( class_name:, id:, msg_handler:, messages: [] )
    return unless debug_email_fritx
    msg_handler.msg "send_fritx_email( #{class_name}, #{id} )" if msg_handler
    ::Deepblue::EmailHelper.send_email_fritx( subject: "DBD #{class_name} on #{::Deepblue::JobTaskHelper.hostname}",
                                              msg_handler: msg_handler,
                                              messages: messages )
  rescue Exception => e
    email_failure( targets: [ "fritx@umich.edu" ], task_name: self.class.name, exception: e, event: self.class.name )
  end

  def perform( work_id:, current_user: nil, job_delay: 0, debug_verbose: new_service_request_ticket_job_debug_verbose )
    debug_verbose = debug_verbose || new_service_request_ticket_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                     "work_id=#{work_id}",
                                     "current_user=#{current_user}",
                                     "job_delay=#{job_delay}",
                                     "::Deepblue::JiraHelper.active=#{::Deepblue::JiraHelper.active}",
                                     "::Deepblue::TeamdynamixService.active=#{::Deepblue::TeamdynamixService.active}",
                                     "" ] if debug_verbose
    initialize_with( id: work_id, debug_verbose: debug_verbose )
    msg_handler.debug_verbose = msg_handler.debug_verbose || debug_verbose
    ensure_msg_queue( msg_handler: msg_handler, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ msg_handler.here, msg_handler.called_from,
                                           "work_id=#{work_id}",
                                           "current_user=#{current_user}",
                                           "job_delay=#{job_delay}",
                                           "::Deepblue::JiraHelper.active=#{::Deepblue::JiraHelper.active}",
                                           "::Deepblue::TeamdynamixService.active=#{::Deepblue::TeamdynamixService.active}",
                                           "" ] if msg_handler.debug_verbose
    log( event: "new service request ticket job" )
    send_fritx_email( class_name: self.class.name,
                      id: work_id,
                      msg_handler: msg_handler,
                      messages: [ msg_handler.here, msg_handler.called_from,
                                  "work_id=#{work_id}",
                                  "current_user=#{current_user}",
                                  "job_delay=#{job_delay}",
                                  "::Deepblue::JiraHelper.active=#{::Deepblue::JiraHelper.active}",
                                  "::Deepblue::TeamdynamixService.active=#{::Deepblue::TeamdynamixService.active}",
                                  "" ] ) if debug_email_fritx && msg_handler.debug_verbose
    if 0 < job_delay
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "work_id=#{work_id}",
                               "current_user=#{current_user}",
                               "sleeping #{job_delay} seconds",
                               "" ] if msg_handler.debug_verbose
      sleep job_delay
    end
    work = ::PersistHelper.find( work_id )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "work.present?=#{work.present?}",
                             "" ] if msg_handler.debug_verbose
    if ::Deepblue::TicketHelper.start_new_ticket_job( curation_concern: work, msg_handler: msg_handler )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "::Deepblue::JiraHelper.active=#{::Deepblue::JiraHelper.active}",
                               "" ] if msg_handler.debug_verbose
      if ::Deepblue::JiraHelper.active
        msg = 'Create jira ticket.'
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "msg=#{msg}",
                                 "" ] if msg_handler.debug_verbose
        msg_handler.msg_verbose msg
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "work_id=#{work_id}",
                                 "current_user=#{current_user}",
                                 "" ] if msg_handler.debug_verbose
        ::Deepblue::JiraHelper.jira_ticket_for_create( curation_concern: work, msg_queue: msg_handler.msg_queue )
        work = ::PersistHelper.find( work_id )
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                                 "work.curation_notes_admin=#{work.curation_notes_admin}",
                                 "" ] if msg_handler.debug_verbose
      end
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "::Deepblue::TeamdynamixService.active=#{::Deepblue::TeamdynamixService.active}",
                               "" ] if msg_handler.debug_verbose
      if ::Deepblue::TeamdynamixService.active
        msg = 'Create teamdynamix ticket.'
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "msg=#{msg}",
                                 "" ] if msg_handler.debug_verbose
        msg_handler.msg_verbose msg
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "work_id=#{work_id}",
                                 "current_user=#{current_user}",
                                 "" ] if msg_handler.debug_verbose
        tdx = ::Deepblue::TeamdynamixService.new( msg_handler: msg_handler )
        if tdx.has_service_request_ticket_for( curation_concern: work )
          msg = 'curation concern admin notes already contains teamdynamix ticket'
          msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                   "msg=#{msg}",
                                   "" ] if msg_handler.debug_verbose
          msg_handler.msg msg
        else
          tdx.create_ticket_for( curation_concern: work )
          msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "after tdx.create_ticket_for",
                                 "work_id=#{work_id}",
                                 "current_user=#{current_user}",
                                 "" ] if msg_handler.debug_verbose
        end
      end
    else
      msg = 'Skip new create ticket job.'
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "msg=#{msg}",
                               "" ] if msg_handler.debug_verbose
      msg_handler.msg_verbose msg
    end
    # ::Deepblue::JobTaskHelper.email_results( targets: [ "fritx@umich.edu" ],
    #                                          task_name: task_name,
    #                                          event: event_name,
    #                                          event_note: '',
    #                                          messages: msg_handler.msg_queue,
    #                                          # timestamp_begin: timestamp_begin,
    #                                          # timestamp_end: timestamp_end,
    #                                          msg_handler: msg_handler,
    #                                          debug_verbose: msg_handler.debug_verbose ) if msg_handler.debug_verbose
    job_finished
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "job_status.status=#{job_status.status}",
                             "job_status.message=#{job_status.message}",
                             "" ] if msg_handler.debug_verbose
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "exiting.",
                             "" ] if msg_handler.debug_verbose
    send_fritx_email( class_name: self.class.name, id: work_id, msg_handler: msg_handler ) if msg_handler.debug_verbose
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e,
                         args: { work_id: work_id,
                                 current_user: current_user,
                                 job_delay: job_delay } )
    email_failure( targets: [ "fritx@umich.edu" ], task_name: self.class.name, exception: e, event: self.class.name )
    raise e
  end

end
