# frozen_string_literal: true

class IngestJobStatus

  INGEST_JOB_STATUS_DEBUG_VERBOSE = ::Deepblue::IngestIntegrationService.ingest_job_status_debug_verbose

  def self.null_ingest_job_status
    @@null_ingest_job_status ||= IngestJobStatus.new( job_status: NullJobStatus.instance )
  end

  CREATE_FILE_SET               = 'create_file_set'.freeze
  DELETE_FILE                   = 'delete_file'.freeze
  FINISHED_ADD_FILE_TO_FILE_SET = 'finished_add_file_to_file_set'.freeze
  FINISHED_ATTACH_FILE_TO_WORK  = 'finished_attach_file_to_work'.freeze
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
                              FINISHED_ATTACH_FILE_TO_WORK,
                              CREATE_FILE_SET,
                              FINISHED_VERSIONING_SERVICE_CREATE,
                              FINISHED_CHARACTERIZE,
                              FINISHED_CREATE_DERIVATIVES,
                              DELETE_FILE,
                              FINISHED_FILE_INGEST,
                              FINISHED_UPLOAD_FILES,
                              FINISHED_NOTIFY ].freeze

  UPLOADING_FILES_STATUS_LIST = [ UPLOADING_FILES,
                                  FINISHED_ATTACH_FILE_TO_WORK,
                                  CREATE_FILE_SET,
                                  FINISHED_VERSIONING_SERVICE_CREATE,
                                  FINISHED_CHARACTERIZE,
                                  FINISHED_CREATE_DERIVATIVES,
                                  DELETE_FILE,
                                  FINISHED_FILE_INGEST ]

  attr_accessor :job_id, :job_status, :ordered_job_status_list, :verbose

  delegate :add_message,
           :add_message!,
           :error,
           :error!,
           :finished?,
           :job_class,
           :parent_job_id,
           :message,
           :null_job_status?,
           :save!,
           :started?,
           :state,
           :state_deserialize,
           :state_serialize,
           :state_serialize!,
           :status,
           :status?,
           to: :job_status

  def self.find_job_status( job_id: nil, parent_job_id: nil, continue_job_chain_later: false, verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_id=#{job_id}",
                                           "parent_job_id=#{parent_job_id}",
                                           "continue_job_chain_later=#{continue_job_chain_later}",
                                           "verbose=#{verbose}",
                                           "" ] if INGEST_JOB_STATUS_DEBUG_VERBOSE
    # TODO: take continue_job_chain_later into account
    # if the parent_job_id exists, use it
    return new_job_status( job_id: parent_job_id, verbose: verbose ) if parent_job_id.present?
    new_job_status( job_id: job_id, verbose: verbose )
  end

  def self.find_or_create_job_started( job: nil, parent_job_id: nil, continue_job_chain_later: false, verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.job_id=#{job&.job_id}",
                                           "parent_job_id=#{parent_job_id}",
                                           "continue_job_chain_later=#{continue_job_chain_later}",
                                           "verbose=#{verbose}",
                                           "" ] if INGEST_JOB_STATUS_DEBUG_VERBOSE
    # TODO: take continue_job_chain_later into account
    return new_job_status( job_id: parent_job_id, verbose: verbose ) if parent_job_id.present?
    IngestJobStatus.new( job: job, verbose: verbose )
  end

  def self.new_job_status( job_id:, verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_id=#{job_id}",
                                           "verbose=#{verbose}",
                                           "" ] if INGEST_JOB_STATUS_DEBUG_VERBOSE
    return nil unless job_id.present?
    IngestJobStatus.new( job_id: job_id, verbose: verbose )
  end

  # order of instantiation: job_status, job, job_id
  def initialize( job_status: nil, job: nil, job_id: nil, verbose: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job.nil?=#{job.nil?}",
                                           "job&.job_id=#{job&.job_id}",
                                           "job_id=#{job_id}",
                                           "job_status=#{job_status}",
                                           "verbose=#{verbose}",
                                           "" ] if INGEST_JOB_STATUS_DEBUG_VERBOSE
    # TODO: error if job_status, job, and job_id are all blank?
    @verbose = verbose
    if job_status.present?
      @job_status = job_status
      @job_id = job_status.job_id
    elsif job.present?
      @job_status = JobStatus.find_or_create( job: job )
      @job_id = job.job_id
    elsif job_id.present?
      @job_status = JobStatus.find_by_job_id( job_id )
      @job_id = job_id
    else
      @job_status = NullJobStatus.instance
      @job_id = nil
    end
  end

  def add_error( error, sep: "\n" )
    add_message( error, sep: sep ) if verbose
    add_error( error, sep: sep )
    return self
  end

  def add_error!( error, sep: "\n" )
    add_message( error, sep: sep ) if verbose
    add_error!( error, sep: sep )
    return self
  end

  def did?( status )
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "status=#{status}",
    #                                        "job_status=#{job_status}",
    #                                        "job_status.job_id=#{job_status.job_id}",
    #                                        "job_status.job_class=#{job_status.job_class}",
    #                                        "job_status.status=#{job_status.status}",
    #                                        "" ] if INGEST_JOB_STATUS_DEBUG_VERBOSE
    return did_verbose( status,false ) if status.blank?
    return did_verbose( status,false ) if job_status.blank?
    current_status = job_status.status
    return did_verbose( status,false ) if current_status.blank?
    return did_verbose( status,true ) if status == current_status
    did_status_index = ordered_job_status_list_index status
    current_status_index = ordered_job_status_list_index current_status
    rv = did_status_index <= current_status_index
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "status=#{status}",
    #                                        "current_status=#{current_status}",
    #                                        "did_status_index=#{did_status_index}",
    #                                        "current_status_index=#{current_status_index}",
    #                                        "rv = did_status_index <= current_status_index=#{rv}",
    #                                        "" ] if INGEST_JOB_STATUS_DEBUG_VERBOSE
    return did_verbose( status,rv )
  end
  alias doing? did?

  def did_verbose( status, rv )
    add_message!( "did? #{status} returning #{rv}" ) if verbose
    return rv
  end

  def did_add_file_to_file_set!
    did! FINISHED_ADD_FILE_TO_FILE_SET
  end

  def did_add_file_to_file_set?
    did? FINISHED_ADD_FILE_TO_FILE_SET
  end

  def did_attach_file_to_work!
    did! FINISHED_ATTACH_FILE_TO_WORK
  end

  def did_attach_file_to_work?
    did? FINISHED_ATTACH_FILE_TO_WORK
  end

  def did_characterize!
    did! FINISHED_CHARACTERIZE
  end

  def did_characterize?
    did? FINISHED_CHARACTERIZE
  end

  def did_create_derivatives!
    did! FINISHED_CREATE_DERIVATIVES
  end

  def did_create_derivatives?
    did? FINISHED_CREATE_DERIVATIVES
  end

  def did_create_file_set!
    did! CREATE_FILE_SET
  end

  def did_create_file_set?
    did? CREATE_FILE_SET
  end

  def did_delete_file!
    did! DELETE_FILE
  end

  def did_delete_file?
    did? DELETE_FILE
  end

  def did_file_ingest!
    did! FINISHED_FILE_INGEST
  end

  def did_file_ingest?
    did? FINISHED_FILE_INGEST
  end

  def did_log_starting!
    did! FINISHED_LOG_STARTING
  end

  def did_log_starting?
    did? FINISHED_LOG_STARTING
  end

  def did_notify!
    did! FINISHED_NOTIFY
  end

  def did_notify?
    did? FINISHED_NOTIFY
  end

  def did_validate_files!
    did! FINISHED_VALIDATE_FILES
  end

  def did_validate_files?
    did? FINISHED_VALIDATE_FILES
  end

  def did_versioning_service_create!
    did! FINISHED_VALIDATE_FILES
  end

  def did_versioning_service_create?
    did? FINISHED_VALIDATE_FILES
  end

  def did_upload_files!
    did! FINISHED_UPLOAD_FILES
  end

  def did_upload_files?
    did? FINISHED_UPLOAD_FILES
  end

  def finished!( message: nil )
    job_status.finished!( message: message )
    add_message! "status changed to: #{JobStatus::FINISHED}" if verbose
  end

  def reload
    job_status.reload
    add_message! "reload" if verbose
  end

  def ordered_job_status_list
    @ordered_job_status_list ||= ordered_job_status_list_init
  end

  def started!( message: nil )
    job_status.started!( message: message )
    add_message! "status changed to: #{JobStatus::STARTED}" if verbose
  end

  def status!( status )
    job_status.status = status
    add_message "status changed to: #{status}" if verbose
    job_status.save!
  end
  alias did! status!

  def uploading_files!( state: nil )
    state_serialize( state )
    status! UPLOADING_FILES
  end

  def uploading_files?
    UPLOADING_FILES_STATUS_LIST.include? status
  end

  private

    def ordered_job_status_list_init
      # TODO: if job_class ...
      ORDERED_JOB_STATUS_LIST
    end

    def ordered_job_status_list_index( status )
      rv = case status
           when JobStatus::STARTED
             -1
           when JobStatus::FINISHED
             ordered_job_status_list.size
           else
             ordered_job_status_list.index status
           end
      rv = -2 if rv.blank?
      return rv
    end

end
