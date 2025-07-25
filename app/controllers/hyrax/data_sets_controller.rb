# frozen_string_literal: true

require 'irus_analytics/controller/analytics_behaviour'

module Hyrax

  class DataSetsController < DeepblueController

    PARAMS_KEY = 'data_set' unless const_defined? :PARAMS_KEY

    mattr_accessor :data_sets_controller_debug_verbose, default: Rails.configuration.data_sets_controller_debug_verbose

    include ActionView::Helpers::TextHelper
    include ::Deepblue::WorksControllerBehavior
    include ::Deepblue::ZipDownloadControllerBehavior
    include IrusAnalytics::Controller::AnalyticsBehaviour
    include ::Deepblue::GlobusControllerBehavior

    self.curation_concern_type = ::DataSet
    self.show_presenter = Hyrax::DataSetPresenter

    before_action :assign_date_coverage,         only: %i[create update]
    before_action :assign_depositor_creator,     only: %i[create update]
    before_action :assign_admin_set,             only: %i[create update]
    # before_action :assign_ticket_status,         only: %i[create update]
    before_action :prepare_tombstone_permissions,only: [:show]
    before_action :provenance_log_update_before, only: [:update]
    before_action :single_use_link_debug,        only: [:single_use_link]
    before_action :visiblity_changed,            only: [:update]
    before_action :workflow_destroy,             only: [:destroy]

    after_action :provenance_log_update_after,   only: [:update]
    after_action :reset_tombstone_permissions,   only: [:show]
    after_action :visibility_changed_update,     only: [:update]
    after_action :workflow_create,               only: [:create]
    after_action :workflow_update_after,         only: [:update]

    before_action :ensure_ticket,                only: %i[show update]
    # after_action :ensure_ticket,                 only: [:create]

    after_action :report_irus_analytics_request, only: %i[globus_download_redirect zip_download]
    after_action :report_irus_analytics_investigation, only: %i[show]

    protect_from_forgery with: :null_session,    only: [:analytics_subscribe]
    protect_from_forgery with: :null_session,    only: [:analytics_unsubscribe]
    protect_from_forgery with: :null_session,    only: [:create_anonymous_link]
    protect_from_forgery with: :null_session,    only: [:create_service_request]
    protect_from_forgery with: :null_session,    only: [:create_single_use_link]
    protect_from_forgery with: :null_session,    only: [:display_provenance_log]
    protect_from_forgery with: :null_session,    only: [:ensure_doi_minted]
    protect_from_forgery with: :null_session,    only: [:globus_add_email]
    protect_from_forgery with: :null_session,    only: [:globus_download]
    protect_from_forgery with: :null_session,    only: [:globus_download_add_email]
    protect_from_forgery with: :null_session,    only: [:globus_download_notify_me]
    protect_from_forgery with: :null_session,    only: [:globus_download_redirect]
    protect_from_forgery with: :null_session,    only: [:ingest_append_script_generate]
    protect_from_forgery with: :null_session,    only: [:ingest_append_script_prep]
    protect_from_forgery with: :null_session,    only: [:ingest_append_script_run_job]
    protect_from_forgery with: :null_session,    only: [:aptrust_upload]
    protect_from_forgery with: :null_session,    only: [:aptrust_verify]
    protect_from_forgery with: :null_session,    only: [:work_find_and_fix]
    protect_from_forgery with: :null_session,    only: [:zip_download]

    attr_accessor :user_email_one, :user_email_two

    attr_accessor :provenance_log_entries

    attr_accessor :read_me_file_set

    attr_accessor :tombstone_permissions_hack
    @tombstone_permissions_hack = false

    # These methods (prepare_permissions, and reset_permissions) are used so that
    # when viewing a tombstoned work, and the user is not admin, the user 
    # will be able to see the metadata.
    def prepare_tombstone_permissions
      unless current_ability.admin?
        # Need to add admin group to current_ability
        # or presenter will not be accessible.
        current_ability.user_groups << "admin"
        if presenter&.tombstone.present?
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "setting @tombstone_permissions_hack true",
                                                 "" ] if data_sets_controller_debug_verbose
          @tombstone_permissions_hack = true
        else
          current_ability.user_groups.delete("admin")
        end
      end
    end

    def reset_tombstone_permissions
      if @tombstone_permissions_hack
        current_ability.user_groups.delete("admin")
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "setting @tombstone_permissions_hack false",
                                               "" ] if data_sets_controller_debug_verbose
        @tombstone_permissions_hack = false
      end
    end

    def tombstone_permissions_hack?
      @tombstone_permissions_hack
    end

    def edit
      # To have presenter available in work edit edit
      # so that the files attached to work can be displaye.
      presenter_init && parent_presenter
      presenter.controller = self
      build_form
    end

    def analytics_subscribe
      ::AnalyticsHelper.monthly_events_report_subscribe_data_set( user: current_user, cc_id: params[:id] )
      redirect_to current_show_path( append: "#analytics" )
    end

    def analytics_subscribed?
      ::AnalyticsHelper.monthly_events_report_subscribed?( user: current_user, cc_id: params[:id] )
    end

    def analytics_unsubscribe
      ::AnalyticsHelper.monthly_events_report_unsubscribe_data_set( user: current_user, cc_id: params[:id] )
      redirect_to current_show_path( append: "#analytics" )
    end

    def create_service_request
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if data_sets_controller_debug_verbose
      ::Deepblue::TicketHelper.new_ticket( curation_concern: curation_concern,
                                           current_user: current_user,
                                           # test_mode: true,
                                           debug_verbose: data_sets_controller_debug_verbose )
      flash[:notice] = "Create service request job started."
      redirect_to [main_app, curation_concern]
    end

    def ensure_doi_minted
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if data_sets_controller_debug_verbose
      ::EnsureDoiMintedJob.perform_later( id: params[:id],
                                          current_user: current_user.email,
                                          args: { email_results_to: current_user.email } )
      flash[:notice] = "Ensure DOI minted job started. You will be emailed the results."
      redirect_to [main_app, curation_concern]
    end

    def aptrust_upload
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if data_sets_controller_debug_verbose
      ::AptrustUploadWorkJob.perform_later( id:                           params[:id],
              email_results_to:             current_user.email,
              cleanup_after_deposit:        ::Aptrust::AptrustIntegrationService.from_controller_cleanup_after_deposit,
              cleanup_bag:                  ::Aptrust::AptrustIntegrationService.from_controller_cleanup_bag,
              cleanup_bag_data:             ::Aptrust::AptrustIntegrationService.from_controller_cleanup_bag_data,
              clear_status:                 ::Aptrust::AptrustIntegrationService.from_controller_clear_status,
              debug_assume_upload_succeeds: ::Aptrust::AptrustIntegrationService.from_controller_debug_assume_upload_succeeds,
              debug_verbose:                ::Aptrust::AptrustIntegrationService.from_controller_debug_verbose )
      flash[:notice] = "APTrust upload work started. You will be emailed the results."
      redirect_to [main_app, curation_concern]
    end

    def aptrust_verify
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if data_sets_controller_debug_verbose
      ::AptrustVerifyWorkJob.perform_later( id:                 params[:id],
                                            email_results_to:   current_user.email,
                                            force_verification: true,  # TODO
                                            reverify_failed:    true,  # TODO
                                            debug_assume_verify_succeeds: false,
                                            debug_verbose:      true )  # TODO
      flash[:notice] = "APTrust verify work started. You will be emailed the results."
      redirect_to [main_app, curation_concern]
    end

    def work_find_and_fix
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if data_sets_controller_debug_verbose
      ::WorkFindAndFixJob.perform_later( id: params[:id], email_results_to: current_user.email )
      flash[:notice] = "Work find and fix job started. You will be emailed the results."
      redirect_to [main_app, curation_concern]
    end

    ## box integration

    def box_create_dir_and_add_collaborator
      return nil unless ::Deepblue::BoxIntegrationService.box_integration_enabled
      # user_email = Deepblue::EmailHelper.user_email_from( current_user )
      # BoxHelper.create_dir_and_add_collaborator( curation_concern.id, user_email: user_email )
      nil
    end

    def box_link
      # return nil unless ::Deepblue::BoxIntegrationService.box_integration_enabled
      # BoxHelper.box_link( curation_concern.id )
      nil
    end

    def box_work_created
      box_create_dir_and_add_collaborator
    end

    ## end box integration

    ## ticketing

    def ensure_ticket
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if data_sets_controller_debug_verbose
      ::Deepblue::TicketHelper.new_ticket_if_necessary( cc_id: params[:id],
                                                        current_user: current_user,
                                                        send_emails: true,
                                                        # test_mode: true,
                                                        debug_verbose: data_sets_controller_debug_verbose )
    end

    ## end ticketing

    ## admin_set

    def assign_admin_set
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:admin_set_id]=#{params[:admin_set_id]}",
                                             "params[PARAMS_KEY]=#{params[PARAMS_KEY]}",
                                             "params[PARAMS_KEY][:admin_set_id]=#{params[PARAMS_KEY][:admin_set_id]}",
                                             "" ] if data_sets_controller_debug_verbose
      admin_sets = Hyrax::AdminSetService.new(self).search_results(:deposit)
      admin_sets.each do |admin_set|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "admin_set=#{admin_set}",
                                               "admin_set.id=#{admin_set.id}",
                                               "admin_set.title=#{admin_set.title}",
                                               "Rails.configuration.default_admin_set_id=#{Rails.configuration.default_admin_set_id}",
                                               "" ] if data_sets_controller_debug_verbose
        if admin_set.id != Rails.configuration.default_admin_set_id &&
          admin_set&.title&.first == Rails.configuration.data_set_admin_set_title

          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "set params[PARAMS_KEY]['admin_set_id'] to",
                                                 "admin_set.id=#{admin_set.id}",
                                                 "admin_set.title=#{admin_set.id}",
                                                 "" ] if data_sets_controller_debug_verbose
          params[PARAMS_KEY]['admin_set_id'] = admin_set.id
          break
        end
      end
    end

    # end admin_set

    ## date_coverage

    # Create EDTF::Interval from form parameters
    # Replace the date coverage parameter prior with serialization of EDTF::Interval
    def assign_date_coverage
      cov_interval = Dataset::DateCoverageService.params_to_interval params
      params[PARAMS_KEY]['date_coverage'] = cov_interval ? cov_interval.edtf : ""
    end

    # end date_coverage

    ## depositor_creator

    # if depositor_creator flag is set, add depositor orcid
    # else remove depositor orcid
    def assign_depositor_creator

      # TODO: current_user may not be the depositor

      debug_verbose =data_sets_controller_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params['depositor_creator_available']=#{params['depositor_creator_available']}",
                                             "params['depositor_orcid']=#{params['depositor_orcid']}",
                                             "current_user.orcid=#{current_user.orcid}",
                                             "params[PARAMS_KEY]['depositor_creator']=#{params[PARAMS_KEY]['depositor_creator']}",
                                             "" ] if debug_verbose
      return unless params['depositor_creator_available'].present?
      params[PARAMS_KEY]['depositor_creator'] = assign_depositor_creator_str
      depositor_orcid = assign_depositor_get_depositor_orcid
      return if depositor_orcid.blank?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params['depositor_creator_available']=#{params['depositor_creator_available']}",
                                             "depositor_orcid=#{depositor_orcid}",
                                             "Hyrax::Orcid::OrcidHelper::validate_orcid=#{Hyrax::Orcid::OrcidHelper::validate_orcid( depositor_orcid )}",
                                             "params[PARAMS_KEY]['depositor_creator']=#{params[PARAMS_KEY]['depositor_creator']}",
                                             "params[PARAMS_KEY]['creator_orcid']=#{params[PARAMS_KEY]['creator_orcid']}",
                                             "" ] if debug_verbose
      # if the depositor_creator value is "true"
      if "true" == params[PARAMS_KEY]['depositor_creator']
        assign_depositor_creator_add( depositor_orcid: depositor_orcid )
      else
        assign_depositor_creator_remove( depositor_orcid: depositor_orcid )
      end
    end

    def assign_depositor_get_depositor_orcid
      debug_verbose =data_sets_controller_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params['depositor_orcid']=#{params['depositor_orcid']}",
                                             "current_user.orcid=#{current_user.orcid}",
                                             "" ] if debug_verbose
      rv = params['depositor_orcid']
      return rv if rv.present?
      rv = current_user.orcid
      rv ||= ""
      return rv
    end

    def assign_depositor_creator_add( depositor_orcid: )
      debug_verbose =data_sets_controller_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[PARAMS_KEY]['creator_orcid']=#{params[PARAMS_KEY]['creator_orcid']}",
                                             "depositor_orcid=#{depositor_orcid}",
                                             "" ] if debug_verbose
      return if depositor_orcid.blank?
      creator_orcid = assign_depositor_creator_get_creator_orcid
      current_user_orcid = Hyrax::Orcid::OrcidHelper::validate_orcid( depositor_orcid )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "creator_orcid=#{creator_orcid}",
                                             "current_user_orcid=#{current_user_orcid}",
                                             "" ] if debug_verbose
      return if current_user_orcid.blank?
      # check for presence of depositor_orcid and add it to creator_orcid if necessary
      found = false
      creator_orcid.each do|orcid|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "orcid=#{orcid}",
                                               "" ] if debug_verbose
        orcid ||= ""
        found = true if orcid.include? current_user_orcid
        break if found
      end
      return if found
      creator_orcids = []
      creator_orcid.each { |orcid| creator_orcids << orcid }
      creator_orcid = [depositor_orcid] + creator_orcids
      params[PARAMS_KEY]['creator_orcid'] = creator_orcid
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "updated creator_orcid=#{creator_orcid}",
                                             "" ] if debug_verbose
    end

    def assign_depositor_creator_get_creator_orcid
      debug_verbose =data_sets_controller_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[PARAMS_KEY]['creator_orcid']=#{params[PARAMS_KEY]['creator_orcid']}",
                                             "" ] if debug_verbose
      creator_orcid = params[PARAMS_KEY]['creator_orcid']
      return creator_orcid unless creator_orcid.nil?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "need to get creator_orcid from curation_concern",
                                             "" ] if debug_verbose
      @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern.present?
      creator_orcid = curation_concern.creator_orcid
      creator_orcid ||= []
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "creator_orcid=#{creator_orcid}",
                                             "" ] if debug_verbose
      return creator_orcid
    end

    def assign_depositor_creator_remove( depositor_orcid: )
      debug_verbose =data_sets_controller_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[PARAMS_KEY]['creator_orcid']=#{params[PARAMS_KEY]['creator_orcid']}",
                                             "depositor_orcid=#{depositor_orcid}",
                                             "" ] if debug_verbose
      return if depositor_orcid.blank?
      creator_orcid = assign_depositor_creator_get_creator_orcid
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "creator_orcid=#{creator_orcid}",
                                             "" ] if debug_verbose
      return if creator_orcid.blank?
      current_user_orcid = Hyrax::Orcid::OrcidHelper::validate_orcid( depositor_orcid )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user_orcid=#{current_user_orcid}",
                                             "" ] if debug_verbose
      return if current_user_orcid.blank?
      # check for presence of depositor_orcid and add it to creator_orcid if necessary
      found = nil
      creator_orcid.each do|orcid|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "orcid=#{orcid}",
                                               "" ] if debug_verbose
        orcid ||= ""
        if orcid.include? current_user_orcid
          found = orcid
          break
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "found=#{found}",
                                             "" ] if debug_verbose
      return if found.blank?
      creator_orcid = [depositor_orcid] - [found]
      params[PARAMS_KEY]['creator_orcid'] = creator_orcid
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "updated creator_orcid=#{creator_orcid}",
                                             "" ] if debug_verbose
    end

    def assign_depositor_creator_str
      param = params[PARAMS_KEY]['depositor_creator']
      return "false" if param.blank?
      return "true" if "true" == param
      return "true" if "1" == param
      return "false"
    end

    # end depositor_creator

    def can_display_read_me?
      @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern.present?
      read_me_file_set_id = curation_concern.read_me_file_set_id
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "read_me_file_set_id=#{read_me_file_set_id}",
                                              "" ] if data_sets_controller_debug_verbose
      return false unless ::Deepblue::FileContentHelper.read_me_file_set_enabled
      return true if current_ability.admin?
      return true if can?( :edit, curation_concern.id )
      return true if read_me_file_set_id.present?
      return false
    end

    def enable_analytics_works_reports_can_subscribe?
      AnalyticsHelper.enable_analytics_works_reports_can_subscribe?
    end

    def is_tabbed?
      return true if current_ability.admin?
      can_display_read_me?
    end

    def read_me_file_set
      @read_me_file_set ||= ::Deepblue::FileContentHelper.read_me_file_set( work: curation_concern )
    end

    def read_me_text
      @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern.present?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@curation_concern.id=#{@curation_concern.id}",
                                             "" ] if data_sets_controller_debug_verbose
      return MsgHelper.t!( 'data_set.read_me_file_set_assignment_missing',
                          size: ActiveSupport::NumberHelper.number_to_human_size( ::Deepblue::FileContentHelper.read_me_file_set_view_max_size )
                        ) if read_me_file_set.blank?
      ::Deepblue::FileContentHelper.read_file( file_set: read_me_file_set )
    end

    def read_me_text_html
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@curation_concern.id=#{@curation_concern.id}",
                                             "" ] if data_sets_controller_debug_verbose
      ::Deepblue::FileContentHelper.read_file_as_html( file_set: read_me_file_set )
    end

    def read_me_text_is_html?
      ::Deepblue::FileContentHelper.read_me_is_html?( file_set: read_me_file_set )
    end

    def read_me_text_simple_format( html_options = {}, options = {} )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@curation_concern.id=#{@curation_concern.id}",
                                             "" ] if data_sets_controller_debug_verbose
      text = read_me_text
      begin
        read_me_simple_format( text, html_options, options )
      rescue
        text
      end
    end

    def read_me_simple_format( text, html_options = {}, options = {} )
      simple_format( text, html_options, options )
    rescue ActionView::Template::Error => e # invalid byte sequence in UTF-8
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rescued error e=#{e}",
                                             "" ] if data_sets_controller_debug_verbose
      # TODO: try to fix text
      "An error has occurred."
    end

    ## Globus

    ## end Globus


    ## Provenance log

    def provenance_log_update_after
      return unless curation_concern.present?
      curation_concern.provenance_log_update_after( current_user: current_user,
                                                    # event_note: 'DataSetsController.provenance_log_update_after',
                                                    update_attr_key_values: @update_attr_key_values )
    end

    def provenance_log_update_before
      return unless curation_concern.present?
      @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
    end

    ## end Provenance log

    ## display provenance log

    def display_provenance_log
      # load provenance log for this work
      file_path = Deepblue::ProvenancePath.path_for_reference( curation_concern.id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_path=#{file_path}",
                                             "" ] if data_sets_controller_debug_verbose
      ::Deepblue::ProvenanceLogService.entries( curation_concern.id, refresh: true )
      # continue on to normal display
      redirect_to current_show_path( append: "#provenance_log_display" )
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
              MsgHelper.t!( 'data_set.tombstone_notice', title: curation_concern.title.first.to_s, reason: epitaph.to_s )
              curation_concern.globus_clean_download if curation_concern.respond_to? :globus_clean_download
            else
              "#{curation_concern.title.first} is already tombstoned."
            end
      redirect_to dashboard_works_path, notice: msg
    end

    def tombstone_enabled?
      true
    end

    ## End Tombstone

    ## User access begin

    def current_user_can_edit?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user&.email=#{current_user&.email}",
                                             "curation_concern.edit_users=#{curation_concern.edit_users}",
                                             "" ] if data_sets_controller_debug_verbose
      return false unless current_user.present?
      curation_concern.edit_users.include? current_user.email
    end

    def current_user_can_read?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user&.email=#{current_user&.email}",
                                             "" ] if data_sets_controller_debug_verbose
      return false unless current_user.present?
      @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern.present?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user&.email=#{current_user&.email}",
                                             "curation_concern&.read_users=#{curation_concern&.read_users}",
                                             "" ] if data_sets_controller_debug_verbose
      curation_concern.read_users.include? current_user.email
    end

    ## User access end

    ## visibility / publish

    def visiblity_changed
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        ::Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ] if data_sets_controller_debug_verbose
      return unless curation_concern.present?
      if visibility_to_private?
        mark_as_set_to_private
      elsif visibility_to_public?
        mark_as_set_to_public
      end
    end

    def visibility_changed_update
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        ::Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ] if data_sets_controller_debug_verbose
      return unless curation_concern.present?
      if curation_concern.private? && @visibility_changed_to_private
       workflow_unpublish
      elsif curation_concern.public? && @visibility_changed_to_public
        workflow_publish
      end
    end

    def visibility_to_private?
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        ::Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ] if data_sets_controller_debug_verbose
      return unless curation_concern.present?
      return false if curation_concern.private?
      params[PARAMS_KEY]['visibility'] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    def visibility_to_public?
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        ::Deepblue::LoggingHelper.obj_class( 'class', self ),
      #                                        "" ] if data_sets_controller_debug_verbose
      return unless curation_concern.present?
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

    def work_url
      curation_concern.data_set_url
    end

    ## end visibility / publish

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
        ::Deepblue::ExportFilesHelper.export_file_sets( target_dir: target_dir,
                                                        file_sets: file_sets,
                                                        log_prefix: log_prefix,
                                                        do_export_predicate: do_export_predicate,
                                                        quiet: quiet,
                                                        &block )
      end

      def flash_and_go_back( msg )
        ::Deepblue::LoggingHelper.debug msg
        redirect_back fallback_location: [main_app, curation_concern], notice: msg
      end

      def flash_error_and_go_back( msg )
        ::Deepblue::LoggingHelper.debug msg
        redirect_back fallback_location: [main_app, curation_concern], error: msg
      end

      def flash_and_redirect_to_main_cc( msg )
        ::Deepblue::LoggingHelper.debug msg
        redirect_to [main_app, curation_concern], notice: msg
      end

      def globus_clean_msg( dir )
        dirs = dir.join( MsgHelper.t( 'data_set.globus_clean_join_html' ) )
        rv = MsgHelper.t!( 'data_set.globus_clean', dirs: dirs )
        return rv
      end

      def globus_file_prep_started_msg( user_email: nil )
        MsgHelper.t!( 'data_set.globus_file_prep_started',
                     when_available: globus_files_when_available( user_email: user_email ) )
      end

      def globus_files_prepping_msg( user_email: nil )
        MsgHelper.t!( 'data_set.globus_files_prepping',
                     when_available: globus_files_when_available( user_email: user_email ) )
      end

      def globus_files_when_available( user_email: nil )
        if user_email.nil?
          MsgHelper.t( 'data_set.globus_files_when_available' )
        else
          MsgHelper.t!( 'data_set.globus_files_when_available_email', user_email: user_email )
        end
      end

      def globus_files_available_here
        MsgHelper.t!( 'data_set.globus_files_available_here', globus_url: globus_url( params[:id] ) )
      end

      def globus_status_msg( user_email: nil )
        msg = if globus_complete?
                globus_files_available_here
              elsif globus_prepping?( params[:id] )
                globus_files_prepping_msg( user_email: user_email )
              else
                globus_file_prep_started_msg( user_email: user_email )
              end
        msg
      end

      def show_presenter
        Hyrax::DataSetPresenter
      end

      def report_irus_analytics_investigation
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if ::IrusAnalytics::Configuration.verbose_debug || data_sets_controller_debug_verbose

        ::Deepblue::IrusHelper.log( class_name: self.class.name,
                                    event: "analytics_investigation",
                                    request: request,
                                    id: params[:id] )
        send_irus_analytics_investigation
      end

      def report_irus_analytics_request
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if ::IrusAnalytics::Configuration.verbose_debug || data_sets_controller_debug_verbose

        ::Deepblue::IrusHelper.log( class_name: self.class.name,
                                    event: "analytics_request",
                                    request: request,
                                    id: params[:id] )
        send_irus_analytics_request
      end

    public

      # irus_analytics: item_identifier
      def item_identifier_for_irus_analytics
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if ::IrusAnalytics::Configuration.verbose_debug || data_sets_controller_debug_verbose
        rv = curation_concern.oai_identifier
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "item_identifier=#{rv}",
                                               "" ] if ::IrusAnalytics::Configuration.verbose_debug || data_sets_controller_debug_verbose
        rv
      end

      def skip_send_irus_analytics?(usage_event_type)
        # return true to skip tracking, for example to skip curation_concerns.visibility == 'private'
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "usage_event_type=#{usage_event_type}",
                                               "" ] if ::IrusAnalytics::Configuration.verbose_debug || data_sets_controller_debug_verbose
        case usage_event_type
        when 'Investigation'
          rv = !deposited?
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "skip_send_irus_analytics?=#{rv}",
                                                 "" ] if ::IrusAnalytics::Configuration.verbose_debug || data_sets_controller_debug_verbose
          rv
        when 'Request'
          rv = !deposited?
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "skip_send_irus_analytics?=#{rv}",
                                                 "" ] if ::IrusAnalytics::Configuration.verbose_debug || data_sets_controller_debug_verbose
          rv
        end
      end

    private

      def get_date_uploaded_from_solr(file_set)
        field = file_set.solr_document['date_uploade_dtsi']
        return if field.blank?
        begin
          Time.parse(field)
        rescue
          Rails.logger.info "Unable to parse date: #{field.first.inspect} for #{self['id']}"
        end
      end

      def target_dir_name_id( dir, id, ext = '' )
        # dir.join "#{::Deepblue::GlobusIntegrationService.globus_base_file_name}#{id}#{ext}"
        dir.join "#{id}#{ext}"
      end

  end

end
