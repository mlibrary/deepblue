# frozen_string_literal: true

module Hyrax

  # monkey patch FileSetsController
  class FileSetsController < ApplicationController

    mattr_accessor :file_sets_controller_debug_verbose,
                   default: Rails.configuration.file_sets_controller_debug_verbose # monkey

    PARAMS_KEY = 'file_set' unless const_defined? :PARAMS_KEY # monkey

    include Blacklight::Base
    include Blacklight::AccessControls::Catalog
    include Hyrax::Breadcrumbs
    # monkey begin
    include Deepblue::DoiControllerBehavior
    include Deepblue::AnonymousLinkControllerBehavior
    include Deepblue::SingleUseLinkControllerBehavior
    # monkey end

    before_action :authenticate_user!, except: [:show, :citation, :stats, :anonymous_link, :single_use_link] # monkey
    load_and_authorize_resource class: ::FileSet, except: [:show, :anonymous_link, :single_use_link] # monkey
    before_action :build_breadcrumbs, only: [:show, :edit, :stats]

    # monkey begin
    before_action :provenance_log_destroy,       only: [:destroy]
    before_action :provenance_log_update_before, only: [:update]
    before_action :anonymous_link_debug, only: [:anonymous_link]
    before_action :single_use_link_debug, only: [:single_use_link]

    after_action :provenance_log_create,         only: [:create]
    after_action :provenance_log_update_after,   only: [:update]

    protect_from_forgery with: :null_session,    only: [:assign_to_work_as_read_me]
    protect_from_forgery with: :null_session,    only: [:create_anonymous_link]
    protect_from_forgery with: :null_session,    only: [:create_single_use_link]
    protect_from_forgery with: :null_session,    only: [:file_contents]
    protect_from_forgery with: :null_session,    only: [:display_provenance_log]

    rescue_from ::ActiveFedora::ObjectNotFoundError, with: :unknown_id_rescue
    rescue_from ::Hyrax::ObjectNotFoundError, with: :unknown_id_rescue
    # monkey end

    # provides the help_text view method
    helper PermissionsHelper

    helper_method :curation_concern
    copy_blacklight_config_from(::CatalogController)

    class_attribute :show_presenter, :form_class
    # self.show_presenter = Hyrax::FileSetPresenter # monkey
    self.show_presenter = Hyrax::DsFileSetPresenter # monkey
    self.form_class = Hyrax::Forms::FileSetEditForm

    # A little bit of explanation, CanCan(Can) sets the @file_set via the .load_and_authorize_resource
    # method. However the interface for various CurationConcern modules leverages the #curation_concern method
    # Thus we have file_set and curation_concern that are aliases for each other.
    attr_accessor :file_set
    alias curation_concern file_set
    private :file_set=
    alias curation_concern= file_set=
    private :curation_concern=
    helper_method :file_set

    layout :decide_layout

    attr_accessor :cc_anonymous_link
    attr_accessor :cc_single_use_link

    def unknown_id_rescue(e)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             "current_ability.admin?=#{current_ability.admin?}",
                                             "e=#{e.pretty_inspect}",
                                             "" ] if file_sets_controller_debug_verbose
      url = if current_ability.admin?
              # attempt to pull id out of e.message:
              # ActiveFedora::ObjectNotFoundError: Couldn't find DataSet with 'id'=xyz
              if e.message =~ /^.*\=(.+)$/
                id = Regexp.last_match(1)
                "/data/provenance_log/#{id}"
              else
                "/data/provenance_log/"
              end
            else
              main_app.root_path
            end
      redirect_to url, alert: "<br/>Unknown ID: #{e.message}<br/><br/>"
    end

    # GET file_sets/:id/anonymous_link/:anon_link_id
    def anonymous_link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:anon_link_id]=#{params[:anon_link_id]}",
                                             "" ] if file_sets_controller_debug_verbose
      @file_set ||= ::Deepblue::WorkViewContentService.content_find_by_id( id: params[:id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:anon_link_id]=#{params[:anon_link_id]}",
                                             "file_set.id=#{file_set.id}",
                                             "" ] if file_sets_controller_debug_verbose
      anon_link = anonymous_link_obj( link_id: params[:anon_link_id] )
      @cc_anonymous_link = anon_link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             "anon_link.class.name=#{anon_link.class.name}",
                                             "" ] if file_sets_controller_debug_verbose
      if @file_set.parent.tombstone.present? && ::Hyrax::AnonymousLinkService.anonymous_link_destroy_if_tombstoned
        ::Hyrax::AnonymousLinkService.anonymous_link_destroy! anon_link
        return redirect_to main_app.root_path, alert: anonymous_link_expired_msg
      end
      if @file_set.parent.published? && ::Hyrax::AnonymousLinkService.anonymous_link_destroy_if_published
        ::Hyrax::AnonymousLinkService.anonymous_link_destroy! anon_link
        return redirect_to main_app.root_path, alert: anonymous_link_expired_msg
      end
      curation_concern_path = polymorphic_path([main_app, curation_concern] )
      unless ::Hyrax::AnonymousLinkService.anonymous_link_valid?( anon_link,
                                                                  item_id: file_set.id,
                                                                  path: curation_concern_path )
        ::Hyrax::AnonymousLinkService.anonymous_link_destroy! anon_link
        return redirect_to main_app.root_path, alert: anonymous_link_expired_msg
      end
      respond_to do |wants|
        wants.html { presenter.cc_anonymous_link = anon_link }
        wants.json { presenter.cc_anonymous_link = anon_link }
        additional_response_formats(wants)
      end
    end

    def anonymous_link?
      params[:anon_link_id].present?
    end

    def anonymous_link_debug
      debug_verbose = file_sets_controller_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if debug_verbose
    end

    def anonymous_link_find_or_create( id:, link_type: )
      debug_verbose = file_sets_controller_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "link_type=#{link_type}",
                                             "id=#{id}",
                                             "" ] if debug_verbose
      case link_type
      when 'download'
        path = anonymous_link_path_download( id: id )
      when 'show'
        path = anonymous_link_path_show
      else
        RuntimeError "Should never get here: unknown link_type=#{link_type}"
      end
      AnonymousLink.find_or_create( id: id, path: path, debug_verbose: debug_verbose )
    end

    def anonymous_link_path_download( id: )
      hyrax.download_path( id: id )
    end

    def anonymous_link_path_show
      current_show_path
    end

    def anonymous_link_obj( link_id: )
      @anonymous_link_obj ||= ::Hyrax::AnonymousLinkService.find_anonymous_link_obj( link_id: link_id )
    end

    def anonymous_link_request?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "" ] if file_sets_controller_debug_verbose
      rv = ( params[:action] == 'anonymous_link' || params[:anon_link_id].present? )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if file_sets_controller_debug_verbose
      return rv
    end

    def anonymous_show?
      cc_anonymous_link.present? || cc_single_use_link.present?
    end

    def anonymous_use_show?
      cc_anonymous_link.present?
    end

    def assign_to_work_as_read_me_test
      # do nothing
    end

    def assign_to_work_as_read_me
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "curation_concern.id=#{curation_concern.id}",
                                             "curation_concern.parent.class.name=#{curation_concern.parent.class.name}",
                                             "curation_concern.parent.read_me_file_set_id=#{curation_concern.parent.read_me_file_set_id}",
                                             "" ] if file_sets_controller_debug_verbose
      if current_ability.can( :edit, curation_concern.id )
        assign_to_work_as_read_me_test
        curation_concern.parent.read_me_update( file_set: curation_concern )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id}",
                                               "curation_concern.parent.read_me_file_set_id=#{curation_concern.parent.read_me_file_set_id}",
                                               "" ] if file_sets_controller_debug_verbose
        redirect_to [main_app, curation_concern.parent],
                    notice: I18n.t('hyrax.file_sets.notifications.assigned_as_read_me',
                                   filename: curation_concern.label )
      else
        redirect_to [main_app, curation_concern.parent],
                    error: I18n.t('hyrax.file_sets.notifications.insufficient_rights_to_assign_as_read_me',
                                  filename: curation_concern.label )
      end
    end

    def can_delete_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if anonymous_link?=#{anonymous_link?}",
                                             "false if doi_minted?=#{doi?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "" ] if file_sets_controller_debug_verbose
      return false if anonymous_link?
      return false if doi?
      return true if current_ability.admin?
      can_edit_file?
    end

    def can_edit_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if anonymous_link?=#{anonymous_link?}",
                                             "false if parent_tombstoned?=#{parent_tombstoned?}",
                                             "true current_ability.admin?=#{current_ability.admin?}",
                                             "true editor?=#{editor?}",
                                             "and pending_publication?=#{pending_publication?}",
                                             "" ] if file_sets_controller_debug_verbose
      return false if anonymous_link?
      return false if parent_tombstoned?
      return true if current_ability.admin?
      return true if editor? && pending_publication?
      false
    end

    # GET /files/:id/citation
    def citation; end

    def create_anonymous_link
      debug_verbose = file_sets_controller_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:commit]=#{params[:commit]}",
                                             "" ] if debug_verbose
      case params[:commit]
      when t( 'simple_form.actions.anonymous_link.create_download' )
        anonymous_link_find_or_create( id: params[:id], link_type: 'download' )
      when t( 'simple_form.actions.anonymous_link.create_show' )
        anonymous_link_find_or_create( id: params[:id], link_type: 'show' )
      else
        RuntimeError "Should never get here: params[:commit]=#{params[:commit]}"
      end

      # continue on to normal display
      redirect_to current_show_path( append: "#anonymous_links" )
    end

    def create_single_use_link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:commit]=#{params[:commit]}",
                                             "params[:user_comment]=#{params[:user_comment]}",
                                             "hyrax.download_path(id: curation_concern.id)=#{hyrax.download_path(id: curation_concern.id)}",
                                             "" ] if file_sets_controller_debug_verbose
      case params[:commit]
      when t( 'simple_form.actions.single_use_link.create_download' )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if file_sets_controller_debug_verbose
        SingleUseLink.create( item_id: curation_concern.id,
                              path: hyrax.download_path( id: curation_concern.id ),
                              user_id: current_ability.current_user.id,
                              user_comment: params[:user_comment] )
      when t( 'simple_form.actions.single_use_link.create_show' )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if file_sets_controller_debug_verbose
        SingleUseLink.create( item_id: curation_concern.id,
                              path: current_show_path,
                              user_id: current_ability.current_user.id,
                              user_comment: params[:user_comment] )
      end

      # continue on to normal display
      redirect_to current_show_path( append: "#single_use_links" )
    end

    def current_show_path( append: nil )
      path = polymorphic_path( [main_app, curation_concern] )
      path.gsub!( /\?locale=.+$/, '' )
      return path if append.blank?
      "#{path}#{append}"
    end

    # DELETE /concern/file_sets/:id
    def destroy
      parent = curation_concern.parent
      guard_for_workflow_restriction_on!(parent: presenter.parent) # TODO: verify for hyrax v3
      return redirect_to [main_app, curation_concern],
                         notice: I18n.t('hyrax.insufficent_privileges_for_action') unless can_delete_file?
      actor.destroy
      redirect_to [main_app, parent],  notice: view_context.t('hyrax.file_sets.asset_deleted_flash.message')
    end

    # GET /concern/file_sets/:id
    def edit
      return redirect_to [main_app, curation_concern],
                         notice: I18n.t('hyrax.insufficent_privileges_for_action') unless can_edit_file?
      initialize_edit_form
    end

    # TODO: move to work_permissions_behavior
    def editor?
      return false if anonymous_link?
      current_ability.can?(:edit, curation_concern.id)
    end

    # TODO: move to work_permissions_behavior
    def doi?
      return false unless curation_concern.respond_to? :doi
      curation_concern.doi.present?
    end

    # TODO: move to file_set_permissions_behavior
    def parent_tombstoned?
      return false unless curation_concern.parent.respond_to? :tombstone
      curation_concern.parent.tombstone.present?
    end

    # TODO: move to file_set_permissions_behavior
    def pending_publication?
      curation_concern.parent.workflow_state != 'deposited'
    end

    # TODO: move to file_set_permissions_behavior
    def published?
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "curation_concern.parent.workflow_state=#{curation_concern.parent.workflow_state}",
      #                                        "curation_concern.visibility == 'open'=#{curation_concern.visibility == 'open'}",
      #                                        "" ] if file_sets_controller_debug_verbose
      curation_concern.parent.workflow_state == 'deposited' && curation_concern.visibility == 'open'
    end

    # GET /concern/parent/:parent_id/file_sets/:id
    def show
      presenter
      guard_for_workflow_restriction_on!(parent: presenter.parent) # TODO: verify for hyrax v3
      respond_to do |wants|
        wants.html { presenter }
        wants.json { presenter }
        additional_response_formats(wants)
      end
    end

    # GET /files/:id/stats
    def stats
      @stats = FileUsage.new(params[:id])
    end

    # PATCH /concern/file_sets/:id
    def update
      parent = curation_concern.parent
      guard_for_workflow_restriction_on!(parent: parent) # TODO: verify for hyrax v3
      if attempt_update
        after_update_response
      else
        after_update_failure_response
      end
    rescue RSolr::Error::Http => error
      flash[:error] = error.message
      logger.error "FileSetsController::update rescued #{error.class}\n\t#{error.message}\n #{error.backtrace.join("\n")}\n\n"
      render action: 'edit'
    end

    # GET /files/:id/stats
    def stats
      @stats = FileUsage.new(params[:id])
    end

    # GET /files/:id/citation
    def citation; end

    # monkey begin

    def file_contents
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set.id=#{file_set.id}",
                                             "file_set.mime_type=#{file_set.mime_type}",
                                             "file_set.original_file.size=#{file_set.original_file.size}",
                                             "" ] if file_sets_controller_debug_verbose
      allowed = can_display_file_contents?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file_set.id=#{file_set.id}",
                                           "file_set.mime_type=#{file_set.mime_type}",
                                           "file_set.original_file.size=#{file_set.original_file.size}",
                                           "allowed=#{allowed}",
                                           "" ] if file_sets_controller_debug_verbose
      return redirect_to [main_app, curation_concern] unless allowed
      presenter # make sure presenter is created
      render action: 'show_contents'
    end

    def show_anonymous_link_section?
      debug_verbose = file_sets_controller_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if anonymous_show?=#{anonymous_show?}",
                                             "false if published?=#{published?}",
                                             "" ] if debug_verbose
      return false if anonymous_show?
      return false if published?
      true
    end

    # GET file_sets/:id/single_use_link/:link_id
    def single_use_link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "" ] if file_sets_controller_debug_verbose
      @file_set ||= ::Deepblue::WorkViewContentService.content_find_by_id( id: params[:id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "file_set.id=#{file_set.id}",
                                             "" ] if file_sets_controller_debug_verbose
      su_link = single_use_link_obj( link_id: params[:link_id] )
      @cc_single_use_link = su_link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "su_link.class.name=#{su_link.class.name}",
                                             "" ] if file_sets_controller_debug_verbose
      if @file_set.parent.tombstone.present?
        single_use_link_destroy! su_link
        return redirect_to main_app.root_path, alert: single_use_link_expired_msg
      end
      curation_concern_path = polymorphic_path([main_app, curation_concern] )
      unless single_use_link_valid?( su_link, item_id: file_set.id, path: curation_concern_path )
        single_use_link_destroy! su_link
        return redirect_to main_app.root_path, alert: single_use_link_expired_msg
      end
      single_use_link_destroy! su_link
      respond_to do |wants|
        wants.html { presenter.cc_single_use_link = su_link }
        wants.json { presenter.cc_single_use_link = su_link }
        additional_response_formats(wants)
      end
    end

    def single_use_link?
      params[:link_id].present?
    end

    def single_use_link_debug
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if file_sets_controller_debug_verbose
    end

    def single_use_link_request?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "" ] if file_sets_controller_debug_verbose
      rv = ( params[:action] == 'single_use_link' || params[:link_id].present? )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if file_sets_controller_debug_verbose
      return rv
    end

    def single_use_show?
      cc_single_use_link.present?
    end

    def can_display_file_contents?
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "file_set.id=#{file_set.id}",
                                           "file_set.mime_type=#{file_set.mime_type}",
                                           "file_set.original_file.size=#{file_set.original_file.size}",
                                           "" ] if file_sets_controller_debug_verbose
      return false unless Rails.configuration.file_sets_contents_view_allow
      return false unless ( current_ability.admin? ) # || current_ability.can?(:read, id) )
      return false unless Rails.configuration.file_sets_contents_view_mime_types.include?( file_set.mime_type )
      return false if file_set.original_file.size.blank?
      return false if file_set.original_file.size > Rails.configuration.file_sets_contents_view_max_size
      return true
    end

    ## User access begin

    def current_user_can_edit?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user&.email=#{current_user&.email}",
                                             "curation_concern&.parent.edit_users=#{curation_concern&.parent.edit_users}",
                                             "" ] if file_sets_controller_debug_verbose
      return false unless current_user.present?
      return false unless curation_concern.parent.present?
      curation_concern.parent.edit_users.include? current_user.email
    end

    def current_user_can_read?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user&.email=#{current_user&.email}",
                                             "curation_concern&.parent.read_users=#{curation_concern&.parent.read_users}",
                                             "" ] if file_sets_controller_debug_verbose
      return false unless current_user.present?
      return false unless curation_concern.parent.present?
      curation_concern.parent.read_users.include? current_user.email
    end

    ## User access end

    ## Provenance log

    def provenance_log_create
      curation_concern.provenance_create( current_user: current_user, event_note: 'FileSetsController' )
    end

    def provenance_log_destroy
      curation_concern.provenance_destroy( current_user: current_user, event_note: 'FileSetsController' )
      if curation_concern.parent.present?
        parent = curation_concern.parent
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "provenance_child_remove",
                                             "parent.id=#{parent.id}",
                                             "child_id=#{curation_concern.id}",
                                             "child_title=#{curation_concern.title}",
                                             "event_note=FileSetsController",
                                             "" ] if file_sets_controller_debug_verbose
        return unless parent.respond_to? :provenance_child_add
        parent.provenance_child_remove( current_user: current_user,
                                        child_id: curation_concern.id,
                                        child_title: curation_concern.title,
                                        event_note: "FileSetsController" )
      end
    end

    def provenance_log_update_after
      curation_concern.provenance_log_update_after( current_user: current_user,
                                                    # event_note: 'FileSetsController.provenance_log_update_after',
                                                    update_attr_key_values: @update_attr_key_values )
    end

    def provenance_log_update_before
      @update_attr_key_values = curation_concern.provenance_log_update_before( form_params: params[PARAMS_KEY].dup )
    end

    ## end Provenance log

    ## display provenance log

    def display_provenance_log
      # load provenance log for this work
      file_path = ::Deepblue::ProvenancePath.path_for_reference( curation_concern.id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_path=#{file_path}",
                                             "" ] if file_sets_controller_debug_verbose
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

    protected

    def attempt_update
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "current_user=#{current_user}",
                                             ::Deepblue::LoggingHelper.obj_class( "actor", actor ),
                                             "" ] if file_sets_controller_debug_verbose
      if wants_to_revert?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "current_user=#{current_user}",
                                             ::Deepblue::LoggingHelper.obj_class( "actor", actor ),
                                             "wants to revert" ] if file_sets_controller_debug_verbose
        actor.revert_content(params[:revision])
      elsif params.key?(:file_set)
        if params[:file_set].key?(:files)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "current_user=#{current_user}",
                                               ::Deepblue::LoggingHelper.obj_class( "actor", actor ),
                                               "actor.update_content" ] if file_sets_controller_debug_verbose
          actor.update_content(params[:file_set][:files].first)
        else
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "current_user=#{current_user}",
                                               "update_metadata" ] if file_sets_controller_debug_verbose
          update_metadata
        end
      elsif params.key?(:files_files) # version file already uploaded with ref id in :files_files array
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "current_user=#{current_user}",
                                             ::Deepblue::LoggingHelper.obj_class( "actor", actor ),
                                             "actor.update_content" ] if file_sets_controller_debug_verbose
        uploaded_files = Array(Hyrax::UploadedFile.find(params[:files_files]))
        actor.update_content(uploaded_files.first)
        update_metadata
      end
    end

    def decide_layout
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if file_sets_controller_debug_verbose
      layout = if 'show' == action_name || params[:link_id].present? || params[:anon_link_id].present?
                 '1_column'
               else
                 'dashboard'
               end
      rv = File.join(theme, layout)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if file_sets_controller_debug_verbose
      return rv
    end

    def presenter
      @presenter ||= begin
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "" ] if file_sets_controller_debug_verbose
        # _, document_list = search_results(params)
        # curation_concern = document_list.first
        # raise CanCan::AccessDenied unless curation_concern
        curation_concern = search_result_document( params )
        show_presenter.new( curation_concern, current_ability, request )
      end
    end

    def show_presenter
      Hyrax::DsFileSetPresenter
    end

    def search_result_document( search_params )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "search_params=#{search_params}",
                                             "" ] if file_sets_controller_debug_verbose
      _, document_list = search_results( search_params ) do |builder|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "builder.class.name=#{builder.class.name}",
                                               "" ] if file_sets_controller_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "builder.processor_chain.size=#{builder.processor_chain.size}",
                                               "builder.processor_chain=#{builder.processor_chain}",
                                               "" ] if file_sets_controller_debug_verbose
        if params[:action] == "single_use_link"
          builder.processor_chain.delete :add_access_controls_to_solr_params
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "builder.processor_chain.size=#{builder.processor_chain.size}",
                                                 "builder.processor_chain=#{builder.processor_chain}",
                                                 "" ] if file_sets_controller_debug_verbose
        end
        builder # need to return a builder
      end
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "document_list.first=#{document_list.first}",
      #                                        "" ] if file_sets_controller_debug_verbose
      return document_list.first unless document_list.empty?
      # document_not_found!
      raise CanCan::AccessDenied
    rescue Blacklight::Exceptions::RecordNotFound => e
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "e=#{e}",
                                             "" ] if file_sets_controller_debug_verbose
      begin
        # check with Fedora to see if the requested id was deleted
        id = params[:id]
        ::PersistHelper.find( id )
      rescue Ldp::Gone => gone
        # it was deleted
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "gone=#{gone.class} #{gone.message} at #{gone.backtrace[0]}",
                                               "" ] if file_sets_controller_debug_verbose
        # okay, since this looks like a deleted curation concern, we can check the provenance log
        # if admin, redirect to the provenance log controller
        if current_ability.admin?
          url = Rails.application.routes.url_helpers.url_for( only_path: true,
                                                              action: 'show',
                                                              controller: 'provenance_log',
                                                              id: id )
          return redirect_to( url, error: "#{id} was deleted." )
        end
      rescue Hyrax::ObjectNotFoundError => e2
        # nope, never existed
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "e2=#{e2.class} #{e2.message} at #{e2.backtrace[0]}",
                                               "" ] if file_sets_controller_debug_verbose
      end
      raise CanCan::AccessDenied
    end

    # monkey end

    private

    # this is provided so that implementing application can override this behavior and map params to different attributes
    def update_metadata
      file_attributes = form_class.model_attributes(attributes)
      actor.update_metadata(file_attributes)
    end

    # monkey begin
    # def attempt_update
    #   if wants_to_revert?
    #     actor.revert_content(params[:revision])
    #   elsif params.key?(:file_set)
    #     if params[:file_set].key?(:files)
    #       actor.update_content(params[:file_set][:files].first)
    #     else
    #       update_metadata
    #     end
    #   end
    # end
    # monkey end

    def after_update_response
      respond_to do |wants|
        wants.html do
          link_to_file = view_context.link_to(curation_concern, [main_app, curation_concern])
          redirect_to [main_app, curation_concern], notice: view_context.t('hyrax.file_sets.asset_updated_flash.message', link_to_file: link_to_file)
        end
        wants.json do
          @presenter = show_presenter.new(curation_concern, current_ability)
          render :show, status: :ok, location: polymorphic_path([main_app, curation_concern])
        end
      end
    end

    def after_update_failure_response
      respond_to do |wants|
        wants.html do
          initialize_edit_form
          flash[:error] = "There was a problem processing your request."
          render 'edit', status: :unprocessable_entity
        end
        wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: curation_concern.errors }) }
      end
    end

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'edit'
        add_breadcrumb I18n.t("hyrax.file_set.browse_view"), main_app.hyrax_file_set_path(params["id"])
      when 'show'
        add_breadcrumb presenter.parent.to_s, main_app.polymorphic_path(presenter.parent) if presenter.parent.present?
        add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
      end
    end

    # Override of Blacklight::RequestBuilders
    def search_builder_class
      Hyrax::FileSetSearchBuilder
    end

    def initialize_edit_form
      @parent = @file_set.in_objects.first
      guard_for_workflow_restriction_on!(parent: @parent) # TODO: verify for hyrax v3
      original = @file_set.original_file
      @version_list = Hyrax::VersionListPresenter.new(original ? original.versions.all : [])
      @groups = current_user.groups
    end

    include WorkflowsHelper # Provides #workflow_restriction?, and yes I mean include not helper; helper exposes the module methods

    # @param parent [Hyrax::WorkShowPresenter, GenericWork, #suppressed?] an
    #        object on which we check if the current can take action.
    #
    # @return true if we did not encounter any workflow restrictions
    # @raise WorkflowAuthorizationException if we encountered some workflow_restriction
    def guard_for_workflow_restriction_on!(parent:) # TODO: verify for hyrax v3
      return false # skip this check for now.
      # return true unless workflow_restriction?(parent, ability: current_ability)
      # raise WorkflowAuthorizationException
    end

    def actor
      @actor ||= Hyrax::Actors::FileSetActor.new(@file_set, current_user)
    end

    def attributes
      params.fetch(:file_set, {}).except(:files).permit!.dup # use a copy of the hash so that original params stays untouched when interpret_visibility modifies things
    end

    # monkey begin
    # def presenter
    #   @presenter ||= begin
    #                    presenter = show_presenter.new(curation_concern_document, current_ability, request)
    #                    raise WorkflowAuthorizationException if presenter.parent.blank?
    #                    presenter
    #                  end
    # end
    # monkey end

    def curation_concern_document
      # Query Solr for the collection.
      # run the solr query to find the collection members
      response, _docs = single_item_search_service.search_results
      curation_concern = response.documents.first
      raise CanCan::AccessDenied unless curation_concern
      curation_concern
    end

    def single_item_search_service
      Hyrax::SearchService.new(config: blacklight_config, user_params: params.except(:q, :page), scope: self, search_builder_class: search_builder_class)
    end

    def wants_to_revert?
      params.key?(:revision) && params[:revision] != curation_concern.latest_content_version.label
    end

    # Override this method to add additional response formats to your local app
    def additional_response_formats(_); end

    # This allows us to use the unauthorized and form_permission template in hyrax/base,
    # while prefering our local paths. Thus we are unable to just override `self.local_prefixes`
    def _prefixes
      @_prefixes ||= super + ['hyrax/base']
    end

    # monkey begin
    # def decide_layout
    #   layout = case action_name
    #            when 'show'
    #              '1_column'
    #            else
    #              'dashboard'
    #            end
    #   File.join(theme, layout)
    # end
    # monkey end

    # rubocop:disable Metrics/MethodLength
    def render_unavailable
      message = I18n.t("hyrax.workflow.unauthorized_parent")
      respond_to do |wants|
        wants.html do
          unavailable_presenter
          flash[:notice] = message
          render 'unavailable', status: :unauthorized
        end
        wants.json do
          render plain: message, status: :unauthorized
        end
        additional_response_formats(wants)
        wants.ttl do
          render plain: message, status: :unauthorized
        end
        wants.jsonld do
          render plain: message, status: :unauthorized
        end
        wants.nt do
          render plain: message, status: :unauthorized
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def unavailable_presenter
      @presenter ||= show_presenter.new(::SolrDocument.find(params[:id]), current_ability, request)
    end

  end

end
