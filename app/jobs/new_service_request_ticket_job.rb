# frozen_string_literal: true

class NewServiceRequestTicketJob < ::Deepblue::DeepblueJob

  mattr_accessor :new_service_request_ticket_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.new_service_request_ticket_job_debug_verbose

  def self.has_service_request?( curation_concern: )
    return false unless ::Deepblue::TeamdynamixService.active
    rv = ::Deepblue::TeamdynamixService.has_service_request? curation_concern: curation_concern
    return rv
  end

  def perform( work_id:, current_user: nil, job_delay: 0, debug_verbose: new_service_request_ticket_job_debug_verbose )
    debug_verbose = debug_verbose || new_service_request_ticket_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                     ::Deepblue::LoggingHelper.called_from,
                                     "work_id=#{work_id}",
                                     "current_user=#{current_user}",
                                     "job_delay=#{job_delay}",
                                     "::Deepblue::JiraHelper.active=#{::Deepblue::JiraHelper.active}",
                                     "::Deepblue::TeamdynamixService.active=#{::Deepblue::TeamdynamixService.active}",
                                     "" ] if debug_verbose
    initialize_with( id: work_id, debug_verbose: debug_verbose )
    msg_handler.debug_verbose = msg_handler.debug_verbose || debug_verbose
    log( event: "new service request ticket job" )
    if 0 < job_delay
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "work_id=#{work_id}",
                               "current_user=#{current_user}",
                               "sleeping #{job_delay} seconds",
                               "" ] if debug_verbose
      sleep job_delay
    end
    work = ::PersistHelper.find( work_id )
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "work.present?=#{work.present?}",
                             "" ] if debug_verbose
    if ::Deepblue::TicketHelper.start_new_ticket_job( curation_concern: work, msg_handler: msg_handler )
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "::Deepblue::JiraHelper.active=#{::Deepblue::JiraHelper.active}",
                               "" ] if debug_verbose
      if ::Deepblue::JiraHelper.active
        msg = 'Create jira ticket.'
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "msg=#{msg}",
                                 "" ] if msg_handler.debug_verbose
        msg_handler.msg_verbose msg
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "work_id=#{work_id}",
                                 "current_user=#{current_user}",
                                 "" ] if msg_handler.debug_verbose
        ::Deepblue::JiraHelper.jira_ticket_for_create( curation_concern: work, msg_queue: msg_handler.msg_queue )
        work = ::PersistHelper.find( work_id )
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                                 "work.curation_notes_admin=#{work.curation_notes_admin}",
                                 "" ] if msg_handler.debug_verbose
      end
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "::Deepblue::TeamdynamixService.active=#{::Deepblue::TeamdynamixService.active}",
                               "" ] if debug_verbose
      if ::Deepblue::TeamdynamixService.active
        msg = 'Create teamdynamix ticket.'
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "msg=#{msg}",
                                 "" ] if msg_handler.debug_verbose
        msg_handler.msg_verbose msg
        msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "work_id=#{work_id}",
                                 "current_user=#{current_user}",
                                 "" ] if msg_handler.debug_verbose
        tdx = ::Deepblue::TeamdynamixService.new( msg_handler: msg_handler )
        if tdx.has_service_request_ticket_for( curation_concern: work )
          msg = 'curation concern admin notes already contains teamdynamix ticket'
          msg_handler.bold_debug [ msg_handler.here,
                                   msg_handler.called_from,
                                   "msg=#{msg}",
                                   "" ] if msg_handler.debug_verbose
          msg_handler.msg msg
        else
          tdx.create_ticket_for( curation_concern: work )
          msg_handler.bold_debug [ msg_handler.here,
                                 msg_handler.called_from,
                                 "after tdx.create_ticket_for",
                                 "work_id=#{work_id}",
                                 "current_user=#{current_user}",
                                 "" ] if msg_handler.debug_verbose
        end
      end
    else
      msg = 'Skip new create ticket job.'
      msg_handler.bold_debug [ msg_handler.here,
                               msg_handler.called_from,
                               "msg=#{msg}",
                               "" ] if msg_handler.debug_verbose
      msg_handler.msg_verbose msg
    end
    job_finished
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "job_status.status=#{job_status.status}",
                             "job_status.message=#{job_status.message}",
                             "" ] if msg_handler.debug_verbose
    msg_handler.bold_debug [ msg_handler.here,
                             msg_handler.called_from,
                             "exiting.",
                             "" ] if msg_handler.debug_verbose
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e,
                         args: { work_id: work_id,
                                 current_user: current_user,
                                 job_delay: job_delay } )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise e
  end

end
