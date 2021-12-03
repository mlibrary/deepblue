# frozen_string_literal: true



class Hyrax::IngestLocalFileJob < AbstractIngestJob
  # monkey

  mattr_accessor :ingest_local_file_job_debug_verbose, default: false
  # default: ::Deepblue::IngestIntegrationService.ingest_job_debug_verbose

  queue_as Hyrax.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] path
  # @param [User] user
  def perform(file_set, path, user, continue_job_chain_later: true)

    find_or_create_job_status_started( parent_job_id: nil,
                                       continue_job_chain_later: continue_job_chain_later,
                                       verbose: ingest_local_file_job_debug_verbose )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_set.id=#{file_set.id}",
                                           "job_status.job_id=#{job_status.job_id}",
                                           "" ] if ingest_local_file_job_debug_verbose

    file_set.label ||= File.basename(path)

    actor = Hyrax::Actors::FileSetActor.new(file_set, user)

    if actor.create_content( File.open(path),
                             continue_job_chain_later: continue_job_chain_later,
                             job_status: job_status )

      Hyrax.config.callback.run(:after_import_local_file_success, file_set, user, path)
    else
      Hyrax.config.callback.run(:after_import_local_file_failure, file_set, user, path)
    end
  rescue SystemCallError
    # This is generic in order to handle Errno constants raised when accessing files
    # @see https://ruby-doc.org/core-2.5.3/Errno.html
    Hyrax.config.callback.run(:after_import_local_file_failure, file_set, user, path)
  end

end
