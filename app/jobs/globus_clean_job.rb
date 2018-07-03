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

    globus_clean_job_email_rds( description: "cleaned Globus directories", log_provenance: true )
    Deepblue::LoggingHelper.debug "#{@globus_log_prefix} end globus clean" unless @globus_job_quiet
  end

  def globus_clean_job_email_rds( curation_concern: nil, description: '', log_provenance: false )
    curation_concern = ActiveFedora::Base.find @globus_concern_id if curation_concern.nil?
    location = MsgHelper.work_location( curation_concern: curation_concern )
    title    = MsgHelper.title( curation_concern )
    creator  = MsgHelper.creator( curation_concern )
    msg      = "#{title} (#{location}) by + #{creator} with #{curation_concern.visibility} #{description}"
    PROV_LOGGER.info( msg ) if log_provenance
    Deepblue::EmailHelper.send_email_globus_clean_job_complete( to: Deepblue::EmailHelper.notification_email, body: msg ) ## TODO
  end

end
