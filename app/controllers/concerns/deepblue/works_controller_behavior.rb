# frozen_string_literal: true

require_relative "../../../actors/hyrax/actors/environment"
require_relative "../../../../lib/action_controller/metal/parameters_track_errors"

module Deepblue

  module WorksControllerBehavior
    extend ActiveSupport::Concern
    #in umrdr
    #include Hyrax::Controller
    include Hyrax::WorksControllerBehavior
    include Deepblue::ControllerWorkflowEventBehavior
    include Deepblue::DoiControllerBehavior
    include Deepblue::AnonymousLinkControllerBehavior
    include Deepblue::SingleUseLinkControllerBehavior
    include Deepblue::IngestAppendScriptControllerBehavior

    mattr_accessor :deepblue_works_controller_behavior_debug_verbose,
                   default: ::DeepBlueDocs::Application.config.deepblue_works_controller_behavior_debug_verbose

    class_methods do
      def curation_concern_type=(curation_concern_type)
        # begin monkey
        # load_and_authorize_resource class: curation_concern_type, instance_name: :curation_concern, except: [:show, :file_manager, :inspect_work, :manifest]
        # Note that the find_with_rescue(id) method specified catches Ldp::Gone exceptions and returns nil instead,
        # so if the curation_concern is nil, it's because it wasn't found or it was deleted
        load_and_authorize_resource class: curation_concern_type,
                                    find_by: :find_with_rescue,
                                    instance_name: :curation_concern,
                                    except: [:show,
                                             :file_manager,
                                             :inspect_work,
                                             :manifest,
                                             :anonymous_link,
                                             :anonymous_link_zip_download,
                                             :single_use_link,
                                             :single_use_link_zip_download]
        # end monkey

        # Load the fedora resource to get the etag.
        # No need to authorize for the file manager, because it does authorization via the presenter.
        load_resource class: curation_concern_type, instance_name: :curation_concern, only: :file_manager

        self._curation_concern_type = curation_concern_type
        # We don't want the breadcrumb action to occur until after the concern has
        # been loaded and authorized
        before_action :save_permissions, only: :update
      end
    end

    # def track_action_update_parms!( properties: )
    #   super( properties: properties )
    #   properties.delete :link_id
    # end

    attr_accessor :cc_anonymous_link
    attr_accessor :cc_single_use_link

    def actor_environment
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:action]=#{params[:action]}",
                                             "params[:format]=#{params[:format]}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      attrs_for_actor = if data_set_version?
                          attributes_for_actor
                        elsif 'json' == params[:format]
                          attributes_for_actor_json
                        else
                          attributes_for_actor
                        end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "attrs_for_actor.class.name=#{attrs_for_actor.class.name}",
                                             "curation_concern.errors.size=#{curation_concern.errors.size}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      if attrs_for_actor.respond_to? :errors
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "attrs_for_actor.errors=#{attrs_for_actor.errors}",
                                               "curation_concern.errors.size=#{curation_concern.errors.size}",
                                               "" ] if deepblue_works_controller_behavior_debug_verbose
        attrs_for_actor.errors.each do |error|
          curation_concern.errors.add( params[:action], error )
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "attrs_for_actor.class.name=#{attrs_for_actor.class.name}",
                                             "curation_concern.errors.size=#{curation_concern.errors.size}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      env = ::Hyrax::Actors::EnvironmentEnhanced.new( curation_concern: curation_concern,
                                                      current_ability: current_ability,
                                                      attributes: attrs_for_actor,
                                                      action: params[:action],
                                                      wants_format: params[:format] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "env=#{env}",
                                             "env.attributes.class.name=#{env.attributes.class.name}",
                                             "env.attributes=#{env.attributes}",
                                             "env.action=#{env.action}",
                                             "env.wants_format=#{env.wants_format}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      return env
    end

    def after_create_response
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "curation_concern&.id=#{curation_concern&.id}",
                                             "@curation_concern=#{@curation_concern}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      respond_to do |wants|
        wants.html do
          # Calling `#t` in a controller context does not mark _html keys as html_safe
          flash[:notice] = view_context.t( 'hyrax.works.create.after_create_html',
                                           application_name: view_context.application_name )
          redirect_to [main_app, curation_concern]
        end
        wants.json do
          @presenter ||= show_presenter.new(curation_concern, current_ability, request)
          render :show, status: :created
        end
      end
    end

    def after_destroy_response( title )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      respond_to do |wants|
        wants.html do
          if curation_concern.present?
            msg = "Deleted #{title}"
          else
            msg = "Not found #{title}"
          end
          redirect_to my_works_path, notice: msg
        end
        wants.json do
          if curation_concern.present?
            # works_render_json_response(response_type: :deleted, message: "Deleted #{curation_concern.id}") # this results in error 500 because of the response_type
            @presenter ||= show_presenter.new(curation_concern, current_ability, request)
            # render :delete, status: :delete # this results in an error 500 because of the status
            render :delete, status: :no_content # this works
          else
            # works_render_json_response( response_type: 410, message: "Already Deleted #{title}" )
            works_render_json_response( response_type: :not_found, message: "ID #{title}" )
          end
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
    end

    def after_update_response
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      if curation_concern.file_sets.present?
        return redirect_to main_app.copy_access_hyrax_permission_path(curation_concern)  if permissions_changed?
        return redirect_to main_app.confirm_hyrax_permission_path(curation_concern) if curation_concern.visibility_changed?
      end
      respond_to do |wants|
        wants.html do
          redirect_to [main_app, curation_concern], notice: "Work \"#{curation_concern}\" successfully updated."
        end
        wants.json do
          @presenter ||= show_presenter.new(curation_concern, current_ability, request)
          render :show, status: :ok, location: polymorphic_path([main_app, curation_concern])
        end
      end
    end

    # GET data_sets/:id/anonymous_link/:anon_link_id
    def anonymous_link
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:anon_link_id]=#{params[:anon_link_id]}",
                                             "" ] if debug_verbose
      ensure_curation_concern_exists
      anon_link = anonymous_link_obj( link_id: params[:anon_link_id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             "anon_link.class.name=#{anon_link.class.name}",
                                             "" ] if debug_verbose
      return redirect_to( main_app.root_path, alert: anonymous_link_expired_msg ) if anonymous_link_destroy_because_invalid( anon_link )
      return redirect_to( main_app.root_path, alert: anonymous_link_expired_msg ) if anonymous_link_destroy_because_tombstoned( anon_link )
      return redirect_to current_show_path if anonymous_link_destroy_because_published( anon_link )
      @cc_anonymous_link = anon_link
      @user_collections = [] # anonymous user, so we don't care
      respond_to do |wants|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               ::Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                               "wants.format=#{wants.format}",
                                               "" ] if debug_verbose
        wants.any do
          presenter_init && parent_presenter
          presenter.controller = self
          presenter.cc_anonymous_link = anon_link
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 ::Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                                 "wants.format=#{wants.format}",
                                                 "presenter.controller.class=#{presenter.controller.class}",
                                                 "presenter.cc_anonymous_link=#{presenter.cc_anonymous_link}",
                                                 "" ] if debug_verbose
          render :show, status: :ok
        end
      end
    end

    def anonymous_link?
      params[:anon_link_id].present?
    end

    def anonymous_link_debug
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if debug_verbose
    end

    # return true if destroyed
    def anonymous_link_destroy_because_invalid( anon_link )
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ensure_curation_concern_exists
      rv = ::Hyrax::AnonymousLinkService.anonymous_link_valid?( anon_link,
                             item_id: curation_concern.id,
                             path: polymorphic_path( [main_app, curation_concern] ) )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             "anon_link.class.name=#{anon_link.class.name}",
                                             "anonymous_link_valid?=#{rv}",
                                             "" ] if debug_verbose
      return false if rv
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             "anon_link.class.name=#{anon_link.class.name}",
                                             "destroying invalid anonymous link",
                                             "" ] if debug_verbose
      ::Hyrax::AnonymousLinkService.anonymous_link_destroy! anon_link
      return true
    end

    # return true if destroyed
    def anonymous_link_destroy_because_published( anon_link )
      return false unless ::Hyrax::AnonymousLinkService.anonymous_link_destroy_if_published
      ensure_curation_concern_exists
      return false unless curation_concern.published?
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             "anon_link.class.name=#{anon_link.class.name}",
                                             "destroying anonymous link to published work",
                                             "" ] if debug_verbose
      ::Hyrax::AnonymousLinkService.anonymous_link_destroy! anon_link
      return true
    end

    # return true if destroyed
    def anonymous_link_destroy_because_tombstoned( anon_link )
      return false unless ::Hyrax::AnonymousLinkService.anonymous_link_destroy_if_tombstoned
      ensure_curation_concern_exists
      return false unless curation_concern.tombstone.present?
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             "anon_link.class.name=#{anon_link.class.name}",
                                             "destroying anonymous link to tombstoned work",
                                             "" ] if debug_verbose
      ::Hyrax::AnonymousLinkService.anonymous_link_destroy! anon_link
      return true
    end

    def anonymous_link_find_or_create( id:, link_type: )
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "link_type=#{link_type}",
                                             "id=#{id}",
                                             "" ] if debug_verbose
      case link_type
      when 'download'
        path = anonymous_link_path_download
      when 'show'
        path = anonymous_link_path_show
      else
        RuntimeError "Should never get here: unknown link_type=#{link_type}"
      end
      AnonymousLink.find_or_create( id: id, path: path, debug_verbose: debug_verbose )
    end

    def anonymous_link_path_download
      current_show_path( append: "/anonymous_link_zip_download" )
    end

    def anonymous_link_path_show
      current_show_path
    end

    def anonymous_link_request?
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "" ] if debug_verbose
      rv = ( params[:action] == 'anonymous_link' || params[:anon_link_id].present? )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if debug_verbose
      return rv
    end

    def anonymous_link_zip_download
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:anon_link_id]=#{params[:anon_link_id]}",
                                             "" ] if debug_verbose
      ensure_curation_concern_exists
      anon_link = anonymous_link_obj( link_id: params[:anon_link_id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             "anon_link.class.name=#{anon_link.class.name}",
                                             "" ] if debug_verbose
      return redirect_to( main_app.root_path, alert: anonymous_link_expired_msg ) if anonymous_link_destroy_because_tombstoned( anon_link )
      return redirect_to( main_app.root_path, alert: anonymous_link_expired_msg ) if anonymous_link_destroy_because_published( anon_link )
      @cc_anonymous_link = anon_link
      curation_concern_path = polymorphic_path( [main_app, curation_concern] )
      curation_concern_path.gsub!( /\?locale=.+$/, '' )
      unless ::Hyrax::AnonymousLinkService.anonymous_link_valid?( anon_link,
                                                                  item_id: curation_concern.id,
                                                                  path: "#{curation_concern_path}/anonymous_link_zip_download" )
        ::Hyrax::AnonymousLinkService.anonymous_link_destroy! anon_link
        return redirect_to main_app.root_path, alert: anonymous_link_expired_msg
      end
      zip_download
    end

    def attributes_for_actor
      return {} unless curation_concern.present?
      super
    end

    def attributes_for_actor_json
      return {} unless curation_concern.present?
      # super
      raw_params = params[hash_key_for_curation_concern]
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params.class.name=#{params.class.name}",
                                             "raw_params.class.name=#{raw_params.class.name}",
                                             "raw_params=#{raw_params}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      attributes = if raw_params
                     raw_params = ::ActionController::ParametersTrackErrors.new( raw_params )
                     form_class = work_form_service.form_class(curation_concern)
                     ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                            ::Deepblue::LoggingHelper.called_from,
                                                            "form_class.name=#{form_class.name}",
                                                            "" ] if deepblue_works_controller_behavior_debug_verbose

                     form_class.model_attributes_json( form_params: raw_params, curation_concern: curation_concern )
                   else
                     {}
                   end

      attributes
    end

    # override curation concerns, add form fields values
    def build_form
      super
      # Set up the multiple parameters for the date coverage attribute in the form
      cov_date = Date.edtf(@form.date_coverage)
      cov_params = Dataset::DateCoverageService.interval_to_params cov_date
      @form.merge_date_coverage_attributes! cov_params
    end


    def create
      # store the Save as Draft selection
      draft = params[:save_as_draft]

      #When you are using the draft option, you want to put teh work in the Admin Set that is for
      #Drafts, otherwise want to put it in the DataSetAdmin Set. actor_enviroment will already have
      #the DataSetAdmi Set set.
      env = actor_environment
      env.attributes[:admin_set_id] = ::Deepblue::DraftAdminSetService.draft_admin_set_id if draft.eql? t('helpers.action.work.draft')

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      respond_to do |wants|
        wants.html do
          if actor.create( env )
            after_create_response
          else
            build_form
            render 'new', status: :unprocessable_entity
          end
        end
        wants.json do
          unless ::DeepBlueDocs::Application.config.rest_api_allow_mutate
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          if actor.create( env )
            after_create_response
          else
            render_json_response( response_type: :unprocessable_entity, options: { errors: curation_concern.errors } )
          end
        end
      end
    end

    def create_anonymous_link
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
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
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      case params[:commit]
      when t( 'simple_form.actions.single_use_link.create_download' )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if deepblue_works_controller_behavior_debug_verbose
        SingleUseLink.create( itemId: curation_concern.id,
                              path: current_show_path( append: "/single_use_link_zip_download" ),
                              user_id: current_ability.current_user.id,
                              user_comment: params[:user_comment] )
      when t( 'simple_form.actions.single_use_link.create_show' )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if deepblue_works_controller_behavior_debug_verbose
        SingleUseLink.create( itemId: curation_concern.id,
                              path: current_show_path,
                              user_id: current_ability.current_user.id,
                              user_comment: params[:user_comment] )
      else
        RuntimeError "Should never get here: params[:commit]-#{params[:commit]}"
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

    # TODO: move to work_permissions_behavior
    def can_delete_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if anonymous_link?=#{anonymous_link?}",
                                             "false if doi_minted?=#{doi?}",
                                             "false if tombstoned?=#{tombstoned?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      return false if anonymous_link?
      return false if doi?
      return false if tombstoned?
      return true if current_ability.admin?
      can_edit_work?
    end

    def can_subscribe_to_analytics_reports?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false unless AnalyticsHelper.enable_local_analytics_ui?=#{AnalyticsHelper.enable_local_analytics_ui?}",
                                             "false if anonymous_link?=#{anonymous_link?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "false unless AnalyticsHelper.open_analytics_report_subscriptions?=#{AnalyticsHelper.open_analytics_report_subscriptions?}",
                                             "true if can_edit_work?=#{can_edit_work?}",
                                             "curation_concern.depositor=#{curation_concern.depositor}",
                                             "current_ability.current_user.email=#{current_ability.current_user.email}",
                                             "true if curation_concern.depositor == current_ability.current_user.email=#{curation_concern.depositor == current_ability.current_user.email}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      return false unless AnalyticsHelper.enable_local_analytics_ui?
      return false if anonymous_link?
      return true if current_ability.admin? && AnalyticsHelper.analytics_reports_admins_can_subscribe?
      return false unless AnalyticsHelper.open_analytics_report_subscriptions?
      return true if can_edit_work?
      return true if curation_concern.depositor == current_ability.current_user.email
      false
    end

    # TODO: move to work_permissions_behavior
    def can_edit_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if anonymous_link?=#{anonymous_link?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "true if editor?=#{editor?}",
                                             "and workflow_state != 'deposited'=#{workflow_state != 'deposited'}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      return false if anonymous_link?
      return true if current_ability.admin?
      return true if editor? && workflow_state != 'deposited'
      false
    end

    def data_set_version?
      return false unless params[:data_set].present?
      return true if params[:data_set][:version].present?
      return false
    end

    # TODO: move to work_permissions_behavior
    def deposited?
      'deposited' == workflow_state
    end

    def destroy
      @curation_concern ||= ::Deepblue::WorkViewContentService.content_find_by_id( id: params[:id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      return redirect_to my_works_path, notice: "You do not have sufficient privileges for this action." unless can_delete_work?
      respond_to do |wants|
        wants.html do
          destroy_rest
        end
        wants.json do
          unless ::DeepBlueDocs::Application.config.rest_api_allow_mutate
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          destroy_rest
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose # + caller_locations(1,40)
    end

    def destroy_rest
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      if curation_concern.present?
        title = curation_concern.to_s
      else
        title = params[:id]
      end
      if curation_concern.nil?
        after_destroy_response( title )
      elsif actor.destroy( actor_environment )
        Hyrax.config.callback.run( :after_destroy, curation_concern&.id, current_user )
        after_destroy_response( title )
      end
    end

    # TODO: move to work_permissions_behavior
    def doi?
      return false unless curation_concern.respond_to? :doi
      curation_concern.doi.present?
    end

    def edit_groups
      curation_concern
      curation_concern&.edit_groups
    end

    def edit_users
      curation_concern
      curation_concern&.edit_users
    end

    def read_groups
      curation_concern
      curation_concern&.read_groups
    end

    def read_users
      curation_concern
      curation_concern&.read_users
    end

    # TODO: move to work_permissions_behavior
    def editor?
      return false if anonymous_link?
      current_ability.can?(:edit, curation_concern.id)
    end

    def ensure_curation_concern_exists
      return @curation_concern if @curation_concern.present?
      debug_verbose = deepblue_works_controller_behavior_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      @curation_concern = ::Deepblue::WorkViewContentService.content_find_by_id( id: params[:id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:anon_link_id]=#{params[:anon_link_id]}",
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if debug_verbose
      @curation_concern
    end

    def new
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      respond_to do |wants|
        wants.html do
          new_rest
        end
        wants.json do
          unless ::DeepBlueDocs::Application.config.rest_api_allow_mutate
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          new_rest
        end
      end
    end

    def new_rest
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      # TODO: move these lines to the work form builder in Hyrax
      curation_concern.depositor = current_user.user_key
      curation_concern.admin_set_id = admin_set_id_for_new
      build_form
    end

    def permissions_changed?
      if curation_concern.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.class.name=#{curation_concern.class.name}",
                                               "@saved_permissions=#{@saved_permissions}",
                                               "curation_concern.permissions.map(&:to_hash)=#{curation_concern.permissions.map(&:to_hash)}",
                                               "" ] if deepblue_works_controller_behavior_debug_verbose
        @saved_permissions != curation_concern.permissions.map(&:to_hash)
      else
        false
      end
    end

    def presenter_init
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "current_ability.class.name=#{current_ability.class.name}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      if respond_to? :read_me_file_set
        # first make sure that the curation concern is loaded
        @curation_concern = _curation_concern_type.find_with_rescue(params[:id]) unless curation_concern
        read_me_file_set # preemptively load
      end
      rv = presenter
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "presenter.class.name=#{presenter.class.name}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      return rv
    rescue Exception => e
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] + e.backtrace[0..20] if deepblue_works_controller_behavior_debug_verbose
      raise
    end

    def save_permissions
      if curation_concern.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "curation_concern.class.name=#{curation_concern.class.name}",
                                               "curation_concern.permissions.map(&:to_hash)=#{curation_concern.permissions.map(&:to_hash)}",
                                               "" ] if deepblue_works_controller_behavior_debug_verbose
        @saved_permissions = curation_concern.permissions.map(&:to_hash)
      else
        @saved_permissions = {}
      end
    end

    def search_result_document( search_params )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "search_params=#{search_params}",
                                             "anonymous_link?=#{anonymous_link?}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      if anonymous_link?
        begin
          return ::SolrDocument.find( params[:id] )
        rescue ::Blacklight::Exceptions::RecordNotFound => _ignore_and_fall_through
        end
      end
      super( search_params )
    end

    # GET data_sets/:id/single_use_link/:link_id
    def single_use_link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      curation_concern ||= ::Deepblue::WorkViewContentService.content_find_by_id( id: params[:id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      su_link = single_use_link_obj( link_id: params[:link_id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "su_link.class.name=#{su_link.class.name}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      if curation_concern.tombstone.present?
        single_use_link_destroy! su_link
        return redirect_to main_app.root_path, alert: single_use_link_expired_msg
      end
      curation_concern_path = polymorphic_path([main_app, curation_concern] )
      unless single_use_link_valid?( su_link, item_id: curation_concern.id, path: curation_concern_path )
        single_use_link_destroy! su_link
        return redirect_to main_app.root_path, alert: single_use_link_expired_msg
      end
      single_use_link_destroy! su_link
      @user_collections = [] # anonymous user, so we don't care

      respond_to do |wants|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               ::Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                               "wants.format=#{wants.format}",
                                               "" ] if deepblue_works_controller_behavior_debug_verbose
        wants.any do
          presenter_init && parent_presenter
          presenter.controller = self
          presenter.cc_single_use_link = su_link
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 ::Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                                 "wants.format=#{wants.format}",
                                                 "presenter.controller.class=#{presenter.controller.class}",
                                                 "presenter.cc_single_use_link=#{presenter.cc_single_use_link}",
                                                 "" ] if deepblue_works_controller_behavior_debug_verbose
          render :show, status: :ok
        end
      end
    end

    def single_use_link?
      params[:link_id].present?
    end

    def single_use_link_zip_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      @curation_concern ||= ::Deepblue::WorkViewContentService.content_find_by_id( id: params[:id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      su_link = single_use_link_obj( link_id: params[:link_id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "su_link.class.name=#{su_link.class.name}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      if @curation_concern.tombstone.present?
        single_use_link_destroy! su_link
        return redirect_to main_app.root_path, alert: single_use_link_expired_msg
      end
      @cc_single_use_link = su_link
      curation_concern_path = polymorphic_path( [main_app, curation_concern] )
      curation_concern_path.gsub!( /\?locale=.+$/, '' )
      unless single_use_link_valid?( su_link, item_id: curation_concern.id, path: "#{curation_concern_path}/single_use_link_zip_download" )
        single_use_link_destroy! su_link
        return redirect_to main_app.root_path, alert: single_use_link_expired_msg
      end
      single_use_link_destroy! su_link
      zip_download
    end

    def single_use_link_debug
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
    end

    def single_use_link_request?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      rv = ( params[:action] == 'single_use_link' || params[:link_id].present? )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      return rv
    end

    # Finds a solr document matching the id and sets @presenter
    # @raise CanCan::AccessDenied if the document is not found or the user doesn't have access to it.
    def show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      @user_collections = user_collections
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      respond_to do |wants|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               ::Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                               "@user_collections.class.name=#{@user_collections.class.name}",
                                               "" ] if deepblue_works_controller_behavior_debug_verbose
        wants.html do
          presenter_init && parent_presenter
          presenter.controller = self
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 ::Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                                 "presenter.controller.class=#{presenter.controller.class}",
                                                 "" ] if deepblue_works_controller_behavior_debug_verbose
        end
        wants.json do
          unless ::DeepBlueDocs::Application.config.rest_api_allow_read
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          # load and authorize @curation_concern manually because it's skipped for html
          # @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern
          @curation_concern = _curation_concern_type.find_with_rescue(params[:id]) unless curation_concern
          if @curation_concern
            presenter
            authorize! :show, @curation_concern
            render :show, status: :ok
          else
            works_render_json_response( response_type: :not_found, message: "ID #{params[:id]}" )
          end
        end
        additional_response_formats(wants)
        wants.ttl do
          render body: presenter.export_as_ttl, content_type: 'text/turtle'
        end
        wants.jsonld do
          render body: presenter.export_as_jsonld, content_type: 'application/ld+json'
        end
        wants.nt do
          render body: presenter.export_as_nt, content_type: 'application/n-triples'
        end
      end
    end

    # TODO: move to work_permissions_behavior
    def tombstoned?
      return false unless curation_concern.respond_to? :tombstone
      curation_concern.tombstone.present?
    end

    def update_allow_json?
      return true if data_set_version?
      return ::DeepBlueDocs::Application.config.rest_api_allow_mutate
    end

    def update
      #Stores the button selection
      draft = params[:save_as_draft]

      @curation_concern ||= ::Deepblue::WorkViewContentService.content_find_by_id( id: params[:id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             ::Deepblue::LoggingHelper.obj_class( 'actor.class', actor ),
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      return redirect_to my_works_path, notice: "You do not have sufficient privileges for this action." unless can_edit_work?
      respond_to do |wants|
        wants.html do
          had_error = update_rest draft 
          if had_error
            build_form
            render 'edit', status: :unprocessable_entity
          end
        end
        wants.json do
          unless update_allow_json?
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "" ] if deepblue_works_controller_behavior_debug_verbose
          had_error = update_rest  draft 
          if had_error
            if curation_concern.present?
              render_json_response( response_type: :unprocessable_entity, options: { errors: curation_concern.errors } )
            else
              works_render_json_response( response_type: :not_found, message: "ID #{params[:id]}" )
            end
          end
        end
      end
    end

    def update_rest( draft )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "draft=#{draft}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      had_error = false
      if curation_concern.present?
        act_env = actor_environment
        #if user saving as draft when updating a work, set the admin set to the Draft Admin Set.
        act_env.attributes[:admin_set_id] = ::Deepblue::DraftAdminSetService.draft_admin_set_id if draft.eql? t('helpers.action.work.draft')

        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "act_env.class.name=#{act_env.class.name}",
                                               "act_env.attributes.class.name=#{act_env.attributes.class.name}",
                                               "curation_concern.errors.class.name=#{curation_concern.errors.class.name}",
                                               "curation_concern.errors.size=#{curation_concern.errors.size}",
                                               "" ] if deepblue_works_controller_behavior_debug_verbose
        if actor.update( act_env )
          after_update_response
          return
        else
          had_error = true
        end
      end
      return had_error
    end

    # TODO: move to work_permissions_behavior
    def workflow_state
      return false unless curation_concern.respond_to? :workflow_state
      curation_concern.workflow_state
    end

    # render a json response for +response_type+
    def works_render_json_response(response_type: :success, message: nil, options: {})
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "response_type=#{response_type}",
                                             "message=#{message}",
                                             "options=#{options}",
                                             "" ] if deepblue_works_controller_behavior_debug_verbose
      json_body = Hyrax::API.generate_response_body(response_type: response_type, message: message, options: options)
      render json: json_body, status: response_type
    end


  end

end
