# frozen_string_literal: true

class CreateDerivativesJob < AbstractIngestJob

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

    find_or_create_job_status_started( parent_job_id: parent_job_id )
    ::Deepblue::IngestHelper.create_derivatives( file_set,
                                                 repository_file_id,
                                                 filepath,
                                                 current_user: current_user,
                                                 delete_input_file: delete_input_file,
                                                 job_status: job_status,
                                                 uploaded_file_ids: uploaded_file_ids )

  rescue Exception => e # rubocop:disable Lint/RescueException
    log_error "CreateDerivativesJob.perform(#{file_set},#{repository_file_id},#{filepath}) #{e.class}: #{e.message}"
  end

end
