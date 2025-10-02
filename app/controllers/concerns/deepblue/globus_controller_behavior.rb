# frozen_string_literal: true

module Deepblue

  module GlobusControllerBehavior

    mattr_accessor :globus_controller_behavior_debug_verbose, default: true
    mattr_accessor :globus_controller_behavior_presenter_debug_verbose, default: false

    def file_sys_export_record( id: )
      ::Deepblue::GlobusService.file_sys_export_record( id: id )
    end

    def globus_add_email
      cc_id ||= id
      if user_signed_in?
        user_email = ::Deepblue::EmailHelper.user_email_from( current_user )
        globus_copy_job( cc_id: cc_id, user_email: user_email, delay_per_file_seconds: 0 )
        flash_and_go_back globus_files_prepping_msg( user_email: user_email )
        # msg = globus_files_prepping_msg( user_email: user_email )
        # redirect_to [main_app, curation_concern], notice: msg
      elsif params[:user_email_one].present? || params[:user_email_two].present?
        user_email_one = params[:user_email_one].present? ? params[:user_email_one].strip : ''
        user_email_two = params[:user_email_two].present? ? params[:user_email_two].strip : ''
        # if user_email_one === user_email_two
        if user_email_one == user_email_two
          globus_copy_job( cc_id: cc_id, user_email: user_email_one, delay_per_file_seconds: 0 )
          flash_and_redirect_to_main_cc globus_files_prepping_msg( user_email: user_email_one )
        else
          flash.now[:error] = emails_did_not_match_msg( user_email_one, user_email_two )
          render 'globus_download_add_email_form'
        end
      else
        flash_and_redirect_to_main_cc globus_status_msg
      end
    end

    def globus_always_available?
      ::Deepblue::GlobusService.globus_always_available?
    end

    def globus_base_url
      ::Deepblue::GlobusService.globus_base_url
    end

    def globus_bounce_external_link_off_server?
      ::Deepblue::GlobusService.globus_bounce_external_link_off_server?
    end

    def globus_clean_download( cc_id: nil )
      cc_id ||= id
      ::GlobusCleanJob.perform_later( cc_id, clean_download: true )
      dirs = []
      dirs << ::Deepblue::GlobusService.globus_target_download_dir( cc_id )
      dirs << ::Deepblue::GlobusService.globus_target_prep_dir( cc_id )
      dirs << ::Deepblue::GlobusService.globus_target_prep_tmp_dir( cc_id )
      globus_ui_delay
      return dirs
    end

    def globus_clean_prep( cc_id: nil )
      cc_id ||= id
      ::GlobusCleanJob.perform_later( cc_id, clean_download: false )
      globus_ui_delay
    end

    # def globus_clean_download_and_redirect( cc_id: nil )
    #   cc_id ||= id
    #   dirs = globus_clean_download( cc_id: id )
    #   flash_and_redirect_to_main_cc globus_clean_msg( dirs )
    # end

    # def globus_complete?( cc_id: nil )
    #   cc_id ||= id
    #   ::Deepblue::GlobusService.globus_copy_complete? cc_id
    # end

    def globus_controller_behavior_debug_verbose
      ::Deepblue::GlobusControllerBehavior.globus_controller_behavior_debug_verbose
    end

    def globus_controller_behavior_presenter_debug_verbose
      ::Deepblue::GlobusControllerBehavior.globus_controller_behavior_presenter_debug_verbose
    end

    def globus_copy_complete?( cc_id )
      ::Deepblue::GlobusService.globus_copy_complete?( cc_id )
    end

    def globus_copy_job( cc_id: nil,
                         user_email: nil,
                         delay_per_file_seconds: ::Deepblue::GlobusIntegrationService.globus_debug_delay_per_file_copy_job_seconds )

      cc_id ||= id
      #::GlobusCopyJob.perform_later( cc_id,
      ::GlobusCopyJob.perform_later( concern_id: cc_id,
                                     user_email: user_email,
                                     delay_per_file_seconds: delay_per_file_seconds )
      globus_ui_delay
    end

    # def globus_data_den?
    #   ::Deepblue::GlobusIntegrationService.globus_use_data_den
    # end

    def globus_data_den_files_available?( cc_id )
      ::Deepblue::GlobusService.globus_data_den_files_available?( cc_id )
    end

    def globus_data_den_published_dir( cc_id )
      ::Deepblue::GlobusService.globus_data_den_published_dir( cc_id )
    end

    def globus_debug_verbose?
      ::Deepblue::GlobusService.globus_debug_verbose?
    end

    def globus_download
      cc_id = params[:id]
      if globus_copy_complete?( cc_id ) # curation_concern.id
        flash_and_redirect_to_main_cc globus_files_available_here
      else
        user_email = ::Deepblue::EmailHelper.user_email_from( current_user, user_signed_in: user_signed_in? )
        msg = if globus_prepping?( cc_id )
                globus_files_prepping_msg( user_email: user_email )
              else
                globus_file_prep_started_msg( user_email: user_email )
              end
        if user_signed_in?
          globus_copy_job( cc_id: cc_id, user_email: user_email )
          flash_and_redirect_to_main_cc msg
        else
          globus_copy_job( cc_id: cc_id, user_email: nil )
          render 'globus_download_notify_me_form'
        end
      end
    end

    def globus_download_add_email
      if user_signed_in?
        globus_add_email
      else
        render 'globus_download_add_email_form'
      end
    end

    def globus_download_dir_du( cc_id: )
      ::Deepblue::GlobusService.globus_download_dir_du( cc_id: cc_id )
    end

    def globus_download_enabled?
      ::Deepblue::GlobusService.globus_download_enabled?
    end

    def globus_download_notify_me
      cc_id = params[:id]
      if user_signed_in?
        user_email = ::Deepblue::EmailHelper.user_email_from( current_user )
        globus_copy_job( cc_id: cc_id, user_email: user_email )
        flash_and_go_back globus_file_prep_started_msg( user_email: user_email )
      elsif params[:user_email_one].present? || params[:user_email_two].present?
        user_email_one = params[:user_email_one].present? ? params[:user_email_one].strip : ''
        user_email_two = params[:user_email_two].present? ? params[:user_email_two].strip : ''
        # if user_email_one === user_email_two
        if user_email_one == user_email_two
          globus_copy_job( cc_id: cc_id, user_email: user_email_one )
          flash_and_redirect_to_main_cc globus_file_prep_started_msg( user_email: user_email_one )
        else
          # flash_and_go_back emails_did_not_match_msg( user_email_one, user_email_two )
          flash.now[:error] = emails_did_not_match_msg( user_email_one, user_email_two )
          render 'globus_download_notify_me_form'
        end
      else
        globus_copy_job( cc_id: cc_id, user_email: nil )
        flash_and_redirect_to_main_cc globus_file_prep_started_msg
      end
    end

    def globus_download_redirect
      redirect_to ::Deepblue::GlobusService.globus_external_url( params[:id] )
    end

    def globus_enabled?
      ::Deepblue::GlobusService.globus_enabled?
    end

    def globus_error_file_exists?( cc_id )
      ::Deepblue::GlobusService.globus_error_file_exists? cc_id
    end

    def globus_export?
      ::Deepblue::GlobusIntegrationService.globus_export
    end

    def globus_external_url( cc_id, admin_only: false )
      ::Deepblue::GlobusService.globus_external_url( cc_id, admin_only: admin_only )
    end

    def globus_files_available?( cc_id )
      ::Deepblue::GlobusService.globus_files_available? cc_id
    end

    def globus_files_prepping?( cc_id )
      ::Deepblue::GlobusService.globus_files_prepping? cc_id
    end

    def globus_files_target_file_name( id, data_den: )
     ::Deepblue::GlobusService.globus_files_target_file_name( id, data_den: data_den )
    end

    def globus_last_error_msg( cc_id )
      ::Deepblue::GlobusService.globus_error_file_contents cc_id
    end

    def globus_locked?( cc_id )
      ::Deepblue::GlobusService.globus_locked?( cc_id )
    end

    def globus_prep_dir_du( cc_id )
      ::Deepblue::GlobusService.globus_prep_dir_du( cc_id )
    end

    def globus_prep_tmp_dir_du( cc_id )
      ::Deepblue::GlobusService.globus_prep_tmp_dir_du( cc_id )
    end

    def globus_prepping?( cc_id )
      ::Deepblue::GlobusService.globus_files_prepping? cc_id
    end

    def globus_ui_delay( delay_seconds: ::Deepblue::GlobusIntegrationService.globus_after_copy_job_ui_delay_seconds )
      sleep delay_seconds if delay_seconds.positive?
    end

    def globus_use_data_den?
      ::Deepblue::GlobusService.globus_use_data_den?
    end

    def globus_url( cc_id, admin_only: false )
      ::Deepblue::GlobusService.globus_external_url( cc_id, admin_only: admin_only )
    end

  end

end
