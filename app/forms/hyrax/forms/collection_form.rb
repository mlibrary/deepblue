# frozen_string_literal: true

module Hyrax

  module Forms

    class CollectionForm
      include HydraEditor::Form
      include HydraEditor::Form::Permissions
      include ::Hyrax::BrandingHelper
      # Used by the search builder
      attr_reader :scope

      delegate :id, :depositor, :permissions, :human_readable_type, :member_ids, :nestable?, to: :model

      class_attribute :membership_service_class, :default_work_primary_terms, :default_work_secondary_terms

      # Required for search builder (FIXME)
      alias collection model

      self.model_class = ::Collection

      self.membership_service_class = Collections::CollectionMemberService

      delegate :blacklight_config, to: Hyrax::CollectionsController

      self.terms = %i[
        authoremail
        based_near
        collection_type_gid
        contributor
        creator
        date_coverage
        date_created
        description
        fundedby
        grantnumber
        identifier
        keyword
        language
        license
        methodology
        publisher
        referenced_by
        related_url
        representative_id
        resource_type
        rights_license
        subject
        subject_discipline
        thumbnail_id
        title
        visibility
      ]

      self.default_work_primary_terms =
        %i[
          title
          creator
          description
          keyword
          subject_discipline
          language
          referenced_by
        ]

      self.default_work_secondary_terms = []

      self.required_fields = %i[
        title
        creator
        description
        subject_discipline
      ]

      ProxyScope = Struct.new(:current_ability, :repository, :blacklight_config) do
        def can?(*args)
          current_ability.can?(*args)
        end
      end

      # @param model [Collection] the collection model that backs this form
      # @param current_ability [Ability] the capabilities of the current user
      # @param repository [Blacklight::Solr::Repository] the solr repository
      def initialize(model, current_ability, repository)
        super(model)
        @scope = ProxyScope.new(current_ability, repository, blacklight_config)
      end

      def permission_template
        @permission_template ||= begin
                                   template_model = PermissionTemplate.find_or_create_by(source_id: model.id)
                                   PermissionTemplateForm.new(template_model)
                                 end
      end

      # @return [Hash] All FileSets in the collection, file.to_s is the key, file.id is the value
      def select_files
        Hash[all_files_with_access]
      end

      # Terms that appear above the accordion
      def primary_terms
        default_work_primary_terms
      end

      # Terms that appear within the accordion
      def secondary_terms
        default_work_secondary_terms
      end

      def relative_url_root
        rv = ::DeepBlueDocs::Application.config.relative_url_root
        return rv if rv
        ''
      end

      def banner_info
        @banner_info ||= branding_banner_info( id: id )
      end

      def logo_info
        @logo_info ||= branding_logo_info( id: id )
      end

      # Do not display additional fields if there are no secondary terms
      # @return [Boolean] display additional fields on the form?
      def display_additional_fields?
        secondary_terms.any?
      end

      def thumbnail_title
        return unless model.thumbnail
        model.thumbnail.title.first
      end

      def list_parent_collections
        collection.member_of_collections
      end

      def list_child_collections
        collection_member_service.available_member_subcollections.documents
      end

      def available_parent_collections(scope:)
        return @available_parents if @available_parents.present?

        collection = Collection.find(id)
        colls = Hyrax::Collections::NestedCollectionQueryService.available_parent_collections(child: collection, scope: scope, limit_to_id: nil)
        @available_parents = colls.map do |col|
          { "id" => col.id, "title_first" => col.title.first }
        end
        @available_parents.to_json
      end

      private

        def all_files_with_access
          member_presenters(member_work_ids).flat_map(&:file_set_presenters).map { |x| [x.to_s, x.id] }
        end

        # Override this method if you have a different way of getting the member's ids
        def member_work_ids
          response = collection_member_service.available_member_work_ids.response
          response.fetch('docs').map { |doc| doc['id'] }
        end

        def collection_member_service
          @collection_member_service ||= membership_service_class.new(scope: scope, collection: collection, params: blacklight_config.default_solr_params)
        end

        def member_presenters(member_ids)
          PresenterFactory.build_for(ids: member_ids,
                                     presenter_class: WorkShowPresenter,
                                     presenter_args: [nil])
        end

    end

  end

end
