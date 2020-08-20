# frozen_string_literal: true

module Hyrax

  # monkey patch FileSetsController
  class FileSetsController < ApplicationController

    FILE_SETS_CONTROLLER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.file_sets_controller_debug_verbose # monkey
    PARAMS_KEY = 'file_set' # monkey

    include Blacklight::Base
    include Blacklight::AccessControls::Catalog
    include Hyrax::Breadcrumbs
    # monkey begin
    include Deepblue::DoiControllerBehavior
    include Deepblue::SingleUseLinkControllerBehavior
    # monkey end

    before_action :authenticate_user!, except: [:show, :citation, :stats, :single_use_link] # monkey
    load_and_authorize_resource class: ::FileSet, except: [:show, :single_use_link] # monkey
    before_action :build_breadcrumbs, only: [:show, :edit, :stats]

    # monkey begin
    before_action :provenance_log_destroy,       only: [:destroy]
    before_action :provenance_log_update_before, only: [:update]
    before_action :single_use_link_debug, only: [:single_use_link]

    after_action :provenance_log_create,         only: [:create]
    after_action :provenance_log_update_after,   only: [:update]

    protect_from_forgery with: :null_session,    only: [:file_contents]
    protect_from_forgery with: :null_session,    only: [:display_provenance_log]
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

    # GET /concern/file_sets/:id
    def edit
      initialize_edit_form
    end

    # GET /concern/parent/:parent_id/file_sets/:id
    def show
      respond_to do |wants|
        wants.html { presenter }
        wants.json { presenter }
        additional_response_formats(wants)
      end
    end

    # DELETE /concern/file_sets/:id
    def destroy
      parent = curation_concern.parent
      actor.destroy
      redirect_to [main_app, parent], notice: 'The file has been deleted.'
    end

    # PATCH /concern/file_sets/:id
    def update
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
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      allowed = can_display_file_contents?
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "file_set.id=#{file_set.id}",
                                           "file_set.mime_type=#{file_set.mime_type}",
                                           "file_set.original_file.size=#{file_set.original_file.size}",
                                           "allowed=#{allowed}",
                                           "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      return redirect_to [main_app, curation_concern] unless allowed
      presenter # make sure presenter is created
      render action: 'show_contents'
    end

    attr_accessor :cc_single_use_link

    # GET file_sets/:id/single_use_link/:link_id
    def single_use_link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      @file_set ||= ::Deepblue::WorkViewContentService.content_find_by_id( id: params[:id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "file_set.id=#{file_set.id}",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      su_link = single_use_link_obj( link_id: params[:link_id] )
      @cc_single_use_link = su_link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "su_link.class.name=#{su_link.class.name}",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
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

    def single_use_link_debug
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
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
                                           "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      return false unless ::DeepBlueDocs::Application.config.file_sets_contents_view_allow
      return false unless ( current_ability.admin? ) # || current_ability.can?(:read, id) )
      return false unless ::DeepBlueDocs::Application.config.file_sets_contents_view_mime_types.include?( file_set.mime_type )
      return false if file_set.original_file.size.blank?
      return false if file_set.original_file.size > ::DeepBlueDocs::Application.config.file_sets_contents_view_max_size
      return true
    end

    ## User access begin

    def current_user_can_edit?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user&.email=#{current_user&.email}",
                                             "curation_concern&.parent.edit_users=#{curation_concern&.parent.edit_users}",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      return unless current_user.present?
      return unless curation_concern.parent.present?
      curation_concern.parent.edit_users.include? current_user.email
    end

    def current_user_can_read?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user&.email=#{current_user&.email}",
                                             "curation_concern&.parent.read_users=#{curation_concern&.parent.read_users}",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      return unless current_user.present?
      return unless curation_concern.parent.present?
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
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "provenance_child_remove",
                                             "parent.id=#{parent.id}",
                                             "child_id=#{curation_concern.id}",
                                             "child_title=#{curation_concern.title}",
                                             "event_note=FileSetsController",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
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

    protected

    def attempt_update
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "current_user=#{current_user}",
                                           Deepblue::LoggingHelper.obj_class( "actor", actor ) ]
      if wants_to_revert?
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "current_user=#{current_user}",
                                             Deepblue::LoggingHelper.obj_class( "actor", actor ),
                                             "wants to revert" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
        actor.revert_content(params[:revision])
      elsif params.key?(:file_set)
        if params[:file_set].key?(:files)
          Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "current_user=#{current_user}",
                                               Deepblue::LoggingHelper.obj_class( "actor", actor ),
                                               "actor.update_content" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
          actor.update_content(params[:file_set][:files].first)
        else
          Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "current_user=#{current_user}",
                                               "update_metadata" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
          update_metadata
        end
      elsif params.key?(:files_files) # version file already uploaded with ref id in :files_files array
        Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "current_user=#{current_user}",
                                             Deepblue::LoggingHelper.obj_class( "actor", actor ),
                                             "actor.update_content" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
        uploaded_files = Array(Hyrax::UploadedFile.find(params[:files_files]))
        actor.update_content(uploaded_files.first)
        update_metadata
      end
    end

    def decide_layout
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      layout = if 'show' == action_name || params[:link_id].present?
                 '1_column'
               else
                 'dashboard'
               end
      rv = File.join(theme, layout)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      return rv
    end

    def presenter
      @presenter ||= begin
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
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
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      _, document_list = search_results( search_params ) do |builder|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "builder.class.name=#{builder.class.name}",
                                               "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "builder.processor_chain.size=#{builder.processor_chain.size}",
                                               "builder.processor_chain=#{builder.processor_chain}",
                                               "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
        if params[:action] == "single_use_link"
          builder.processor_chain.delete :add_access_controls_to_solr_params
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "builder.processor_chain.size=#{builder.processor_chain.size}",
                                                 "builder.processor_chain=#{builder.processor_chain}",
                                                 "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
        end
        builder # need to return a builder
      end
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "document_list.first=#{document_list.first}",
      #                                        "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      return document_list.first unless document_list.empty?
      # document_not_found!
      raise CanCan::AccessDenied
    rescue Blacklight::Exceptions::RecordNotFound => e
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "e=#{e}",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      begin
        # check with Fedora to see if the requested id was deleted
        id = params[:id]
        ActiveFedora::Base.find( id )
      rescue Ldp::Gone => gone
        # it was deleted
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "gone=#{gone.class} #{gone.message} at #{gone.backtrace[0]}",
                                               "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
        # okay, since this looks like a deleted curation concern, we can check the provenance log
        # if admin, redirect to the provenance log controller
        if current_ability.admin?
          url = Rails.application.routes.url_helpers.url_for( only_path: true,
                                                              action: 'show',
                                                              controller: 'provenance_log',
                                                              id: id )
          return redirect_to( url, error: "#{id} was deleted." )
        end
      rescue ActiveFedora::ObjectNotFoundError => e2
        # nope, never existed
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "e2=#{e2.class} #{e2.message} at #{e2.backtrace[0]}",
                                               "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      end
      raise CanCan::AccessDenied
    end

    def single_use_link_request?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      rv = params[:action] == 'single_use_link'
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if FILE_SETS_CONTROLLER_DEBUG_VERBOSE
      return rv
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
          redirect_to [main_app, curation_concern], notice: "The file #{view_context.link_to(curation_concern, [main_app, curation_concern])} has been updated."
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
      when 'edit'.freeze
        add_breadcrumb I18n.t("hyrax.file_set.browse_view"), main_app.hyrax_file_set_path(params["id"])
      when 'show'.freeze
        add_breadcrumb presenter.parent.to_s, main_app.polymorphic_path(presenter.parent)
        add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
      end
    end

    # Override of Blacklight::RequestBuilders
    def search_builder_class
      Hyrax::FileSetSearchBuilder
    end

    def initialize_edit_form
      @parent = @file_set.in_objects.first
      original = @file_set.original_file
      @version_list = Hyrax::VersionListPresenter.new(original ? original.versions.all : [])
      @groups = current_user.groups
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
    #     _, document_list = search_results(params)
    #     curation_concern = document_list.first
    #     raise CanCan::AccessDenied unless curation_concern
    #     show_presenter.new(curation_concern, current_ability, request)
    #   end
    # end
    # monkey end

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

  end

end
