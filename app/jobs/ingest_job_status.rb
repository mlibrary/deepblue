
class IngestJobStatus

  CREATED_FILE_SET              = 'created_file_set'.freeze
  DELETE_FILE                   = 'delete_file'.freeze
  FINISHED_ADD_FILE_TO_FILE_SET = 'finished_add_file_to_file_set'.freeze
  FINISHED_CHARACTERIZE         = 'finished_characterize'.freeze
  FINISHED_CREATE_DERIVATIVES   = 'finished_create_derivatives'.freeze
  FINISHED_FILE_INGEST          = 'finished_file_ingest'.freeze
  FINISHED_NOTIFY               = 'finished_notify'.freeze
  FINISHED_LOG_STARTING         = 'finished_log_starting'.freeze
  FINISHED_VALIDATE_FILES       = 'finished_validate_files'.freeze
  FINISHED_VERSIONING_SERVICE_CREATE = 'finished_versioning_service_create'.freeze
  FINISHED_UPLOAD_FILES         = 'finished_upload_files'.freeze
  UPLOADING_FILES               = 'uploading_files'.freeze

  ORDERED_JOB_STATUS_LIST = [ FINISHED_LOG_STARTING,
                              FINISHED_VALIDATE_FILES,
                              FINISHED_ADD_FILE_TO_FILE_SET,
                              UPLOADING_FILES,
                              CREATED_FILE_SET,
                              FINISHED_VERSIONING_SERVICE_CREATE,
                              FINISHED_CHARACTERIZE,
                              FINISHED_CREATE_DERIVATIVES,
                              DELETE_FILE,
                              FINISHED_FILE_INGEST,
                              FINISHED_UPLOAD_FILES,
                              FINISHED_NOTIFY ].freeze

  UPLOADING_FILES_STATUS_LIST = [ UPLOADING_FILES,
                                  CREATED_FILE_SET,
                                  FINISHED_VERSIONING_SERVICE_CREATE,
                                  FINISHED_CHARACTERIZE,
                                  FINISHED_CREATE_DERIVATIVES,
                                  DELETE_FILE,
                                  FINISHED_FILE_INGEST ]

  attr_accessor :job_id, :job_status, :ordered_job_status_list

  delegate :add_error!,
           :add_message!,
           :error,
           :job_class_name,
           :parent_job_id,
           :message,
           :save!,
           :status,
           :state,
           :state_deserialize,
           :state_serialize,
           :status?,
           :update_status!,
           :update_finished!,
           :update_started!,
           to: :job_status

  def self.find_job_status( job_id: nil, parent_job_id: nil, continue_job_chain_later: false )
    # TODO: take continue_job_chain_later into account
    # if the parent_job_id exists, use it
    return new_job_status( job_id: parent_job_id ) if parent_job_id.present?
    new_job_status( job_id: job_id )
  end

  def self.find_or_create_job_started( job: nil, parent_job_id: nil, continue_job_chain_later: false )
    # TODO: take continue_job_chain_later into account
    return new_job_status( job_id: parent_job_id ) if parent_job_id.present?
    IngestJobStatus.new( job: job )
  end

  def self.new_job_status( job_id: )
    return nil unless job_id.present?
    IngestJobStatus.new( job_id: job_id )
  end

  def initialize( job: nil, job_id: nil )
    if job.present?
      @job_status = JobStatus.find_or_create_job( job: job )
      @job_id = job.job_id
    elsif job_id.present?
      @job_status = JobStatus.find_by_job_id( job_id )
      @job_id = job_id
    else
      @job_status = NullJobStatus.instance
      @job_id = nil
    end
  end

  def did?( status: )
    return false if status.blank?
    job_status_status = job_status.status
    return false if job_status_status.blank?
    return false if JobStatus::STARTED == job_status_status
    return true if JobStatus::FINISHED == job_status_status
    return true if status == job_status_status
    status_index = ordered_job_status_list.index status
    job_status_index = ordered_job_status_list.index job_status_status
    # TODO: does this cover not found? i.e. does index return -1 when not found?
    return status_index <= job_status_index
  end
  alias doing? did?

  def did_add_file_to_file_set!
    update_status!( status: FINISHED_ADD_FILE_TO_FILE_SET )
  end

  def did_add_file_to_file_set?
    did?( status: FINISHED_ADD_FILE_TO_FILE_SET )
  end

  def did_characterize!
    update_status!( status: FINISHED_CHARACTERIZE )
  end

  def did_characterize?
    did?( status: FINISHED_CHARACTERIZE )
  end

  def did_create_derivatives!
    update_status!( status: FINISHED_CREATE_DERIVATIVES )
  end

  def did_create_derivatives?
    did?( status: FINISHED_CREATE_DERIVATIVES )
  end

  def did_created_file_set!
    update_status!( status: CREATED_FILE_SET )
  end

  def did_created_file_set?
    did?( status: CREATED_FILE_SET )
  end

  def did_delete_file!
    update_status!( status: DELETE_FILE )
  end

  def did_delete_file?
    did?( status: DELETE_FILE )
  end

  def did_file_ingest!
    update_status!( status: FINISHED_FILE_INGEST )
  end

  def did_file_ingest?
    did?( status: FINISHED_FILE_INGEST )
  end

  def did_log_starting!
    update_status!( status: FINISHED_LOG_STARTING )
  end

  def did_log_starting?
    did?( status: FINISHED_LOG_STARTING )
  end

  def did_notify!
    update_status!( status: FINISHED_NOTIFY )
  end

  def did_notify?
    did?( status: FINISHED_NOTIFY )
  end

  def did_validate_files!
    update_status!( status: FINISHED_VALIDATE_FILES )
  end

  def did_validate_files?
    did?( status: FINISHED_VALIDATE_FILES )
  end

  def did_versioning_service_create!
    update_status!( status: FINISHED_VALIDATE_FILES )
  end

  def did_versioning_service_create?
    did?( status: FINISHED_VALIDATE_FILES )
  end

  def did_upload_files!
    update_status!( status: FINISHED_UPLOAD_FILES )
  end

  def did_upload_files?
    did?( status: FINISHED_UPLOAD_FILES )
  end

  def ordered_job_status_list!
    @ordered_job_status_list ||= ordered_job_status_list_init
  end

  def uploading_files!( state: nil )
    state_serialize( state )
    update_status!( status: UPLOADING_FILES )
  end

  def uploading_files?
    UPLOADING_FILES_STATUS_LIST.include? status
  end

  private

    def ordered_job_status_list_init
      # TODO: if job_class_name ...
      ORDERED_JOB_STATUS_LIST
    end

end
