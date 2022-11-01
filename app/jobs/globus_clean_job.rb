# frozen_string_literal: true

class GlobusCleanJob < GlobusJob
  queue_as :globus_clean

  # @param [String] concern_id
  # @param [String, "Globus: "] log_prefix
  # @param [boolean, false] clean_download
  # @param [boolean, false] start_globus_copy_after_clean
  def perform( concern_id, log_prefix: "Globus: ", clean_download: false, start_globus_copy_after_clean: false )
    @globus_concern_id = concern_id
    @globus_log_prefix = log_prefix
    @globus_lock_file = nil
    @globus_job_quiet = false
    @globus_log_prefix = "#{log_prefix}globus_clean_job(#{concern_id})"

    ::Deepblue::LoggingHelper.debug "#{@globus_log_prefix} begin globus clean" unless @globus_job_quiet
    @target_download_dir = GlobusJob.target_download_dir @globus_concern_id
    @target_prep_dir     = GlobusJob.target_prep_dir( @globus_concern_id )
    @target_prep_dir_tmp = GlobusJob.target_prep_tmp_dir( @globus_concern_id )
    @globus_lock_file    = GlobusJob.lock_file @globus_concern_id

    while GlobusJob.files_prepping? concern_id do
      sleep 1.minute
      break if GlobusJob.error_file_exists? concern_id
    end

    unless globus_locked?
      GlobusJob.clean_dir( @target_prep_dir_tmp, delete_dir: true )
      GlobusJob.clean_dir( @target_prep_dir, delete_dir: true )
      globus_error_reset
    end

    if clean_download
      GlobusJob.clean_dir( @target_download_dir, delete_dir: true )
      GlobusJob.clean_file globus_ready_file
    end

    globus_email_rds( description: "cleaned work #{@globus_concern_id} directories" )
    Deepblue::LoggingHelper.debug "#{@globus_log_prefix} end globus clean" unless @globus_job_quiet

    GlobusCopyJob.perform_later( concern_id, log_prefix: log_prefix ) if start_globus_copy_after_clean
  end

end
