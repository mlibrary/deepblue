# frozen_string_literal: true

module Hyrax
  # monkey

  module Actors

    # Actions are decoupled from controller logic so that they may be called from a controller or a background job.
    class FileSetActor
      include Lockable
      attr_reader :file_set, :user, :attributes

      def initialize(file_set, user)
        @file_set = file_set
        @user = user
      end

      # @!group Asynchronous Operations

      # Spawns asynchronous IngestJob unless ingesting from URL
      # Called from FileSetsController, AttachFilesToWorkJob, IngestLocalFileJob, ImportUrlJob
      # @param [Hyrax::UploadedFile, File] file the file uploaded by the user
      # @param [Symbol, #to_s] relation
      # @return [IngestJob, FalseClass] false on failure, otherwise the queued job
      def create_content( file,
                          relation = :original_file,
                          from_url: false,
                          continue_job_chain_later: true,
                          uploaded_file_ids: [] )
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "file=#{file}",
                                             Deepblue::LoggingHelper.obj_to_json( "file", file ),
                                             "relation=#{relation}",
                                             "from_url=#{from_url}",
                                             "continue_job_chain_later=#{continue_job_chain_later}",
                                             "uploaded_file_ids=#{uploaded_file_ids}",
                                              "" ]
        # If the file set doesn't have a title or label assigned, set a default.
        file_set.label ||= label_for(file)
        file_set.title = [file_set.label] if file_set.title.blank?
        return false unless file_set.save # Need to save to get an id
        io_wrapper = wrapper!( file: file, relation: relation )
        if from_url
          # If ingesting from URL, don't spawn an IngestJob; instead
          # reach into the FileActor and run the ingest with the file instance in
          # hand. Do this because we don't have the underlying UploadedFile instance
          file_actor = build_file_actor( relation )
          file_actor.ingest_file( io_wrapper, continue_job_chain_later: continue_job_chain_later )
          parent = file_set.parent
          # Copy visibility and permissions from parent (work) to
          # FileSets even if they come in from BrowseEverything
          if continue_job_chain_later
            VisibilityCopyJob.perform_later( parent )
            InheritPermissionsJob.perform_later( parent )
          else
            VisibilityCopyJob.perform_now( parent )
            InheritPermissionsJob.perform_now( parent )
          end
        else
          IngestJob.perform_now( io_wrapper,
                                 continue_job_chain_later: continue_job_chain_later,
                                 uploaded_file_ids: uploaded_file_ids )
        end
      end

      # Spawns asynchronous IngestJob with user notification afterward
      # @param [Hyrax::UploadedFile, File, ActionDigest::HTTP::UploadedFile] file the file uploaded by the user
      # @param [Symbol, #to_s] relation
      # @return [IngestJob] the queued job
      def update_content( file, relation = :original_file )
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "user=#{user}",
                                             "file_set.id=#{file_set.id}",
                                             "file=#{file}",
                                             "relation=#{relation}" ]
        current_version = file_set.latest_version
        prior_revision_id = current_version.label
        prior_create_date = current_version.created
        file_set.provenance_update_version( current_user: user,
                                            event_note: "update_content",
                                            new_create_date: '',
                                            new_revision_id: '',
                                            prior_create_date: prior_create_date,
                                            prior_revision_id: prior_revision_id,
                                            revision_id: '' )
        IngestJob.perform_later( wrapper!(file: file, relation: relation), notification: true )
      end

      # @!endgroup

      # Adds the appropriate metadata, visibility and relationships to file_set
      # @note In past versions of Hyrax this method did not perform a save because it is mainly used in conjunction with
      #   create_content, which also performs a save.  However, due to the relationship between Hydra::PCDM objects,
      #   we have to save both the parent work and the file_set in order to record the "metadata" relationship between them.
      # @param [Hash] file_set_params specifying the visibility, lease and/or embargo of the file set.
      #   Without visibility, embargo_release_date or lease_expiration_date, visibility will be copied from the parent.
      def create_metadata( file_set_params = {} )
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "file_set_params=#{file_set_params}" ]
        file_set.depositor = depositor_id(user)
        now = TimeService.time_in_utc
        file_set.date_uploaded = now
        file_set.date_modified = now
        file_set.creator = [user.user_key]
        if assign_visibility?(file_set_params)
          env = Actors::Environment.new(file_set, ability, file_set_params)
          CurationConcern.file_set_create_actor.create(env)
        end
        yield(file_set) if block_given?
      end

      # Adds a FileSet to the work using ore:Aggregations.
      # Locks to ensure that only one process is operating on the list at a time.
      def attach_to_work( work, file_set_params = {}, uploaded_file_id: nil )
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "work.id=#{work.id}",
                                             "file_set_params=#{file_set_params}" ]
        acquire_lock_for( work.id ) do
          # Ensure we have an up-to-date copy of the members association, so that we append to the end of the list.
          work.reload unless work.new_record?
          file_set.visibility = work.visibility unless assign_visibility?(file_set_params)
          work.ordered_members << file_set
          work.representative = file_set if work.representative_id.blank?
          work.thumbnail = file_set if work.thumbnail_id.blank?
          # Save the work so the association between the work and the file_set is persisted (head_id)
          # NOTE: the work may not be valid, in which case this save doesn't do anything.
          work.save
          Deepblue::UploadHelper.log( class_name: self.class.name,
                                      event: "attach_to_work",
                                      id: file_set.id,
                                      uploaded_file_id: uploaded_file_id,
                                      work_id: work.id,
                                      work_file_set_count: work.file_set_ids.count )
          Hyrax.config.callback.run(:after_create_fileset, file_set, user)
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        Rails.logger.error "#{e.class} work.id=#{work.id} -- #{e.message} at #{e.backtrace[0]}"
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "ERROR",
                                             "e=#{e.class.name}",
                                             "e.message=#{e.message}",
                                             "e.backtrace:" ] +
                                               e.backtrace
        Deepblue::UploadHelper.log( class_name: self.class.name,
                                    event: "attach_to_work",
                                    event_note: "failed",
                                    id: work.id,
                                    uploaded_file_id: uploaded_file_id,
                                    work_id: work.id,
                                    exception: e.to_s,
                                    backtrace0: e.backtrace[0] )
      end
      alias attach_file_to_work attach_to_work
      deprecation_deprecate attach_file_to_work: "use attach_to_work instead"

      # @param [String] revision_id the revision to revert to
      # @param [Symbol, #to_sym] relation
      # @return [Boolean] true on success, false otherwise
      def revert_content( revision_id, relation = :original_file )
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "revision_id=#{revision_id}",
                                             "relation=#{relation}" ]
        # return false unless build_file_actor(relation).revert_to(revision_id)
        file_actor = build_file_actor( relation )
        # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
        #                                      Deepblue::LoggingHelper.called_from,
        #                                      Deepblue::LoggingHelper.obj_class( "file_actor", file_actor ) ]
        return false unless file_actor.revert_to revision_id
        Hyrax.config.callback.run(:after_revert_content, file_set, user, revision_id)
        true
      rescue Exception => e # rubocop:disable Lint/RescueException
        Rails.logger.error "#{e.class} work.id=#{work.id} -- #{e.message} at #{e.backtrace[0]}"
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "ERROR",
                                             "e=#{e.class.name}",
                                             "e.message=#{e.message}",
                                             "e.backtrace:" ] +
                                               e.backtrace
        false
      end

      def update_metadata(attributes)
        env = Actors::Environment.new(file_set, ability, attributes)
        CurationConcern.file_set_update_actor.update(env)
      end

      def destroy
        unlink_from_work
        file_set.destroy
        Hyrax.config.callback.run(:after_destroy, file_set.id, user)
      end

      class_attribute :file_actor_class
      self.file_actor_class = Hyrax::Actors::FileActor

      private

        def ability
          @ability ||= ::Ability.new(user)
        end

        def build_file_actor(relation)
          file_actor_class.new(file_set, relation, user)
        end

        # uses create! because object must be persisted to serialize for jobs
        def wrapper!( file:, relation: )
          JobIoWrapper.create_with_varied_file_handling!( user: user,
                                                          file: file,
                                                          relation: relation,
                                                          file_set: file_set )
        end

        # For the label, use the original_filename or original_name if it's there.
        # If the file was imported via URL, parse the original filename.
        # If all else fails, use the basename of the file where it sits.
        # @note This is only useful for labeling the file_set, because of the recourse to import_url
        def label_for(file)
          if file.is_a?(Hyrax::UploadedFile) # filename not present for uncached remote file!
            file.uploader.filename.present? ? file.uploader.filename : File.basename(Addressable::URI.parse(file.file_url).path)
          elsif file.respond_to?(:original_name) # e.g. Hydra::Derivatives::IoDecorator
            file.original_name
          elsif file_set.import_url.present?
            # This path is taken when file is a Tempfile (e.g. from ImportUrlJob)
            File.basename(Addressable::URI.parse(file_set.import_url).path)
          else
            File.basename(file)
          end
        end

        def assign_visibility?(file_set_params = {})
          !((file_set_params || {}).keys.map(&:to_s) & %w[visibility embargo_release_date lease_expiration_date]).empty?
        end

        # replaces file_set.apply_depositor_metadata(user)from hydra-access-controls so depositor doesn't automatically get edit access
        def depositor_id(depositor)
          depositor.respond_to?(:user_key) ? depositor.user_key : depositor
        end

        # Must clear the fileset from the thumbnail_id, representative_id and rendering_ids fields on the work
        #   and force it to be re-solrized.
        # Although ActiveFedora clears the children nodes it leaves those fields in Solr populated.
        # rubocop:disable Metrics/CyclomaticComplexity
        def unlink_from_work
          work = file_set.parent
          # monkey patch
          work.total_file_size_subtract_file_set! file_set
          # monkey patch
          return unless work && (work.thumbnail_id == file_set.id || work.representative_id == file_set.id || work.rendering_ids.include?(file_set.id))
          work.thumbnail = nil if work.thumbnail_id == file_set.id
          work.representative = nil if work.representative_id == file_set.id
          work.rendering_ids -= [file_set.id]
          work.save!
        end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity
    end

  end

end
