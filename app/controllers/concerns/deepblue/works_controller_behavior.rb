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
    include Deepblue::SingleUseLinkControllerBehavior
    include Deepblue::IngestAppendScriptControllerBehavior

    WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.works_controller_behavior_debug_verbose

    class_methods do
      def curation_concern_type=(curation_concern_type)
        # begin monkey
        # load_and_authorize_resource class: curation_concern_type, instance_name: :curation_concern, except: [:show, :file_manager, :inspect_work, :manifest]
        # Note that the find_with_rescue(id) method specified catches Ldp::Gone exceptions and returns nil instead,
        # so if the curation_concern is nil, it's because it wasn't found or it was deleted
        load_and_authorize_resource class: curation_concern_type, find_by: :find_with_rescue, instance_name: :curation_concern, except: [:show, :file_manager, :inspect_work, :manifest]
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

    def after_create_response
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "curation_concern&.id=#{curation_concern&.id}",
                                             "@curation_concern=#{@curation_concern}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      respond_to do |wants|
        wants.html do
          # Calling `#t` in a controller context does not mark _html keys as html_safe
          flash[:notice] = view_context.t('hyrax.works.create.after_create_html', application_name: view_context.application_name)
          redirect_to [main_app, curation_concern]
        end
        wants.json do
          @presenter ||= show_presenter.new(curation_concern, current_ability, request)
          render :show, status: :created
        end
      end
    end

    def after_destroy_response( title )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
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
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
    end

    # render a json response for +response_type+
    def works_render_json_response(response_type: :success, message: nil, options: {})
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "response_type=#{response_type}",
                                             "message=#{message}",
                                             "options=#{options}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      json_body = Hyrax::API.generate_response_body(response_type: response_type, message: message, options: options)
      render json: json_body, status: response_type
    end

    def after_update_response
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
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

    # override curation concerns, add form fields values
    def build_form
      super
      # Set up the multiple parameters for the date coverage attribute in the form
      cov_date = Date.edtf(@form.date_coverage)
      cov_params = Dataset::DateCoverageService.interval_to_params cov_date
      @form.merge_date_coverage_attributes! cov_params
    end

    def create
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      respond_to do |wants|
        wants.html do
          if actor.create( actor_environment )
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
          if actor.create( actor_environment )
            after_create_response
          else
            render_json_response( response_type: :unprocessable_entity, options: { errors: curation_concern.errors } )
          end
        end
      end
    end

    def destroy
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
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
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE # + caller_locations(1,40)
    end

    def destroy_rest
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
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

    def new
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
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
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      # TODO: move these lines to the work form builder in Hyrax
      curation_concern.depositor = current_user.user_key
      curation_concern.admin_set_id = admin_set_id_for_new
      build_form
    end

    # GET file_sets/:id/single_use_link/:link_id
    def single_use_link
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      @curation_concern ||= ::Deepblue::WorkViewContentService.content_find_by_id( id: params[:id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params[:id]=#{params[:id]}",
                                             "params[:link_id]=#{params[:link_id]}",
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      su_link = single_use_link_obj( link_id: params[:link_id] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "su_link.class.name=#{su_link.class.name}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      curation_concern_path = polymorphic_path([main_app, curation_concern] )
      unless single_use_link_valid?( su_link, item_id: curation_concern.id, path: curation_concern_path )
        single_use_link_destroy! su_link
        return redirect_to main_app.root_path, alert: single_use_link_expired_msg
      end
      single_use_link_destroy! su_link
      # respond_to do |wants|
      #   wants.html { presenter.single_use_link = su_link }
      #   wants.json { presenter.single_use_link = su_link }
      #   additional_response_formats(wants)
      # end
      @user_collections = user_collections

      respond_to do |wants|
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                               "wants.format=#{wants.format}",
                                               "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        wants.any do
          presenter && parent_presenter
          presenter.controller = self
          presenter.single_use_link = su_link
          ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                                 "wants.format=#{wants.format}",
                                                 "presenter.controller.class=#{presenter.controller.class}",
                                                 "presenter.single_use_link=#{presenter.single_use_link}",
                                                 "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
          render :show, status: :ok
        end
      end
    end

    def single_use_link_debug
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
    end

    def single_use_link_request?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      rv = params[:action] == 'single_use_link'
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      return rv
    end

    # Finds a solr document matching the id and sets @presenter
    # @raise CanCan::AccessDenied if the document is not found or the user doesn't have access to it.
    def show
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      @user_collections = user_collections

      respond_to do |wants|
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                               "wants.format=#{wants.format}",
                                               "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        wants.html do
          presenter && parent_presenter
          presenter.controller = self
          ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                                 "presenter.controller.class=#{presenter.controller.class}",
                                                 "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
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

    def update
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             Deepblue::LoggingHelper.obj_class( 'actor.class', actor ),
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      respond_to do |wants|
        wants.html do
          had_error = upate_rest
          if had_error
            build_form
            render 'edit', status: :unprocessable_entity
          end
        end
        wants.json do
          unless ::DeepBlueDocs::Application.config.rest_api_allow_mutate
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          had_error = upate_rest
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

    def upate_rest
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      had_error = false
      if curation_concern.present?
        act_env = actor_environment
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "act_env.class.name=#{act_env.class.name}",
                                               "act_env.attributes.class.name=#{act_env.attributes.class.name}",
                                               "curation_concern.errors.class.name=#{curation_concern.errors.class.name}",
                                               "curation_concern.errors.size=#{curation_concern.errors.size}",
                                               "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        if actor.update( act_env )
          after_update_response
          return
        else
          had_error = true
        end
      end
      return had_error
    end

    def attributes_for_actor
      return {} unless curation_concern.present?
      super
    end

    def attributes_for_actor_json
      return {} unless curation_concern.present?
      # super
      raw_params = params[hash_key_for_curation_concern]
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "params.class.name=#{params.class.name}",
                                             "raw_params.class.name=#{raw_params.class.name}",
                                             "raw_params=#{raw_params}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      attributes = if raw_params
                     raw_params = ::ActionController::ParametersTrackErrors.new( raw_params )
                     form_class = work_form_service.form_class(curation_concern)
                     ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                            Deepblue::LoggingHelper.called_from,
                                                            "form_class.name=#{form_class.name}",
                                                            "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE

                     form_class.model_attributes_json( form_params: raw_params, curation_concern: curation_concern )
                   else
                     {}
                   end

      attributes
    end

    def actor_environment
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:action]=#{params[:action]}",
                                             "params[:format]=#{params[:format]}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      attrs_for_actor = if 'json' == params[:format]
                          attributes_for_actor_json
                        else
                          attributes_for_actor
                        end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "attrs_for_actor.class.name=#{attrs_for_actor.class.name}",
                                             "curation_concern.errors.size=#{curation_concern.errors.size}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      if attrs_for_actor.respond_to? :errors
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "attrs_for_actor.errors=#{attrs_for_actor.errors}",
                                               "curation_concern.errors.size=#{curation_concern.errors.size}",
                                               "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        attrs_for_actor.errors.each do |error|
          curation_concern.errors.add( params[:action], error )
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "attrs_for_actor.class.name=#{attrs_for_actor.class.name}",
                                             "curation_concern.errors.size=#{curation_concern.errors.size}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      env = ::Hyrax::Actors::EnvironmentEnhanced.new( curation_concern: curation_concern,
                                                current_ability: current_ability,
                                                attributes: attrs_for_actor,
                                                action: params[:action],
                                                wants_format: params[:format] )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "env=#{env}",
                                             "env.attributes.class.name=#{env.attributes.class.name}",
                                             "env.attributes=#{env.attributes}",
                                             "env.action=#{env.action}",
                                             "env.wants_format=#{env.wants_format}",
                                             "" ] if WORKS_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      return env
    end

    def save_permissions
      if curation_concern.present?
        @saved_permissions = curation_concern.permissions.map(&:to_hash)
      else
        @saved_permissions = {}
      end
    end

    def permissions_changed?
      if curation_concern.present?
        @saved_permissions != curation_concern.permissions.map(&:to_hash)
      else
        false
      end
    end


  end

end
