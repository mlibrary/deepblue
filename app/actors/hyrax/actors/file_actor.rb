# frozen_string_literal: true

module Hyrax

  module Actors

    # Actions for a file identified by file_set and relation (maps to use predicate)
    # @note Spawns asynchronous jobs
    class FileActor

      FILE_ACTOR_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.file_actor_debug_verbose

      attr_reader :file_set, :relation, :user

      # @param [FileSet] file_set the parent FileSet
      # @param [Symbol, #to_sym] relation the type/use for the file
      # @param [User] user the user to record as the Agent acting upon the file
      def initialize(file_set, relation, user)
        @file_set = file_set
        @relation = relation.to_sym
        @user = user
      end

      # Persists file as part of file_set and spawns async job to characterize and create derivatives.
      # @param [JobIoWrapper] io the file to save in the repository, with mime_type and original_name
      # @return [CharacterizeJob, FalseClass] spawned job on success, false on failure
      # @note Instead of calling this method, use IngestJob to avoid synchronous execution cost
      # @see IngestJob
      # @todo create a job to monitor the temp directory (or in a multi-worker system, directories!) to prune old files that have made it into the repo
      def ingest_file( io,
                       continue_job_chain: true,
                       continue_job_chain_later: true,
                       current_user: nil,
                       delete_input_file: true,
                       job_status:,
                       uploaded_file_ids: [] )

        # job_status.add_message! "FileActor#ingest_file" if job_status.verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "file_set=#{file_set}",
                                               "file_set.id=#{file_set.id}",
                                               "file_set.original_file=#{file_set.original_file}",
                                               "relation=#{relation}",
                                               "user=#{user}",
                                               "io=#{io}",
                                               "continue_job_chain=#{continue_job_chain}",
                                               "continue_job_chain_later=#{continue_job_chain_later}",
                                               "delete_input_file=#{delete_input_file}",
                                               "job_status=#{job_status}",
                                               "uploaded_file_ids=#{uploaded_file_ids}" ] if FILE_ACTOR_DEBUG_VERBOSE
        unless job_status.did_add_file_to_file_set?
          # Skip versioning because versions will be minted by VersionCommitter as necessary during
          # save_characterize_and_record_committer.
          Hydra::Works::AddFileToFileSet.call_enhanced_version( file_set,
                                               io,
                                               relation,
                                               versioning: false,
                                               job_status: job_status )
          unless file_set.save
            job_status.add_error! "file_set.save returned false, exiting FileSet#ingest_file early"
            ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                                        ::Deepblue::LoggingHelper.called_from,
                                                        "io=#{io})",
                                                        "user=#{user}",
                                                        "continue_job_chain=#{continue_job_chain}",
                                                        "continue_job_chain_later=#{continue_job_chain_later}",
                                                        "delete_input_file=#{delete_input_file}",
                                                        "job_status=#{job_status}",
                                                        "uploaded_file_ids=#{uploaded_file_ids}",
                                                        "",
                                                        "file_set failed to save after call to AddFileToFileSet during ingest file",
                                                        "" ] # error
            return false
          end
          job_status.did_add_file_to_file_set!
        end
        repository_file = related_file
        unless job_status.did_versioning_service_create?
          Hyrax::VersioningService.create( repository_file, current_user )
          job_status.did_versioning_service_create!
        end
        pathhint = io.uploaded_file.uploader.path if io.uploaded_file # in case next worker is on same filesystem
        next_parent_id = job_status.null_job_status? ? nil : job_status.job_id
        job_status.did_file_ingest!
        if continue_job_chain_later
          CharacterizeJob.perform_later( file_set,
                                         repository_file.id,
                                         pathhint || io.path,
                                         current_user: current_user,
                                         parent_job_id: next_parent_id,
                                         uploaded_file_ids: uploaded_file_ids )
        else
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "job_status.job_id=#{job_status.job_id}",
                                                 "job_status.parent_job_id=#{job_status.parent_job_id}",
                                                 "job_status.message=#{job_status.message}",
                                                 "job_status.error=#{job_status.error}",
                                                 "" ] if FILE_ACTOR_DEBUG_VERBOSE
          CharacterizeJob.perform_now( file_set,
                                       repository_file.id,
                                       pathhint || io.path,
                                       continue_job_chain: continue_job_chain,
                                       continue_job_chain_later: continue_job_chain_later,
                                       current_user: current_user,
                                       delete_input_file: delete_input_file,
                                       parent_job_id: next_parent_id,
                                       uploaded_file_ids: uploaded_file_ids )
          job_status.reload
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "job_status.job_id=#{job_status.job_id}",
                                                 "job_status.parent_job_id=#{job_status.parent_job_id}",
                                                 "job_status.message=#{job_status.message}",
                                                 "job_status.error=#{job_status.error}",
                                                 "" ] if FILE_ACTOR_DEBUG_VERBOSE
        end
      end

      # Reverts file and spawns async job to characterize and create derivatives.
      # @param [String] revision_id
      # @return [CharacterizeJob, FalseClass] spawned job on success, false on failure
      def revert_to( revision_id )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "user=#{user}",
                                               "file_set.id=#{file_set.id}",
                                               "relation=#{relation}",
                                               "revision_id=#{revision_id}" ] if FILE_ACTOR_DEBUG_VERBOSE
        repository_file = related_file
        current_version = file_set.latest_version
        prior_revision_id = current_version.label
        prior_create_date = current_version.created
        # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                      Deepblue::LoggingHelper.called_from,
        #                                      "repository_file=#{repository_file}",
        #                                      "file_set.latest_version_create_datetime=#{prior_create_date}" ]
        repository_file.restore_version(revision_id)
        # return false unless file_set.save
        unless file_set.save
          ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                                      ::Deepblue::LoggingHelper.called_from,
                                                      "io=#{io})",
                                                      "user=#{user}",
                                                      "continue_job_chain=#{continue_job_chain}",
                                                      "continue_job_chain_later=#{continue_job_chain_later}",
                                                      "delete_input_file=#{delete_input_file}",
                                                      "uploaded_file_ids=#{uploaded_file_ids}",
                                                      "",
                                                      "file_set failed to save after call to restore version during revert to",
                                                      "" ] # error
          return false
        end
        current_version = file_set.latest_version
        new_revision_id = current_version.label
        new_create_date = current_version.created
        file_set.provenance_update_version( current_user: user,
                                            event_note: "revert_to",
                                            new_create_date: new_create_date,
                                            new_revision_id: new_revision_id,
                                            prior_create_date: prior_create_date,
                                            prior_revision_id: prior_revision_id,
                                            revision_id: revision_id )
        Hyrax::VersioningService.create( repository_file, user )
        CharacterizeJob.perform_later( file_set, repository_file.id, current_user: user )
      end

      # @note FileSet comparison is limited to IDs, but this should be sufficient, given that
      #   most operations here are on the other side of async retrieval in Jobs (based solely on ID).
      def ==(other)
        return false unless other.is_a?(self.class)
        file_set.id == other.file_set.id && relation == other.relation && user == other.user
      end

      private

        def log_error( msg )
          job_status.reload if job_status.present?
          Rails.logger.error msg
          job_status.add_error! msg if job_status.present?
        end

        # @return [Hydra::PCDM::File] the file referenced by relation
        def related_file
          file_set.public_send(relation) || raise("No #{relation} returned for FileSet #{file_set.id}")
        end

    end

  end

end
