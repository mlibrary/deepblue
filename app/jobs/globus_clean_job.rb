# frozen_string_literal: true

class GlobusCleanJob < GlobusJob
  queue_as :globus_clean

  # @param [String] concern_id
  # @param [String, "Globus: "] log_prefix
  # @param [boolean, false] clean_download
  def perform( concern_id, log_prefix: "Globus: ", clean_download: false )
    @globus_concern_id = concern_id
    @globus_log_prefix = log_prefix
    @globus_lock_file = nil
    @globus_job_quiet = false
    @globus_log_prefix = "#{log_prefix}globus_clean_job(#{concern_id})"

    Deepblue::LoggingHelper.debug "#{@globus_log_prefix} begin globus clean" unless @globus_job_quiet
    @target_download_dir = GlobusJob.target_download_dir @globus_concern_id
    @target_prep_dir     = GlobusJob.target_prep_dir( @globus_concern_id, prefix: nil )
    @target_prep_dir_tmp = GlobusJob.target_prep_tmp_dir( @globus_concern_id, prefix: nil )
    @globus_lock_file    = GlobusJob.lock_file @globus_concern_id

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
  end

end
