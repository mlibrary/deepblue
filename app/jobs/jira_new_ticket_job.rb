# frozen_string_literal: true

class JiraNewTicketJob < ::Hyrax::ApplicationJob

  def perform( work_id:, current_user: nil, job_delay: 0 )
    Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "work_id=#{work_id}",
                                         "current_user=#{current_user}",
                                         "job_delay=#{job_delay}" ]
    if 0 < job_delay
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "work_id=#{work_id}",
                                           "current_user=#{current_user}",
                                           "sleeping #{job_delay} seconds"]
      sleep job_delay
    end
    work = ActiveFedora::Base.find( work_id )
    ::Deepblue::JiraHelper.jira_ticket_for_create( curation_concern: work )
    work = ActiveFedora::Base.find( work_id )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "work.curation_notes_admin=#{work.curation_notes_admin}",
                                           "" ]
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "JiraNewTicketJob.perform(#{work_id},#{job_delay}) #{e.class}: #{e.message} at #{e.backtrace[0]}"
    raise
  end

end
