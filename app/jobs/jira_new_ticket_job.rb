# frozen_string_literal: true

class JiraNewTicketJob < ::Hyrax::ApplicationJob

  JIRA_NEW_TICKET_JOB_DEBUG_VERBOSE = false

  def perform( work_id:, current_user: nil, job_delay: 0 )
    Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "work_id=#{work_id}",
                                         "current_user=#{current_user}",
                                         "job_delay=#{job_delay}" ] if JIRA_NEW_TICKET_JOB_DEBUG_VERBOSE
    if 0 < job_delay
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "work_id=#{work_id}",
                                           "current_user=#{current_user}",
                                           "sleeping #{job_delay} seconds"] if JIRA_NEW_TICKET_JOB_DEBUG_VERBOSE
      sleep job_delay
    end
    work = ::PersistHelper.find( work_id )
    ::Deepblue::JiraHelper.jira_ticket_for_create( curation_concern: work )
    work = ::PersistHelper.find( work_id )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "work.curation_notes_admin=#{work.curation_notes_admin}",
                                           "" ] if JIRA_NEW_TICKET_JOB_DEBUG_VERBOSE
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "JiraNewTicketJob.perform(#{work_id},#{job_delay}) #{e.class}: #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error "JiraNewTicketJob.perform(#{work_id},#{job_delay}) #{e.class}: #{e.message} backtrace:\n" + e.backtrace.join("\n" )
    raise
  end

end
