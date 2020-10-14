# frozen_string_literal: true

class CharacterizeJob < AbstractIngestJob

  CHARACTERIZE_JOB_DEBUG_VERBOSE = ::Deepblue::JobTaskHelper.characterize_job_debug_verbose

  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] repository_file_id identifier for a Hydra::PCDM::File
  # @param [String, NilClass] filepath the cached file within the Hyrax.config.working_path
  def perform( file_set,
               repository_file_id,
               filepath = nil,
               continue_job_chain: true,
               continue_job_chain_later: true,
               current_user: nil,
               delete_input_file: true,
               parent_job_id: nil,
               uploaded_file_ids: [] )

    find_or_create_job_status_started( parent_job_id: parent_job_id, continue_job_chain_later: continue_job_chain_later )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_set=#{file_set})",
                                           "repository_file_id=#{repository_file_id}",
                                           "filepath=#{filepath}",
                                           "continue_job_chain=#{continue_job_chain}",
                                           "continue_job_chain_later=#{continue_job_chain_later}",
                                           "current_user=#{current_user}",
                                           "delete_input_file=#{delete_input_file}",
                                           "parent_job_id=#{parent_job_id}",
                                           "job_status=#{job_status}",
                                           "uploaded_file_ids=#{uploaded_file_ids}",
                                           "" ] if CHARACTERIZE_JOB_DEBUG_VERBOSE
    ::Deepblue::IngestHelper.characterize( file_set,
                                           repository_file_id,
                                           filepath,
                                           continue_job_chain: continue_job_chain,
                                           continue_job_chain_later: continue_job_chain_later,
                                           current_user: current_user,
                                           delete_input_file: delete_input_file,
                                           job_status: job_status,
                                           uploaded_file_ids: uploaded_file_ids )
  rescue Exception => e # rubocop:disable Lint/RescueException
    log_error "CharacterizeJob.perform(#{file_set},#{repository_file_id},#{filepath}) #{e.class}: #{e.message}"
  end

end
