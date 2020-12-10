# frozen_string_literal: true

class CreateDerivativesJob < AbstractIngestJob

  # CREATE_DERIVATIVES_JOB_DEBUG_VERBOSE = ::Deepblue::IngestIntegrationService.create_derivatives_job_debug_verbose

  mattr_accessor :create_derivatives_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.create_derivatives_job_debug_verbose

  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] repository_file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform( file_set,
               repository_file_id,
               filepath = nil,
               current_user: nil,
               delete_input_file: true,
               parent_job_id: nil,
               uploaded_file_ids: [] )

    find_or_create_job_status_started( parent_job_id: parent_job_id, verbose: create_derivatives_job_debug_verbose )
    # job_status.add_message!( "#{self.class.name}.perform: #{repository_file_id}" ) if job_status.verbose
    ::Deepblue::IngestHelper.create_derivatives( file_set,
                                                 repository_file_id,
                                                 filepath,
                                                 current_user: current_user,
                                                 delete_input_file: delete_input_file,
                                                 job_status: job_status,
                                                 uploaded_file_ids: uploaded_file_ids )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_set.id=#{file_set.id}",
                                           "current_user=#{current_user}",
                                           "filepath=#{filepath}",
                                           "parent_job_id=#{parent_job_id}",
                                           "uploaded_file_ids=#{uploaded_file_ids}",
                                           "job_status=#{job_status}",
                                           "job_status.job_id=#{job_status.job_id}",
                                           "job_status.job_class=#{job_status.job_class}",
                                           "job_status.status=#{job_status.status}",
                                           "job_status.state=#{job_status.state}",
                                           "job_status.message=#{job_status.message}",
                                           "job_status.error=#{job_status.error}",
                                           "" ] if create_derivatives_job_debug_verbose
  rescue Exception => e # rubocop:disable Lint/RescueException
    log_error "CreateDerivativesJob.perform(#{file_set},#{repository_file_id},#{filepath}) #{e.class}: #{e.message}"
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_set.id=#{file_set.id}",
                                           "current_user=#{current_user}",
                                           "filepath=#{filepath}",
                                           "parent_job_id=#{parent_job_id}",
                                           "uploaded_file_ids=#{uploaded_file_ids}",
                                           "job_status=#{job_status}",
                                           "job_status.job_id=#{job_status.job_id}",
                                           "job_status.job_class=#{job_status.job_class}",
                                           "job_status.status=#{job_status.status}",
                                           "job_status.state=#{job_status.state}",
                                           "job_status.message=#{job_status.message}",
                                           "job_status.error=#{job_status.error}",
                                           "" ] + e.backtrace[0..8] if create_derivatives_job_debug_verbose
  end

end
