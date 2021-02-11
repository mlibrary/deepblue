# frozen_string_literal: true

class ::Deepblue::DeepblueJob < ::Hyrax::ApplicationJob

  # A common base class for all Hyrax jobs.
  # This allows downstream applications to manipulate all the hyrax jobs by
  # including modules on this class.

  mattr_accessor :deepblue_job_debug_verbose
  @@deepblue_job_debug_verbose = false

  attr_accessor :job_status, :restartable

  def job_status_init( restartable: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "restartable=#{restartable}",
                                           "" ] if deepblue_job_debug_verbose
    @restartable = restartable
    @job_status = JobStatus.find_or_create_job_started( job: self )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_status=#{job_status}",
                                           "" ] if deepblue_job_debug_verbose
    @job_status
  end

  def job_status_register( exception:, msg: nil, args: '', rails_log: true, status: nil )
    msg = "#{self.class.name}.perform(#{args}) #{exception.class}: #{exception.message}" unless msg.present?
    Rails.logger.error msg if rails_log
    job_status = JobStatus.find_or_create_job_error( job: self, error: msg )
    return job_status if job_status.nil?
    return job_status.status! status unless status.nil?
    return job_status.status! JobStatus::FINISHED unless restartable
    job_status
  end

end
