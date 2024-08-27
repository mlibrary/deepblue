# frozen_string_literal: true
# Reviewed: hyrax4

module Hyrax

  module CollectionsControllerBehavior
    extend ActiveSupport::Concern
    include Blacklight::AccessControls::Catalog
    puts "include Blacklight::Base at #{caller_locations(1,1).first}"
    include Blacklight::Base

    mattr_accessor :hyrax_collections_controller_behavior_debug_verbose, default: false

    included do
      # include the display_trophy_link view helper method
      helper Hyrax::TrophyHelper

      # This is needed as of BL 3.7
      copy_blacklight_config_from(::CatalogController)

      before_action do
        blacklight_config.track_search_session = false
      end

      class_attribute :presenter_class,
                      :form_class,
                      :single_item_search_builder_class,
                      :membership_service_class,
                      :parent_collection_query_service

      self.presenter_class = Hyrax::CollectionPresenter

      # The search builder to find the collection
      self.single_item_search_builder_class = SingleCollectionSearchBuilder
      # The search builder to find the collections' members
      self.membership_service_class = Collections::CollectionMemberSearchService
      # A search service to use in finding parent collections
      self.parent_collection_query_service = Collections::NestedCollectionQueryService

      rescue_from ::ActiveFedora::ObjectNotFoundError, with: :unknown_id_rescue
      rescue_from ::Hyrax::ObjectNotFoundError, with: :unknown_id_rescue
    end

    def unknown_id_rescue(e)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_ability.admin?=#{current_ability.admin?}",
                                             "e=#{e.pretty_inspect}",
                                             "" ] if hyrax_collections_controller_behavior_debug_verbose
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

    def create
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params[:id]=#{params[:id]}",
                                             "params=#{params}" ] if hyrax_collections_controller_behavior_debug_verbose
      respond_to do |wants|
        wants.html do
          super
        end
        wants.json do
          unless Rails.configuration.rest_api_allow_mutate
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          super
        end
      end
    end

    def destroy
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params[:id]=#{params[:id]}",
                                             "params=#{params}" ] if hyrax_collections_controller_behavior_debug_verbose
      respond_to do |wants|
        wants.html do
          super
        end
        wants.json do
          unless Rails.configuration.rest_api_allow_mutate
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          super
        end
      end
    end

    def edit
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params[:id]=#{params[:id]}",
                                             "params=#{params}" ] if hyrax_collections_controller_behavior_debug_verbose
      respond_to do |wants|
        wants.html do
          super
        end
        wants.json do
          unless Rails.configuration.rest_api_allow_mutate
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          super
        end
      end
    end

    def show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                            "params[:id]=#{params[:id]}",
                                            "params=#{params}" ] if hyrax_collections_controller_behavior_debug_verbose
      @curation_concern = @collection # we must populate curation_concern
      respond_to do |wants|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               ::Deepblue::LoggingHelper.obj_class( 'wants', wants ),
                                               "wants.format=#{wants.format}",
                                               "" ] if hyrax_collections_controller_behavior_debug_verbose
        wants.html do
          @curation_concern ||= ::PersistHelper.find( params[:id] )
          if @curation_concern.present?
            presenter
            query_collection_members
          end
        end
        wants.json do
          unless Rails.configuration.rest_api_allow_read
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          @curation_concern ||= ::PersistHelper.find( params[:id] )
          if @curation_concern.present?
            presenter
            query_collection_members
          end
          if @curation_concern
            # authorize! :show, @curation_concern
            render :show, status: :ok
          else
            collections_render_json_response( response_type: :not_found, message: "ID #{params[:id]}" )
          end
        end
      end
    end

    # render a json response for +response_type+
    def collections_render_json_response(response_type: :success, message: nil, options: {})
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "response_type=#{response_type}",
                                             "message=#{message}",
                                             "options=#{options}",
                                             "" ] if hyrax_collections_controller_behavior_debug_verbose
      json_body = Hyrax::API.generate_response_body(response_type: response_type, message: message, options: options)
      render json: json_body, status: response_type
    end

    def update
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "params[:id]=#{params[:id]}",
                                             "params=#{params}" ] if hyrax_collections_controller_behavior_debug_verbose
      respond_to do |wants|
        wants.html do
          super
        end
        wants.json do
          unless Rails.configuration.rest_api_allow_mutate
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          super
        end
      end
    end

    def collection
      action_name == 'show' ? @presenter : @collection
    end

    private

      def presenter
        @presenter ||= presenter_class.new(curation_concern, current_ability)
        # hyrax2 # commented out for hyrax4
        # @presenter ||= begin
        #   # Query Solr for the collection.
        #   # run the solr query to find the collection members
        #   response = repository.search(single_item_search_builder.query)
        #   curation_concern = response.documents.first
        #   raise CanCan::AccessDenied unless curation_concern
        #   presenter_class.new(curation_concern, current_ability)
        # end
      end

    def curation_concern
      # Query Solr for the collection.
      # run the solr query to find the collection members
      response, _docs = search_service.search_results
      curation_concern = response.documents.first
      raise CanCan::AccessDenied unless curation_concern
      curation_concern
    end

    def search_service
      Hyrax::SearchService.new(config: blacklight_config, user_params: params.except(:q, :page), scope: self, search_builder_class: single_item_search_builder_class)
    end

      # Instantiates the search builder that builds a query for a single item
      # this is useful in the show view.
      def single_item_search_builder
        single_item_search_builder_class.new(self).with(params.except(:q, :page))
      end

      def collection_params
        form_class.model_attributes(params[:collection])
      end

      # Include 'catalog' and 'hyrax/base' in the search path for views, while prefering
      # our local paths. Thus we are unable to just override `self.local_prefixes`
      def _prefixes
        @_prefixes ||= super + ['catalog', 'hyrax/base']
      end

      def query_collection_members_v2
        member_works
        member_subcollections if collection.collection_type.nestable?
        parent_collections if collection.collection_type.nestable? && action_name == 'show'
      end

    # rubocop:disable Style/GuardClause
    def query_collection_members
      load_member_works
      if Hyrax::CollectionType.for(collection: collection).nestable?
        load_member_subcollections
        load_parent_collections if action_name == 'show'
      end
    end
    # rubocop:enable Style/GuardClause

    # Instantiate the membership query service
      def collection_member_service
        @collection_member_service ||= membership_service_class.new(scope: self, collection: collection, params: params_for_query)
      end

      def member_works
        @response = collection_member_service.available_member_works
        @member_docs = @response.documents
        @members_count = @response.total
      end
    alias load_member_works member_works

      def parent_collections_v2
        page = params[:parent_collection_page].to_i
        query = Hyrax::Collections::NestedCollectionQueryService
        collection.parent_collections = query.parent_collections(child: collection_object, scope: self, page: page)
      end

    ##
    # Handles paged loading for parent collections.
    #
    # @param the query service to use when searching for the parent collections.
    #   uses the class attribute +parent_collection_query_service+ by default.
    def parent_collections(query_service: self.class.parent_collection_query_service)
      page = params[:parent_collection_page].to_i

      collection.parent_collections =
        query_service.parent_collections(child: collection_object,
                                         scope: self,
                                         page: page)
    end
    alias load_parent_collections parent_collections

    ##
    # @note this is here because, though we want to load and authorize the real
    #   collection for show views, for apparently historical reasons,
    #   {#collection} is overridden to access `@presenter`. this should probably
    #   be deprecated and callers encouraged to use `@collection` but the scope
    #   and impact of that change needs more evaluation.
    def collection_object
      action_name == 'show' ? @collection : collection
    end

      def collection_object_v2
        action_name == 'show' ? Collection.find(collection.id) : collection
      end

      def member_subcollections_v2
        verbose =hyrax_collections_controller_behavior_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if verbose
        results = collection_member_service.available_member_subcollections
        @subcollection_solr_response = results
        @subcollection_docs = ::Hyrax::CollectionHelper2.member_subcollections_docs( results )
        @subcollection_count = results.total
      end

    def member_subcollections
      results = collection_member_service.available_member_subcollections
      @subcollection_solr_response = results
      @subcollection_docs = results.documents
      @subcollection_count = @presenter.subcollection_count = results.total
    end
    alias load_member_subcollections member_subcollections

      # You can override this method if you need to provide additional inputs to the search
      # builder. For example:
      #   search_field: 'all_fields'
      # @return <Hash> the inputs required for the collection member query service
      def params_for_query
        params.merge(q: params[:cq])
      end

  end

end
