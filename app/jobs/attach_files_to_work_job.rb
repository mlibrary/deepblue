# frozen_string_literal: true

# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkJob < ::Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  JOB_IS_VERBOSE = true

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform( work, uploaded_files, **work_attributes )
    @processed = []
    Deepblue::LoggingHelper.bold_debug [ "#{caller_locations(1, 1)[0]}",
                                         "work=#{work}",
                                         "uploaded_files=#{uploaded_files}",
                                         "uploaded_files.count=#{uploaded_files.count}",
                                         "work_attributes=#{work_attributes}" ] if JOB_IS_VERBOSE
    validate_files!(uploaded_files)
    depositor = proxy_or_depositor( work )
    user = User.find_by_user_key( depositor )
    work_permissions = work.permissions.map( &:to_hash )
    metadata = visibility_attributes( work_attributes )
    uploaded_files.each do |uploaded_file|
      upload_file( work, uploaded_file, user, work_permissions, metadata )
    end
    failed = uploaded_files - @processed
    Rails.logger.error "FAILED to process all uploaded files at #{caller_locations(1, 1)[0]}, count of unprocessed files = #{failed.count}" unless failed.empty?
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} work_id=#{work.id} -- #{e.message} at #{e.backtrace[0]}"
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

    def upload_file( work, uploaded_file, user, work_permissions, metadata )
      Deepblue::LoggingHelper.bold_debug [ "#{caller_locations(1, 1)[0]}",
                                           "work_id=#{work.id}",
                                           "uploaded_file.file=#{uploaded_file.file}",
                                           "uploaded_file.file_set_uri=#{uploaded_file.file_set_uri}",
                                           "user=#{user}",
                                           "work_permissions=#{work_permissions}",
                                           "metadata=#{metadata}" ] if JOB_IS_VERBOSE
      actor = Hyrax::Actors::FileSetActor.new( FileSet.create, user )
      actor.file_set.permissions_attributes = work_permissions
      actor.create_metadata( metadata )
      actor.create_content( uploaded_file )
      actor.attach_to_work( work )
      uploaded_file.update( file_set_uri: actor.file_set.uri )
      @processed << uploaded_file
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "#{e.class} work_id=#{work_id} -- #{e.message} at #{e.backtrace[0]}"
    end

end
