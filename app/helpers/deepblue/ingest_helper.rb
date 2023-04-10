# frozen_string_literal: true

module Deepblue

  module IngestHelper

    mattr_accessor :ingest_helper_debug_verbose,
                   default: ::Deepblue::IngestIntegrationService.ingest_helper_debug_verbose

    mattr_accessor :ingest_helper_debug_verbose_puts, default: false

    def self.after_create_derivative( file_set:, file_set_orig:, job_status: )
      # Reload from Fedora and reindex for thumbnail and extracted text
      file_set.reload
      file_set.update_index
      file_set.parent.update_index if file_set.parent.present? && parent_needs_reindex?(file_set)
      #
      # file_set.under_embargo?
      # looks like file_set becomes nil in here. Does it fail to reload?
      #
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set}",
                                             "file_set.under_embargo?=#{file_set.under_embargo?}",
                                             "file_set.parent.present? && !file_set.parent.under_embargo?=#{file_set.parent.present? && !file_set.parent.under_embargo?}",
                                             "job_status=#{job_status}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      file_set = file_set_orig if file_set.nil?
      if file_set.under_embargo? && (file_set.parent.present? && !file_set.parent.under_embargo?)
        file_set.deactivate_embargo!
        file_set.save
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "file_set=#{file_set}",
                                               "file_set.under_embargo?=#{file_set.under_embargo?}",
                                               "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      end
      job_status.did_characterize!
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "IngestHelper.after_create_derivative(#{file_set}) #{compose_e_msg( e )}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "error msg=#{msg}",
                                             "" ] + e.backtrace[0..8], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      if Rails.configuration.derivative_create_error_report_to_curation_notes_admin
        file_set.add_curation_note_admin( note: msg )
      end
      log_error( msg, job_status: job_status )
    end

    # @param [FileSet] file_set
    # @param [String] repository_file_id identifier for a Hydra::PCDM::File
    # @param [String, NilClass] file_path the cached file within the Hyrax.config.working_path
    def self.characterize( file_set,
                           repository_file_id,
                           file_path = nil,
                           continue_job_chain: true,
                           continue_job_chain_later: true,
                           current_user: IngestHelper.current_user,
                           delete_input_file: true,
                           job_status:,
                           uploaded_file_ids: [],
                           **added_prov_key_values )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set}",
                                             "repository_file_id=#{repository_file_id}",
                                             "file_path=#{file_path}",
                                             "continue_job_chain=#{continue_job_chain}",
                                             "continue_job_chain_later=#{continue_job_chain_later}",
                                             "current_user=#{current_user}",
                                             "delete_input_file=#{delete_input_file}",
                                             "job_status=#{job_status}",
                                             "uploaded_file_ids=#{uploaded_file_ids}",
                                             "added_prov_key_values=#{added_prov_key_values}",
                                             # "wrapper.methods=#{wrapper.methods.sort}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      # See Hyrax gem: app/job/characterize_job.rb
      file_name = Hyrax::WorkingDirectory.find_or_retrieve( repository_file_id, file_set.id, file_path )
      unless file_set.characterization_proxy?
        error_msg = "#{file_set.class.characterization_proxy} was not found"
        log_error( error_msg, job_status: job_status )
        raise LoadError, error_msg
      end
      unless job_status.did_characterize?
        begin
          proxy = file_set.characterization_proxy
          Hydra::Works::CharacterizationService.run( proxy, file_name )
          Rails.logger.debug "Ran characterization on #{proxy.id} (#{proxy.mime_type})" if ingest_helper_debug_verbose
          file_set.provenance_characterize( current_user: current_user,
                                            calling_class: name,
                                            **added_prov_key_values )
          file_set.characterization_proxy.save!
          file_set.update_index
          file_set.parent&.in_collections&.each(&:update_index)
          # file_set.parent.in_collections.each( &:update_index ) if file_set.parent
          job_status.did_characterize!
        rescue Exception => e # rubocop:disable Lint/RescueException
          msg = "IngestHelper.characterize(#{file_path}) #{compose_e_msg( e )}"
          log_error( msg, job_status: job_status )
        end
      end
      update_total_file_size( file_set, log_prefix: "CharacterizationHelper.characterize()", job_status: job_status )
      perform_create_derivatives_job( file_set,
                                      repository_file_id,
                                      file_name,
                                      file_path,
                                      continue_job_chain: continue_job_chain,
                                      continue_job_chain_later: continue_job_chain_later,
                                      current_user: current_user,
                                      delete_input_file: delete_input_file,
                                      job_status: job_status,
                                      uploaded_file_ids: uploaded_file_ids,
                                      **added_prov_key_values )
    end

    # @param [FileSet] file_set
    # @param [String] repository_file_id identifier for a Hydra::PCDM::File
    # @param [String, NilClass] file_path the cached file within the Hyrax.config.working_path
    def self.create_derivatives( file_set,
                                 repository_file_id,
                                 file_path = nil,
                                 current_user: IngestHelper.current_user,
                                 delete_input_file: true,
                                 job_status:,
                                 uploaded_file_ids: [],
                                 **added_prov_key_values )

      raise ArgumentError, "job_status blank" if job_status.blank?
      file_set_orig = file_set
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set}",
                                             "repository_file_id=#{repository_file_id}",
                                             "file_path=#{file_path}",
                                             "current_user=#{current_user}",
                                             "delete_input_file=#{delete_input_file}",
                                             "job_status=#{job_status}",
                                             "uploaded_file_ids=#{uploaded_file_ids}",
                                             "added_prov_key_values=#{added_prov_key_values}",
                                             # "wrapper.methods=#{wrapper.methods.sort}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      unless job_status.did_create_derivatives?
        # See Hyrax gem: app/job/create_derivatives_job.rb
        file_name = Hyrax::WorkingDirectory.find_or_retrieve( repository_file_id, file_set.id, file_path )
        Rails.logger.info "Create derivatives for: #{file_name}."
        begin
          file_ext = ''
          file_ext = File.extname file_set.label if file_set.label.present?
          if derivative_excluded_ext_set? file_ext
            Rails.logger.info "Skipping derivative of file with extension #{file_ext}: #{file_name}"
            file_set.add_curation_note_admin( note: "Skipping derivative for file with extension "\
                                              "#{file_ext}" ) if ingest_helper_debug_verbose
            file_set.provenance_create_derivative( current_user: current_user,
                                                   event_note: "skipped_extension #{file_ext}",
                                                   calling_class: name,
                                                   **added_prov_key_values )
            job_status.did_create_derivatives!
            return
          end
          if file_set.video? && !Hyrax.config.enable_ffmpeg
            Rails.logger.info "Skipping video derivative job for file: #{file_name}"
            file_set.add_curation_note_admin( note: "Skipping derivative for video file." ) if ingest_helper_debug_verbose
            file_set.provenance_create_derivative( current_user: current_user,
                                                   event_note: "skipped_extension #{file_ext}",
                                                   calling_class: name,
                                                   **added_prov_key_values )
            job_status.did_create_derivatives!
            return
          end
          if file_too_big(file_name)
            human_readable = ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( Rails.configuration.derivative_max_file_size, precision: 3 )
            Rails.logger.info "Skipping file larger than #{human_readable} for create derivative job file: #{file_name}"
            file_set.add_curation_note_admin( note: "Skipping derivative for file larger than "\
                                              "#{human_readable}." ) if ingest_helper_debug_verbose
            file_set.provenance_create_derivative( current_user: current_user,
                                                   event_note: "skipped_file_size #{File.size(file_name)}",
                                                   calling_class: name,
                                                   **added_prov_key_values )
            job_status.did_create_derivatives!
            return
          end
          Rails.logger.debug "About to call create derivatives: #{file_name}." if ingest_helper_debug_verbose
          file_set_create_derivatives( file_set, file_name )
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Create derivative successful",
                                                 "file_name=#{file_name}",
                                                 "file_set.create_derivatives_duration=#{file_set.create_derivatives_duration}",
                                                 "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
          file_set.provenance_create_derivative( current_user: current_user,
                                                 calling_class: IngestHelper.class.name,
                                                 **added_prov_key_values )

          after_create_derivative( file_set: file_set, file_set_orig: file_set_orig, job_status: job_status )
          Rails.logger.debug "Successful create derivative job for file: #{file_name}" if ingest_helper_debug_verbose
          file_set.add_curation_note_admin( note: "Create derivative successful in"\
                                      " #{create_derivatives_duration( file_set )}." ) if ingest_helper_debug_verbose
          job_status.did_create_derivatives!
        rescue Hydra::Derivatives::TimeoutError => te # rubocop:disable Lint/RescueException
          after_create_derivative( file_set: file_set, file_set_orig: file_set_orig, job_status: job_status )
          create_derivative_error( file_set: file_set,
                                   job_status: job_status,
                                   repository_file_id: repository_file_id,
                                   file_path: file_path,
                                   exception: te )
        rescue Timeout::Error => te2 # rubocop:disable Lint/RescueException
          after_create_derivative( file_set: file_set, file_set_orig: file_set_orig, job_status: job_status )
          create_derivative_error( file_set: file_set,
                                   job_status: job_status,
                                   repository_file_id: repository_file_id,
                                   file_path: file_path,
                                   exception: te2 )
        rescue Exception => e # rubocop:disable Lint/RescueException
          create_derivative_error( file_set: file_set,
                                   job_status: job_status,
                                   repository_file_id: repository_file_id,
                                   file_path: file_path,
                                   exception: e )
        ensure
          # This is the last step in the process ( ingest job -> characterization job -> create derivative (last step))
          # So now it's safe to remove the file uploaded file.
          delete_file( file_path,
                       delete_file_flag: delete_input_file,
                       msg_prefix: 'Create derivatives ',
                       job_status: job_status )
        end
      end
    end

    def self.file_set_create_derivatives( file_set, file_name )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set}",
                                             "file_name=#{file_name}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      file_set.create_derivatives( file_name )
    end

    def self.derivative_excluded_ext_set?( file_ext )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_ext=#{file_ext}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      Rails.configuration.derivative_excluded_ext_set.key? file_ext
    end

    def self.file_too_big(file_name)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_name=#{file_name}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      threshold_file_size = Rails.configuration.derivative_max_file_size
      threshold_file_size > -1 && File.exist?(file_name) && File.size(file_name) > threshold_file_size
    end

    def self.create_derivatives_duration( file_set )
      return 0 if file_set.create_derivatives_duration.blank?
      ActiveSupport::Duration.build( file_set.create_derivatives_duration ).inspect
    end

    def self.create_derivative_error( file_set:,
                                      job_status:,
                                      repository_file_id:,
                                      file_path:,
                                      exception: )

      msg = "IngestHelper.create_derivatives(#{file_set},#{repository_file_id},#{file_path}) "\
            "#{exception.class}: #{exception.message} at #{exception.backtrace[0]} in "\
            "#{create_derivatives_duration( file_set )}"

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "error msg=#{msg}",
                                             "" ] + exception.backtrace[0..50] if ingest_helper_debug_verbose
      if Rails.configuration.derivative_create_error_report_to_curation_notes_admin
        file_set.add_curation_note_admin( note: msg )
      end
      log_error( msg, job_status: job_status )
    end

    def self.current_user
      ProvenanceHelper.system_as_current_user
    end

    def self.delete_file( file_path, delete_file_flag: false, msg_prefix: '', job_status: )
      return if job_status.did_delete_file?
      if delete_file_flag && file_path.present? && File.exist?( file_path )
        File.delete file_path
        job_status.did_delete_file!
        Rails.logger.debug "#{msg_prefix}file deleted: #{file_path}" if ingest_helper_debug_verbose
      else
        job_status.did_delete_file! # flags that this method has been done and doesn't need to be done again
      end
    end

    # this method is never called
    def self.file_set_actor_create_content( file_set,
                                            file,
                                            relation = :original_file,
                                            job_status:,
                                            uploaded_file_ids: [] )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set})",
                                             "file=#{file})",
                                             "relation=#{relation}",
                                             "job_status=#{job_status}",
                                             "uploaded_file_ids=#{uploaded_file_ids}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose

      # If the file set doesn't have a title or label assigned, set a default.
      file_set.label ||= label_for( file )
      file_set.title = [file_set.label] if file_set.title.blank?
      # return false unless file_set.save # Need to save to get an id
      unless file_set.save # Need to save to get an id
        job_status.add_error! "file_set.save returned false, exiting IngestHelper#file_set_actor_create_content early"
        ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "file_set=#{file_set})",
                                              "file=#{file})",
                                              "relation=#{relation}",
                                              "job_status=#{job_status}",
                                              "uploaded_file_ids=#{uploaded_file_ids}",
                                              "",
                                              "file_set save failed in file_set_actor_create_content",
                                              "" ] # error
        return false
      end
      # if from_url
      #   # If ingesting from URL, don't spawn an IngestJob; instead
      #   # reach into the FileActor and run the ingest with the file instance in
      #   # hand. Do this because we don't have the underlying UploadedFile instance
      #   file_actor = build_file_actor(relation)
      #   file_actor.ingest_file(wrapper!(file: file, relation: relation))
      #   # Copy visibility and permissions from parent (work) to
      #   # FileSets even if they come in from BrowseEverything
      #   VisibilityCopyJob.perform_later(file_set.parent)
      #   InheritPermissionsJob.perform_later(file_set.parent)
      # else
      #   IngestJob.perform_later(wrapper!(file: file, relation: relation))
      # end
      io = JobIoWrapper.create_with_varied_file_handling!( user: user, file: file, relation: relation, file_set: file_set )
      # FileActor#ingest_file(io)
      # def ingest_file(io)
      # Skip versioning because versions will be minted by VersionCommitter as necessary during save_characterize_and_record_committer.
      Hydra::Works::AddFileToFileSet.call_enhanced_version( file_set,
                                           io,
                                           relation,
                                           versioning: false,
                                           job_status: job_status )
      # return false unless file_set.save
      unless file_set.save # Need to save to get an id
        job_status.add_error! "file_set.save returned false, exiting IngestHelper#file_set_actor_create_content early"
        ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                                    ::Deepblue::LoggingHelper.called_from,
                                                    "file_set=#{file_set})",
                                                    "file=#{file})",
                                                    "relation=#{relation}",
                                                    "job_status=#{job_status}",
                                                    "uploaded_file_ids=#{uploaded_file_ids}",
                                                    "",
                                                    "file_set save failed in file_set_actor_create_content after AddFileToFileSet",
                                                    "" ] # error
        return false
      end
      repository_file = related_file( file_set, relation )
      Hyrax::VersioningService.create( repository_file, user )
      virus_scan( file_set: file_set, job_status: job_status )
      # pathhint = io.uploaded_file.uploader.path if io.uploaded_file # in case next worker is on same filesystem
      # CharacterizeJob.perform_later(file_set, repository_file.id, pathhint || io.path)
      characterize( file_set, repository_file.id, io.path, job_status: job_status )
    end

    # @param [FileSet] file_set
    # @param [String] filepath the cached file within the Hyrax.config.working_path
    # @param [User] user
    # @option opts [String] mime_type
    # @option opts [String] filename
    # @option opts [String] relation, ex. :original_file
    def self.ingest( file_set, path, _user, job_status, uploaded_file_ids = [], _opts = {} )
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "file_set=#{file_set}",
                                           "path=#{path}",
                                           "uploaded_file_ids=#{uploaded_file_ids}",
                                           "user=#{_user}",
                                           "opts=#{opts}",
                                           # "wrapper.methods=#{wrapper.methods.sort}",
                                           "" ], bold_puts: ingest_helper_debug_verbose_puts if INGEST_HELPER_VERBOSE
      # launched from Hyrax gem: app/actors/hyrax/actors/file_set_actor.rb  FileSetActor#create_content
      # See Hyrax gem: app/job/ingest_local_file_job.rb
      # def perform(file_set, path, user)
      file_set.label ||= File.basename(path)
      file_set_actor_create_content( file_set, File.open(path), uploaded_file_ids: uploaded_file_ids, job_status: job_status )
    end

    # For the label, use the original_filename or original_name if it's there.
    # If the file was imported via URL, parse the original filename.
    # If all else fails, use the basename of the file where it sits.
    # @note This is only useful for labeling the file_set, because of the recourse to import_url
    def self.label_for( file )
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

    def self.log_error( msg, job_status: )
      Rails.logger.error msg
      job_status.add_error! msg
    end

    def self.related_file( file_set, relation )
      file_set.public_send(relation) || raise("No #{relation} returned for FileSet #{file_set.id}")
    end

    # If this file_set is the thumbnail for the parent work,
    # then the parent also needs to be reindexed.
    def self.parent_needs_reindex?(file_set)
      return false unless file_set.parent
      file_set.parent.thumbnail_id == file_set.id
    end

    def self.perform_create_derivatives_job( file_set,
                                             repository_file_id,
                                             file_name,
                                             file_path,
                                             continue_job_chain: true,
                                             continue_job_chain_later: true,
                                             current_user: IngestHelper.current_user,
                                             delete_input_file: true,
                                             job_status:,
                                             uploaded_file_ids: [],
                                             **added_prov_key_values )

      # job_status.add_message! "IngestHelper.perform_create_derivatives_job" if job_status.present? && job_status.verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set}",
                                             "repository_file_id=#{repository_file_id}",
                                             "file_name=#{file_name}",
                                             "file_path=#{file_path}",
                                             "continue_job_chain=#{continue_job_chain}",
                                             "continue_job_chain_later=#{continue_job_chain_later}",
                                             "current_user=#{current_user}",
                                             "delete_input_file=#{delete_input_file}",
                                             "job_status=#{job_status}",
                                             "uploaded_file_ids=#{uploaded_file_ids}",
                                             "added_prov_key_values=#{added_prov_key_values}",
                                             # "wrapper.methods=#{wrapper.methods.sort}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      if continue_job_chain
        if continue_job_chain_later
          # TODO: see about adding **added_prov_key_values to this:
          CreateDerivativesJob.perform_later( file_set,
                                              repository_file_id,
                                              file_name,
                                              current_user: current_user,
                                              delete_input_file: delete_input_file,
                                              parent_job_id: nil,
                                              uploaded_file_ids: uploaded_file_ids )
        else
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "job_status.job_id=#{job_status.job_id}",
                                                 "job_status.parent_job_id=#{job_status.parent_job_id}",
                                                 "job_status.message=#{job_status.message}",
                                                 "job_status.error=#{job_status.error}",
                                                 "job_status.user_id=#{job_status.user_id}",
                                                 "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
          create_derivatives( file_set,
                              repository_file_id,
                              file_name,
                              delete_input_file: delete_input_file,
                              current_user: current_user,
                              job_status: job_status,
                              uploaded_file_ids: uploaded_file_ids,
                              **added_prov_key_values )
          job_status.reload
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "job_status.job_id=#{job_status.job_id}",
                                                 "job_status.parent_job_id=#{job_status.parent_job_id}",
                                                 "job_status.message=#{job_status.message}",
                                                 "job_status.error=#{job_status.error}",
                                                 "job_status.user_id=#{job_status.user_id}",
                                                 "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
        end
      else
        delete_file( file_path,
                     delete_file_flag: delete_input_file,
                     msg_prefix: 'Characterize ',
                     job_status: job_status )
      end
    end

    def self.update_total_file_size( file_set, log_prefix: nil, job_status: )
      # this method can be called multiple times during an ingest and it will always improve or leave the state
      # of the parent work the same, thus no need to for job_status to block it if it has already been done
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set}",
                                             "log_prefix=#{log_prefix}",
                                             # "wrapper.methods=#{wrapper.methods.sort}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      # Rails.logger.info "begin IngestHelper.update_total_file_size"
      # Rails.logger.debug "#{log_prefix} file_set.original_file.size=#{file_set.original_file_size}" unless log_prefix.nil?
      # Rails.logger.info "nothing to update, parent is nil" if file_set.parent.nil?
      return if file_set.parent.nil?
      total = file_set.parent.total_file_size
      Rails.logger.debug "#{log_prefix}.file_set.parent.update_total_file_size!" unless log_prefix.nil?
      file_set.parent.update_total_file_size!
      # if total.nil? || total.zero?
      #   Rails.logger.debug "#{log_prefix}.file_set.parent.update_total_file_size!" unless log_prefix.nil?
      #   file_set.parent.update_total_file_size!
      # else
      #   Rails.logger.debug "#{log_prefix}.file_set.parent.total_file_size_add_file_set!" unless log_prefix.nil?
      #   file_set.parent.total_file_size_add_file_set! file_set
      # end
      Rails.logger.info "end IngestHelper.update_total_file_size"
      # job_status.add_message! "IngestHelper.update_total_file_size" if job_status.present? && job_status.verbose
    rescue Exception => e # rubocop:disable Lint/RescueException
      log_error( "IngestHelper.update_total_file_size(#{file_set}) #{compose_e_msg( e )}",
                         job_status: job_status )
    end

    def self.virus_scan( file_set:, job_status: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set}",
                                             "job_status=#{job_status}",
                                             "" ], bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      # this is called by a method that is never called
      return if job_status.did_virus_scan?
      ::Deepblue::LoggingHelper.bold_debug "IngestHelper.virus_scan #{file_set}", bold_puts: ingest_helper_debug_verbose_puts if ingest_helper_debug_verbose
      file_set.virus_scan
      job_status.did_virus_scan!
    rescue Exception => e # rubocop:disable Lint/RescueException
      log_error( "IngestHelper.virus_scan(#{file_set}) #{compose_e_msg( e )}",
                 job_status: job_status )
    end

    def compose_e_msg( e )
      IngestHelper.compose_e_msg( e )
    end

    def self.compose_e_msg( e )
      return "#{e.class}: #{e.message} at #{e.backtrace[0..4]}" if ingest_helper_debug_verbose
      "#{e.class}: #{e.message} at #{e.backtrace[0]}"
    end

  end

end
