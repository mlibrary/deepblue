# frozen_string_literal: true

class CreateDerivativesJob < ::Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] repository_file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform( file_set,
               repository_file_id,
               filepath = nil,
               current_user: nil,
               delete_input_file: true,
               uploaded_file_ids: [] )

    Deepblue::IngestHelper.create_derivatives( file_set,
                                               repository_file_id,
                                               filepath,
                                               current_user: current_user,
                                               delete_input_file: delete_input_file,
                                               uploaded_file_ids: uploaded_file_ids )

  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "CreateDerivativesJob.perform(#{file_set},#{repository_file_id},#{filepath}) #{e.class}: #{e.message}"
  end

end
