# frozen_string_literal: true

module Hyrax

  class DataSetsController < DeepblueController

    PARAMS_KEY = 'data_set'

    include Deepblue::WorksControllerBehavior

    self.curation_concern_type = ::DataSet
    self.show_presenter = Hyrax::DataSetPresenter

    before_action :assign_date_coverage,         only: %i[create update]
    before_action :assign_admin_set,             only: %i[create update]
    before_action :email_rds_destroy,            only: [:destroy]
    before_action :provenance_log_destroy,       only: [:destroy]
    before_action :provenance_log_update_before, only: [:update]
    before_action :visiblity_changed,            only: [:update]
    before_action :prepare_permissions,           only: [:show]

    after_action :email_rds_create,                only: [:create]
    after_action :provenance_log_create,           only: [:create]
    after_action :visibility_changed_update,       only: [:update]
    after_action :provenance_log_update_after,     only: [:update]
    after_action :reset_permissions,               only: [:show]

    protect_from_forgery with: :null_session,    only: [:display_provenance_log]
    protect_from_forgery with: :null_session,    only: [:globus_add_email]
    protect_from_forgery with: :null_session,    only: [:globus_download]
    protect_from_forgery with: :null_session,    only: [:globus_download_add_email]
    protect_from_forgery with: :null_session,    only: [:globus_download_notify_me]
    protect_from_forgery with: :null_session,    only: [:zip_download]

    attr_accessor :user_email_one, :user_email_two

    attr_accessor :provenance_log_entries

    # These methods (prepare_permissions, and reset_permissions) are used so that
    # when viewing a tombstoned work, and the user is not admin, the user 
    # will be able to see the metadata.
    def prepare_permissions
      if current_ability.admin?
      else
        # Need to add admin group to current_ability
        # or presenter will not be accessible.
        current_ability.user_groups << "admin"
        if presenter.tombstone.present? 
        else
          current_ability.user_groups.delete("admin")
        end
      end
    end

    def reset_permissions
      current_ability.user_groups.delete("admin")
    end


    ## box integration

    def box_create_dir_and_add_collaborator
      return nil unless DeepBlueDocs::Application.config.box_integration_enabled
      user_email = Deepblue::EmailHelper.user_email_from( current_user )
      BoxHelper.create_dir_and_add_collaborator( curation_concern.id, user_email: user_email )
    end

    def box_link
      return nil unless DeepBlueDocs::Application.config.box_integration_enabled
      BoxHelper.box_link( curation_concern.id )
    end

    def box_work_created
      box_create_dir_and_add_collaborator
    end

    ## end box integration

    ## date_coverage

    # Create EDTF::Interval from form parameters
    # Replace the date coverage parameter prior with serialization of EDTF::Interval
    def assign_date_coverage
      cov_interval = Dataset::DateCoverageService.params_to_interval params
      params[PARAMS_KEY]['date_coverage'] = cov_interval ? cov_interval.edtf : ""
    end

    def assign_admin_set
      admin_sets = Hyrax::AdminSetService.new(self).search_results(:deposit)
      admin_sets.each do |admin_set|
        if admin_set.id != "admin_set/default"
          params[PARAMS_KEY]['admin_set_id'] = admin_set.id
        end
      end
    end

    # end date_coverage

    ## DOI

    def doi
      doi_mint
      respond_to do |wants|
        wants.html { redirect_to [main_app, curation_concern] }
        wants.json do
          render :show,
                 status: :ok,
                 location: polymorphic_path([main_app, curation_concern])
        end
      end
    end

    def doi_minting_enabled?
      ::Deepblue::DoiBehavior::DOI_MINTING_ENABLED
    end

    def doi_mint
      # Do not mint doi if
      #   one already exists
      #   work file_set count is 0.
      if curation_concern.doi_pending?
        flash[:notice] = MsgHelper.t( 'data_set.doi_is_being_minted' )
      elsif curation_concern.doi_minted?
        flash[:notice] = MsgHelper.t( 'data_set.doi_already_exists' )
      elsif curation_concern.file_sets.count < 1
        flash[:notice] = MsgHelper.t( 'data_set.doi_requires_work_with_files' )
      elsif ( curation_concern.depositor != current_user.email ) && !current_ability.admin?
        flash[:notice] = MsgHelper.t( 'data_set.doi_user_without_access' )
      elsif curation_concern.doi_mint( current_user: current_user, event_note: 'DataSetsController' )
        flash[:notice] = MsgHelper.t( 'data_set.doi_minting_started' )
      end
    end

    # def mint_doi_enabled?
    #   true
    # end

    ## end DOI

    ## email

    def email_rds_create
      curation_concern.email_rds_create( current_user: current_user,
                                         event_note: "deposited by #{curation_concern.depositor}" )
    end

    def email_rds_destroy
      curation_concern.email_rds_destroy( current_user: current_user )
    end

    def email_rds_publish
      curation_concern.email_rds_publish( current_user: current_user )
    end

    def email_rds_unpublish
      curation_concern.email_rds_unpublish( current_user: current_user )
    end

    ## end email

    ## Globus

    def globus_add_email
      if user_signed_in?
        user_email = Deepblue::EmailHelper.user_email_from( current_user )
        globus_copy_job( user_email: user_email, delay_per_file_seconds: 0 )
        flash_and_go_back globus_files_prepping_msg( user_email: user_email )
      elsif params[:user_email_one].present? || params[:user_email_two].present?
        user_email_one = params[:user_email_one].present? ? params[:user_email_one].strip : ''
        user_email_two = params[:user_email_two].present? ? params[:user_email_two].strip : ''
        # if user_email_one === user_email_two
        if user_email_one == user_email_two
          globus_copy_job( user_email: user_email_one, delay_per_file_seconds: 0 )
          flash_and_redirect_to_main_cc globus_files_prepping_msg( user_email: user_email_one )
        else
          flash.now[:error] = emails_did_not_match_msg( user_email_one, user_email_two )
          render 'globus_download_add_email_form'
        end
      else
        flash_and_redirect_to_main_cc globus_status_msg
      end
    end

    def globus_clean_download
      ::GlobusCleanJob.perform_later( curation_concern.id, clean_download: true )
      globus_ui_delay
      dirs = []
      dirs << ::GlobusJob.target_download_dir( curation_concern.id )
      dirs << ::GlobusJob.target_prep_dir( curation_concern.id, prefix: nil )
      dirs << ::GlobusJob.target_prep_tmp_dir( curation_concern.id, prefix: nil )
      flash_and_redirect_to_main_cc globus_clean_msg( dirs )
    end

    def globus_clean_prep
      ::GlobusCleanJob.perform_later( curation_concern.id, clean_download: false )
      globus_ui_delay
    end

    def globus_complete?
      ::GlobusJob.copy_complete? curation_concern.id
    end

    def globus_copy_job( user_email: nil,
                         delay_per_file_seconds: DeepBlueDocs::Application.config.globus_debug_delay_per_file_copy_job_seconds )

      ::GlobusCopyJob.perform_later( curation_concern.id,
                                     user_email: user_email,
                                     delay_per_file_seconds: delay_per_file_seconds )
      globus_ui_delay
    end

    def globus_download
      if globus_complete?
        flash_and_redirect_to_main_cc globus_files_available_here
      else
        user_email = Deepblue::EmailHelper.user_email_from( current_user, user_signed_in: user_signed_in? )
        msg = if globus_prepping?
                globus_files_prepping_msg( user_email: user_email )
              else
                globus_file_prep_started_msg( user_email: user_email )
              end
        if user_signed_in?
          globus_copy_job( user_email: user_email )
          flash_and_redirect_to_main_cc msg
        else
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

    def globus_download_enabled?
      DeepBlueDocs::Application.config.globus_enabled
    end

    def globus_download_notify_me
      if user_signed_in?
        user_email = Deepblue::EmailHelper.user_email_from( current_user )
        globus_copy_job( user_email: user_email )
        flash_and_go_back globus_file_prep_started_msg( user_email: user_email )
      elsif params[:user_email_one].present? || params[:user_email_two].present?
        user_email_one = params[:user_email_one].present? ? params[:user_email_one].strip : ''
        user_email_two = params[:user_email_two].present? ? params[:user_email_two].strip : ''
        # if user_email_one === user_email_two
        if user_email_one == user_email_two
          globus_copy_job( user_email: user_email_one )
          flash_and_redirect_to_main_cc globus_file_prep_started_msg( user_email: user_email_one )
        else
          # flash_and_go_back emails_did_not_match_msg( user_email_one, user_email_two )
          flash.now[:error] = emails_did_not_match_msg( user_email_one, user_email_two )
          render 'globus_download_notify_me_form'
        end
      else
        globus_copy_job( user_email: nil )
        flash_and_redirect_to_main_cc globus_file_prep_started_msg
      end
    end

    def globus_enabled?
      DeepBlueDocs::Application.config.globus_enabled
    end

    def globus_last_error_msg
      ::GlobusJob.error_file_contents curation_concern.id
    end

    def globus_prepping?
      ::GlobusJob.files_prepping? curation_concern.id
    end

    def globus_ui_delay( delay_seconds: DeepBlueDocs::Application.config.globus_after_copy_job_ui_delay_seconds )
      sleep delay_seconds if delay_seconds.positive?
    end

    def globus_url
      ::GlobusJob.external_url curation_concern.id
    end

    ## end Globus

    ## Provenance log

    def provenance_log_create
      curation_concern.provenance_create( current_user: current_user, event_note: 'DataSetsController' )
    end

    def provenance_log_destroy
      curation_concern.provenance_destroy( current_user: current_user, event_note: 'DataSetsController' )
    end

    def provenance_log_publish
      curation_concern.provenance_publish( current_user: current_user, event_note: 'DataSetsController' )
    end

    def provenance_log_unpublish
      curation_concern.provenance_unpublish( current_user: current_user, event_note: 'DataSetsController' )
    end

    def provenance_log_update_after
      curation_concern.provenance_log_update_after( current_user: current_user,
                                                    # event_note: 'DataSetsController.provenance_log_update_after',
                                                    update_attr_key_values: @update_attr_key_values )
    end

    def provenance_log_update_before
      @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
    end

    ## end Provenance log

    ## display provenance log

    def display_provenance_log
      # load provenance log for this work
      file_path = Deepblue::ProvenancePath.path_for_reference( curation_concern.id )
      Deepblue::LoggingHelper.bold_debug [ "DataSetsController", "display_provenance_log", file_path ]
      Deepblue::ProvenanceLogService.entries( curation_concern.id, refresh: true )
      # continue on to normal display
      redirect_to [main_app, curation_concern]
    end

    def display_provenance_log_enabled?
      true
    end

    def provenance_log_entries_present?
      provenance_log_entries.present?
    end

    ## end display provenance log


    ## Tombstone

    def tombstone
      epitaph = params[:tombstone]
      success = curation_concern.entomb!( epitaph, current_user )
      msg = if success
              MsgHelper.t( 'data_set.tombstone_notice', title: curation_concern.title.first.to_s, reason: epitaph.to_s )
            else
              "#{curation_concern.title.first} is already tombstoned."
            end
      redirect_to dashboard_works_path, notice: msg
    end

    def tombstone_enabled?
      true
    end

    ## End Tombstone

    ## visibility / publish

    def visiblity_changed
      if visibility_to_private?
        mark_as_set_to_private
      elsif visibility_to_public?
        mark_as_set_to_public
      end
    end

    def visibility_changed_update
      if curation_concern.private? && @visibility_changed_to_private
        provenance_log_unpublish
        email_rds_unpublish
      elsif curation_concern.public? && @visibility_changed_to_public
        provenance_log_publish
        email_rds_publish
      end
    end

    def visibility_to_private?
      return false if curation_concern.private?
      params[PARAMS_KEY]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    def visibility_to_public?
      return false if curation_concern.public?
      params[PARAMS_KEY]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    def mark_as_set_to_private
      @visibility_changed_to_public = false
      @visibility_changed_to_private = true
    end

    def mark_as_set_to_public
      @visibility_changed_to_public = true
      @visibility_changed_to_private = false
    end

    ## end visibility / publish

    ## begin zip download operations

    def zip_download
      require 'zip'
      require 'tempfile'

      tmp_dir = ENV['TMPDIR'] || "/tmp"
      tmp_dir = Pathname.new tmp_dir
      # Deepblue::LoggingHelper.debug "Download Zip begin tmp_dir #{tmp_dir}"
      Deepblue::LoggingHelper.bold_debug [ "zip_download begin", "tmp_dir=#{tmp_dir}" ]
      target_dir = target_dir_name_id( tmp_dir, curation_concern.id )
      # Deepblue::LoggingHelper.debug "Download Zip begin copy to folder #{target_dir}"
      Deepblue::LoggingHelper.bold_debug [ "zip_download", "target_dir=#{target_dir}" ]
      Dir.mkdir( target_dir ) unless Dir.exist?( target_dir )
      target_zipfile = target_dir_name_id( target_dir, curation_concern.id, ".zip" )
      # Deepblue::LoggingHelper.debug "Download Zip begin copy to target_zipfile #{target_zipfile}"
      Deepblue::LoggingHelper.bold_debug [ "zip_download", "target_zipfile=#{target_zipfile}" ]
      File.delete target_zipfile if File.exist? target_zipfile
      # clean the zip directory if necessary, since the zip structure is currently flat, only
      # have to clean files in the target folder
      files = Dir.glob( (target_dir.join '*').to_s)
      Deepblue::LoggingHelper.bold_debug files, label: "zip_download files to delete:"
      files.each do |file|
        File.delete file if File.exist? file
      end
      Deepblue::LoggingHelper.debug "Download Zip begin copy to folder #{target_dir}"
      Deepblue::LoggingHelper.bold_debug [ "zip_download", "begin copy target_dir=#{target_dir}" ]
      Zip::File.open(target_zipfile.to_s, Zip::File::CREATE ) do |zipfile|
        metadata_filename = curation_concern.metadata_report( dir: target_dir )
        zipfile.add( metadata_filename.basename, metadata_filename )
        export_file_sets_to( target_dir: target_dir, log_prefix: "Zip: " ) do |target_file_name, target_file|
          zipfile.add( target_file_name, target_file )
        end
      end
      # Deepblue::LoggingHelper.debug "Download Zip copy complete to folder #{target_dir}"
      Deepblue::LoggingHelper.bold_debug [ "zip_download", "download complete target_dir=#{target_dir}" ]
      send_file target_zipfile.to_s
    end

    def zip_download_enabled?
      true
    end

    # end zip download operations

    # # Create EDTF::Interval from form parameters
    # # Replace the date coverage parameter prior with serialization of EDTF::Interval
    # def assign_date_coverage
    #   ##cov_interval = Umrdr::DateCoverageService.params_to_interval params
    #   ##params['generic_work']['date_coverage'] = cov_interval ? [cov_interval.edtf] : []
    # end
    #
    # def check_recent_uploads
    #   if params[:uploads_since]
    #     begin
    #       @recent_uploads = [];
    #       uploads_since = Time.at(params[:uploads_since].to_i / 1000.0)
    #       presenter.file_set_presenters.reverse_each do |file_set|
    #         date_uploaded = get_date_uploaded_from_solr(file_set)
    #         if date_uploaded.nil? or date_uploaded < uploads_since
    #           break
    #         end
    #         @recent_uploads.unshift file_set
    #       end
    #     rescue Exception => e
    #       Rails.logger.info "Something happened in check_recent_uploads: #{params[:uploads_since]} : #{e.message}"
    #     end
    #   end
    # end

    protected

      def emails_did_not_match_msg( _user_email_one, _user_email_two )
        "Emails did not match" # + ": '#{user_email_one}' != '#{user_email_two}'"
      end

      def export_file_sets_to( target_dir:,
                               log_prefix: "",
                               do_export_predicate: ->(_target_file_name, _target_file) { true },
                               quiet: false,
                               &block )
        file_sets = curation_concern.file_sets
        Deepblue::ExportFilesHelper.export_file_sets( target_dir: target_dir,
                                                      file_sets: file_sets,
                                                      log_prefix: log_prefix,
                                                      do_export_predicate: do_export_predicate,
                                                      quiet: quiet,
                                                      &block )
      end

      def flash_and_go_back( msg )
        Deepblue::LoggingHelper.debug msg
        redirect_to :back, notice: msg
      end

      def flash_error_and_go_back( msg )
        Deepblue::LoggingHelper.debug msg
        redirect_to :back, error: msg
      end

      def flash_and_redirect_to_main_cc( msg )
        Deepblue::LoggingHelper.debug msg
        redirect_to [main_app, curation_concern], notice: msg
      end

      def globus_clean_msg( dir )
        dirs = dir.join( MsgHelper.t( 'data_set.globus_clean_join_html' ) )
        rv = MsgHelper.t( 'data_set.globus_clean', dirs: dirs )
        return rv
      end

      def globus_file_prep_started_msg( user_email: nil )
        MsgHelper.t( 'data_set.globus_file_prep_started',
                     when_available: globus_files_when_available( user_email: user_email ) )
      end

      def globus_files_prepping_msg( user_email: nil )
        MsgHelper.t( 'data_set.globus_files_prepping',
                     when_available: globus_files_when_available( user_email: user_email ) )
      end

      def globus_files_when_available( user_email: nil )
        if user_email.nil?
          MsgHelper.t( 'data_set.globus_files_when_available' )
        else
          MsgHelper.t( 'data_set.globus_files_when_available_email', user_email: user_email )
        end
      end

      def globus_files_available_here
        MsgHelper.t( 'data_set.globus_files_available_here', globus_url: globus_url.to_s )
      end

      def globus_status_msg( user_email: nil )
        msg = if globus_complete?
                globus_files_available_here
              elsif globus_prepping?
                globus_files_prepping_msg( user_email: user_email )
              else
                globus_file_prep_started_msg( user_email: user_email )
              end
        msg
      end

      def show_presenter
        Hyrax::DataSetPresenter
      end

    private

      def get_date_uploaded_from_solr(file_set)
        field = file_set.solr_document[Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)]
        return if field.blank?
        begin
          Time.parse(field)
        rescue
          Rails.logger.info "Unable to parse date: #{field.first.inspect} for #{self['id']}"
        end
      end

      def target_dir_name_id( dir, id, ext = '' )
        dir.join "#{DeepBlueDocs::Application.config.base_file_name}#{id}#{ext}"
      end

  end

end
