# frozen_string_literal: true

class JiraNewTicketJob < ::Deepblue::DeepblueJob

  # see JobHelper for :by_request_only, :email_targets, :hostname, :job_msg_queue, :timestamp_begin, :timestamp_end

  mattr_accessor :jira_new_ticket_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.jira_new_ticket_job_debug_verbose

  def perform( work_id:, current_user: nil, job_delay: 0, debug_verbose: jira_new_ticket_job_debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                         "work_id=#{work_id}",
                                         "current_user=#{current_user}",
                                         "job_delay=#{job_delay}" ] if debug_verbose
    initialize_with( debug_verbose: debug_verbose )
    log( event: "jira new ticket job" )
    job_msg_queue
    status = job_status
    status.main_cc_id = work_id
    status.save
    if 0 < job_delay
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work_id=#{work_id}",
                                           "current_user=#{current_user}",
                                           "sleeping #{job_delay} seconds"] if debug_verbose
      sleep job_delay
    end
    work = ::PersistHelper.find( work_id )
    ::Deepblue::JiraHelper.jira_ticket_for_create( curation_concern: work, msg_queue: job_msg_queue )
    work = ::PersistHelper.find( work_id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_msg_queue=#{job_msg_queue}",
                                           "work.curation_notes_admin=#{work.curation_notes_admin}",
                                           "" ] if debug_verbose
    job_finished
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_status.status=#{job_status.job_status}",
                                           "job_status.message=#{job_status.message}",
                                           "" ] if debug_verbose
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e,
                         msg: "JiraNewTicketJob.perform(#{work_id},#{job_delay}) #{e.class}: #{e.message} backtrace:\n" +
                           e.backtrace.join("\n" ) )
    raise
  end

end
