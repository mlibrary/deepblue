# frozen_string_literal: true

class DataDenWorkTombstoneJob < ::Deepblue::DeepblueJob

  mattr_accessor :data_den_work_tombstone_job_debug_verbose, default: false

  #def perform( work_id:, current_user: nil, job_delay: 0, debug_verbose: false )
  def perform( *args )
    args = [{}] if args.nil? || args[0].nil?
    work_id = args[0][:work_id]
    current_user = args[0][:current_user]
    job_delay = args[0][:job_delay]
    job_delay ||= 0
    debug_verbose = args[0][:debug_verbose]
    debug_verbose ||= data_den_work_tombstone_job_debug_verbose
    debug_verbose = debug_verbose || data_den_work_tombstone_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                         "work_id=#{work_id}",
                                         "current_user=#{current_user}",
                                         "job_delay=#{job_delay}" ] if debug_verbose
    initialize_with( id: work_id, debug_verbose: debug_verbose )
    log( event: WorkTombstoneJob.class.name )
    if 0 < job_delay
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work_id=#{work_id}",
                                           "current_user=#{current_user}",
                                           "sleeping #{job_delay} seconds"] if debug_verbose
      sleep job_delay
    end
    work = ::PersistHelper.find( work_id )
    ::DataDenExportService.tombstone_work( cc: work, msg_handler: msg_handler )
    job_finished
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "job_status.status=#{job_status.status}",
                                           "job_status.message=#{job_status.message}",
                                           "" ] if debug_verbose
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e,
                         args: { work_id: work_id,
                                 current_user: current_user,
                                 job_delay: job_delay } )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise e
  end

end
