# frozen_string_literal: true
# Reviewed: hyrax4

module Hyrax

  module Actors

    # Actions for a file identified by file_set and relation (maps to use predicate)
    # @note Spawns asynchronous jobs
    class FileActor

      mattr_accessor :file_actor_debug_verbose,
                     default: Rails.configuration.file_actor_debug_verbose

      attr_reader :file_set, :relation, :user, :use_valkyrie

      # @param [FileSet] file_set the parent FileSet
      # @param [Symbol, #to_sym] relation the type/use for the file
      # @param [User] user the user to record as the Agent acting upon the file
      def initialize(file_set, relation, user, use_valkyrie: false) # use_valkyrie: Hyrax.config.query_index_from_valkyrie
        @use_valkyrie = use_valkyrie
        @file_set = file_set
        @relation = normalize_relation(relation)
        @user = user
      end

      # Persists file as part of file_set and spawns async job to characterize and create derivatives.
      # @param [JobIoWrapper] io the file to save in the repository, with mime_type and original_name
      # @return [CharacterizeJob, FalseClass] spawned job on success, false on failure
      # @note Instead of calling this method, use IngestJob to avoid synchronous execution cost
      # @see IngestJob
      # @todo create a job to monitor the temp directory (or in a multi-worker system, directories!) to prune old files that have made it into the repo
      def ingest_file(io,
                      continue_job_chain: true,
                      continue_job_chain_later: true,
                      current_user: nil,
                      delete_input_file: true,
                      job_status:,
                      uploaded_file_ids: [])
        use_valkyrie ? perform_ingest_file_through_valkyrie(io)
          : perform_ingest_file_through_active_fedora(io,
                                                      continue_job_chain: continue_job_chain,
                                                      continue_job_chain_later: continue_job_chain_later,
                                                      current_user: current_user,
                                                      delete_input_file: delete_input_file,
                                                      job_status: job_status,
                                                      uploaded_file_ids: uploaded_file_ids)
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
                                               "revision_id=#{revision_id}" ] if file_actor_debug_verbose
        repository_file = related_file
        current_version = file_set.latest_version
        prior_revision_id = current_version.label
        prior_create_date = current_version.created
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
        create_version(repository_file, user)
        CharacterizeJob.perform_later( file_set, repository_file.id, current_user: user )
      end

      # @note FileSet comparison is limited to IDs, but this should be sufficient, given that
      #   most operations here are on the other side of async retrieval in Jobs (based solely on ID).
      def ==(other)
        return false unless other.is_a?(self.class)
        file_set.id == other.file_set.id && relation == other.relation && user == other.user
      end

      private

      ##
      # Wraps the verisoning service with erro handling. if the service's
      # create handler isn't implemented, we want to accept that quietly here.
      def create_version(content, user)
        Hyrax::VersioningService.create(content, user)
      rescue NotImplementedError
        :no_op
      end

        def log_error( msg )
          job_status.reload if job_status.present?
          Rails.logger.error msg
          job_status.add_error! msg if job_status.present?
        end

      ##
        # @return [Hydra::PCDM::File] the file referenced by relation
        def related_file
          file_set.public_send(normalize_relation(relation)) || raise("No #{relation} returned for FileSet #{file_set.id}")
        end

      def perform_ingest_file_through_active_fedora( io,
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
                                               "uploaded_file_ids=#{uploaded_file_ids}" ] if file_actor_debug_verbose
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
                                                 "job_status.user_id=#{job_status.user_id}",
                                                 "" ] if file_actor_debug_verbose
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
                                                 "job_status.user_id=#{job_status.user_id}",
                                                 "" ] if file_actor_debug_verbose
        end
      end

      def perform_ingest_file_through_valkyrie(io) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "io=#{io}",
                                               "" ] if file_actor_debug_verbose
        # TODO: update for hyrax v3 / update for use of valkyrie
        file =
          begin
            Hyrax.storage_adapter.upload(resource: file_set, file: io, original_filename: io.original_name, use: relation)
          rescue StandardError => err
            Rails.logger.error("Failed to save file_metadata through valkyrie: #{err.message}")
            return false
          end
        file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: file.id)
        create_version(file_metadata, user)
        id = file_metadata.file_identifier
        file_set.file_ids << id
        file_set.original_file_id = id
        Hyrax.persister.save(resource: file_set)
        Hyrax.publisher.publish('object.metadata.updated', object: file_set, user: user)
        CharacterizeJob.perform_later(file_set, id.to_s, pathhint(io))
        file_metadata
      end

      def normalize_relation(relation)
          use_valkyrie ? normalize_relation_for_valkyrie(relation) : normalize_relation_for_active_fedora(relation)
        end

        def normalize_relation_for_active_fedora(relation)
          return relation.to_sym if relation.respond_to? :to_sym

          case relation
          when Hyrax::FileMetadata::Use::ORIGINAL_FILE
            :original_file
          when Hyrax::FileMetadata::Use::EXTRACTED_TEXT
            :extracted_file
          when Hyrax::FileMetadata::Use::THUMBNAIL
            :thumbnail_file
          else
            :original_file
          end
        end

        ##
        # @return [RDF::URI]
        def normalize_relation_for_valkyrie(relation)
          return relation if relation.is_a?(RDF::URI)

          Hyrax::FileMetadata::Use.uri_for(use: relation.to_sym)
        rescue ArgumentError
          Hyrax::FileMetadata::Use::ORIGINAL_FILE
        end

        def pathhint(io)
          io.uploaded_file&.uploader&.path || io.path
        end

    end

  end

end
