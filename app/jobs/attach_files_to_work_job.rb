# frozen_string_literal: true

# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < ::Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  ATTACH_FILES_TO_WORK_JOB_IS_VERBOSE = true
  ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY = false

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform( work, uploaded_files, user_key, **work_attributes )
    @processed = []
    Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                         Deepblue::LoggingHelper.called_from,
                                         "work=#{work}",
                                         "user_key=#{user_key}",
                                         "uploaded_files=#{uploaded_files}",
                                         "uploaded_files.count=#{uploaded_files.count}",
                                         "work_attributes=#{work_attributes}" ] if ATTACH_FILES_TO_WORK_JOB_IS_VERBOSE
    depositor = proxy_or_depositor( work )
    # user = User.find_by_user_key( depositor ) # Wrong!, it's actually on the upload file record.
    user = User.find_by_user_key( user_key )
    uploaded_file_ids = uploaded_files.map { |u| u.id }
    Deepblue::UploadHelper.log( class_name: self.class.name,
                                event: "attach_files_to_work",
                                event_note: "starting",
                                id: work.id,
                                uploaded_file_ids: uploaded_file_ids,
                                uploaded_file_ids_count: uploaded_file_ids.size,
                                user: user.to_s,
                                work_id: work.id,
                                work_file_set_count: work.file_set_ids.count,
                                asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY)
    validate_files!(uploaded_files)
    work_permissions = work.permissions.map( &:to_hash )
    metadata = visibility_attributes( work_attributes )
    uploaded_files.each do |uploaded_file|
      upload_file( work, uploaded_file, user, work_permissions, metadata, uploaded_file_ids: uploaded_file_ids )
    end
    failed = uploaded_files - @processed
    if failed.empty?
      Deepblue::UploadHelper.log( class_name: self.class.name,
                                  event: "attach_files_to_work",
                                  event_note: "finished",
                                  id: work.id,
                                  uploaded_file_ids: uploaded_file_ids,
                                  uploaded_file_ids_count: uploaded_file_ids.size,
                                  user: user.to_s,
                                  work_id: work.id,
                                  work_file_set_count: work.file_set_ids.count,
                                  asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY)
    else
      Rails.logger.error "FAILED to process all uploaded files at #{caller_locations(1, 1)[0]}, count of unprocessed files = #{failed.count}"
      Deepblue::UploadHelper.log( class_name: self.class.name,
                                  event: "attach_files_to_work",
                                  event_note: "finished_with_failed_files",
                                  id: work.id,
                                  uploaded_file_ids: uploaded_file_ids,
                                  uploaded_file_ids_count: uploaded_file_ids.size,
                                  user: user.to_s,
                                  work_id: work.id,
                                  work_file_set_count: work.file_set_ids.count,
                                  failed: failed,
                                  asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY )
    end
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} work_id=#{work.id} -- #{e.message} at #{e.backtrace[0]}"
    Deepblue::UploadHelper.log( class_name: self.class.name,
                                event: "attach_files_to_work",
                                event_note: "failed",
                                id: work.id,
                                user: user.to_s,
                                work_id: work.id,
                                exception: e.to_s,
                                backtrace0: e.backtrace[0],
                                asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY )
    raise
  end

  private

    # The attributes used for visibility - sent as initial params to created FileSets.
    def visibility_attributes(attributes)
      attributes.slice(:visibility, :visibility_during_lease,
                       :visibility_after_lease, :lease_expiration_date,
                       :embargo_release_date, :visibility_during_embargo,
                       :visibility_after_embargo)
    end

    def validate_files!(uploaded_files)
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.is_a? Hyrax::UploadedFile
        msg = "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
        Rails.logger.error msg
        raise ArgumentError, msg
      end
    end

    ##
    # A work with files attached by a proxy user will set the depositor as the intended user
    # that the proxy was depositing on behalf of. See tickets #2764, #2902.
    def proxy_or_depositor(work)
      work.on_behalf_of.blank? ? work.depositor : work.on_behalf_of
    end

    def upload_file( work, uploaded_file, user, work_permissions, metadata, uploaded_file_ids: [] )
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "work.id=#{work.id}",
                                           "uploaded_file.file=#{uploaded_file.file.path}",
                                           "uploaded_file.file_set_uri=#{uploaded_file.file_set_uri}",
                                           # Deepblue::LoggingHelper.obj_methods( "uploaded_file", uploaded_file ),
                                           # Deepblue::LoggingHelper.obj_instance_variables( "uploaded_file", uploaded_file ),
                                           Deepblue::LoggingHelper.obj_attribute_names( "uploaded_file", uploaded_file ),
                                           Deepblue::LoggingHelper.obj_to_json( "uploaded_file", uploaded_file ),
                                           "uploaded_file.id=#{Deepblue::UploadHelper.uploaded_file_id( uploaded_file )}",
                                           "user=#{user}",
                                           "work_permissions=#{work_permissions}",
                                           "metadata=#{metadata}",
                                           "uploaded_file_ids=#{uploaded_file_ids}",
                                           "" ] if ATTACH_FILES_TO_WORK_JOB_IS_VERBOSE
      Deepblue::UploadHelper.log( class_name: self.class.name,
                                  event: "upload_file",
                                  id: "NA",
                                  path: Deepblue::UploadHelper.uploaded_file_path( uploaded_file ),
                                  size: Deepblue::UploadHelper.uploaded_file_size( uploaded_file ),
                                  uploaded_file_id: Deepblue::UploadHelper.uploaded_file_id( uploaded_file ),
                                  user: user.to_s,
                                  work_id: work.id,
                                  work_file_set_count: work.file_set_ids.count,
                                  asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY)
      actor = Hyrax::Actors::FileSetActor.new( FileSet.create, user )
      actor.file_set.permissions_attributes = work_permissions
      actor.create_metadata( metadata )
      # when actor.create content is here, and the processing is synchronous, then it fails to add size to the file_set
      # actor.create_content( uploaded_file, continue_job_chain_later: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY )
      actor.attach_to_work( work, uploaded_file_id: Deepblue::UploadHelper.uploaded_file_id( uploaded_file ) )
      uploaded_file.update( file_set_uri: actor.file_set.uri )
      actor.create_content( uploaded_file,
                            continue_job_chain_later: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY,
                            uploaded_file_ids: uploaded_file_ids )
      @processed << uploaded_file
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "#{e.class} work.id=#{work.id} -- #{e.message} at #{e.backtrace[0]}"
      Deepblue::UploadHelper.log( class_name: self.class.name,
                                  event: "upload_file",
                                  event_note: "failed",
                                  id: work.id,
                                  path: uploaded_file.file.path,
                                  size: File.size( uploaded_file.file.path ),
                                  user: user,
                                  work_id: work.id,
                                  exception: e.to_s,
                                  backtrace0: e.backtrace[0],
                                  asynchronous: ATTACH_FILES_TO_WORK_UPLOAD_FILES_ASYNCHRONOUSLY )
    end

end
