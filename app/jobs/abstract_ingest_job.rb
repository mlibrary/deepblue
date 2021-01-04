# frozen_string_literal: true

class AbstractIngestJob < ::Hyrax::ApplicationJob

  ABSTRACT_INGEST_JOB_DEBUG_VERBOSE = ::Deepblue::IngestIntegrationService.abstract_ingest_job_debug_verbose

  mattr_accessor :abstract_ingest_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.abstract_ingest_job_debug_verbose

  attr_accessor :job_status

  def user_id_from( current_user )
    return nil if current_user.blank?
    return current_user.id if current_user.respond_to? :id
    email = current_user
    email = current_user.user_key if current_user.respond_to? :user_key
    user = User.find_by_user_key email
    return nil if user.blank?
    user.id
  end

  def find_or_create_job_status_started( parent_job_id: nil,
                                         continue_job_chain_later: false,
                                         verbose: abstract_ingest_job_debug_verbose,
                                         main_cc_id: nil,
                                         user_id: nil  )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "parent_job_id=#{parent_job_id}",
                                           "continue_job_chain_later=#{continue_job_chain_later}",
                                           "verbose=#{verbose}",
                                           "main_cc_id=#{main_cc_id}",
                                           "user_id=#{user_id}",
                                           "" ] if abstract_ingest_job_debug_verbose
    @job_status = IngestJobStatus.find_or_create_job_started( job: self,
                                                              parent_job_id: parent_job_id,
                                                              continue_job_chain_later: continue_job_chain_later,
                                                              verbose: verbose,
                                                              main_cc_id: main_cc_id,
                                                              user_id: user_id  )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "parent_job_id=#{parent_job_id}",
                                           "continue_job_chain_later=#{continue_job_chain_later}",
                                           "verbose=#{verbose}",
                                           "@job_status.job_id=#{@job_status.job_id}",
                                           "@job_status.parent_job_id=#{@job_status.parent_job_id}",
                                           "@job_status.message=#{@job_status.message}",
                                           "@job_status.error=#{@job_status.error}",
                                           "" ] if abstract_ingest_job_debug_verbose
    # @job_status.add_message! "#{self.class.name}#find_or_create_job_status_started" if verbose
    @job_status
  end

  def job_status
    @job_status # ||= job_status_init
  end

  # def job_status_init
  #   ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
  #                                          ::Deepblue::LoggingHelper.called_from,
  #                                          "" ] if abstract_ingest_job_debug_verbose
  #   rv = IngestJobStatus.find_or_create_job_started( job: self, verbose: abstract_ingest_job_debug_verbose )
  #   return rv
  # end

  def log_error( msg )
    job_status.reload if job_status.present?
    Rails.logger.error msg
    job_status.add_error! msg if job_status.present?
  end

end
