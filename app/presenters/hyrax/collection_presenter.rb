# frozen_string_literal: true

# monkey override Hyrax::CollectionPresenter in Hyrax gem.

module Hyrax

  class CollectionPresenter
    include ModelProxy
    include PresentsAttributes
    include ActionView::Helpers::NumberHelper
    include ::Hyrax::BrandingHelper
    include ActionView::Helpers::TagHelper
    attr_accessor :solr_document, :current_ability, :request
    attr_reader :subcollection_count
    attr_accessor :parent_collections # This is expected to be a Blacklight::Solr::Response with all of the parent collections
    attr_writer :collection_type

    mattr_accessor :collection_presenter_debug_verbose,
                   default: ::DeepBlueDocs::Application.config.collection_presenter_debug_verbose

    class_attribute :create_work_presenter_class
    self.create_work_presenter_class = ::Deepblue::SelectTypeListPresenter

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
      @subcollection_count = 0
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :representative_id,
             :to_s, to: :solr_document

    delegate(*Hyrax::CollectionType.collection_type_settings_methods, to: :collection_type, prefix: :collection_type_is)

    def collection_type
      @collection_type ||= Hyrax::CollectionType.find_by_gid!(collection_type_gid)
    end

    # Metadata Methods
    delegate :based_near,
             :collection_type_gid,
             :contributor,
             :create_date,
             :creator,
             :curation_notes_admin,
             :curation_notes_user,
             :date_created,
             :description,
             :edit_groups,
             :edit_people,
             :embargo_release_date,
             :identifier,
             :keyword,
             :language,
             :lease_expiration_date,
             :license,
             :modified_date,
             :publisher,
             :referenced_by,
             :related_url,
             :resource_type,
             :subject,
             :thumbnail_path,
             :title,
             :title_or_label,
             :visibility,
             to: :solr_document

    # Terms is the list of fields displayed by
    # app/views/collections/_show_descriptions.html.erb
    def self.terms
      [:total_items,
       :size,
       :resource_type,
       :creator,
       :contributor,
       :keyword,
       :license,
       :publisher,
       :date_created,
       :subject,
       :language,
       :identifier,
       :based_near,
       :referenced_by,
       :related_url ]
    end

    def terms_with_values
      self.class.terms.select { |t| self[t].present? }
    end

    def [](key)
      case key
      when :size
        size
      when :total_items
        total_items
      else
        solr_document.send key
      end
    end

    def json_metadata_properties
      ::Collection.metadata_keys_json
    end

    def can_download_using_globus_maybe?
      false
    end

    def controller_class
      ::Hyrax::CollectionPresenter
    end

    # begin display_provenance_log

    def can_display_provenance_log?
      return false unless display_provenance_log_enabled?
      current_ability.admin?
    end

    def display_provenance_log_enabled?
      true
    end

    def provenance_log_entries?
      file_path = Deepblue::ProvenancePath.path_for_reference( id )
      File.exist? file_path
    end

    # end display_provenance_log

    def relative_url_root
      rv = ::DeepBlueDocs::Application.config.relative_url_root
      return rv if rv
      ''
    end

    def size
      number_to_human_size(@solr_document['bytes_lts'])
    end

    def sorted_methods
      methods.sort
    end

    def member_of_this_collection
      @member_of_this_collection ||= ::PersistHelper.where("member_of_collection_ids_ssim:#{id}")
    end

    def member_of_this_collection_ids
      @member_of_this_collection_ids ||= member_of_this_collection.map { |member| member.id }
    end

    def collection_members_of_this_collection
      @collection_members_of_this_collection ||= ::PersistHelper.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Collection")
    end

    def collection_members_of_this_collection_ids
      @collection_members_of_this_collection_ids ||= collection_members_of_this_collection.map { |member| member.id }
    end

    def work_members_of_this_collection
      @work_members_of_this_collection ||= ::PersistHelper.where("member_of_collection_ids_ssim:#{id} AND generic_type_sim:Work")
    end
    alias collection_member_ids collection_members_of_this_collection_ids

    def work_members_of_this_collection_ids
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_members_of_this_collection.first&.class.name=#{work_members_of_this_collection.first&.class.name}",
                                             "" ] if collection_presenter_debug_verbose
      @work_members_of_this_collection_ids ||= work_members_of_this_collection.map { |member| member.id }
    end
    alias work_member_ids work_members_of_this_collection_ids

    def total_items
      member_of_this_collection.count
    end

    def total_viewable_items
      member_of_this_collection.accessible_by(current_ability).count
    end

    def total_viewable_works
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "current_ability=#{current_ability}",
                                             "" ] if collection_presenter_debug_verbose
      work_members_of_this_collection.accessible_by(current_ability).count
    end

    def total_viewable_collections
      collection_members_of_this_collection.accessible_by(current_ability).count
    end

    def collection_type_badge
      # collection_type.title
      content_tag(:span, collection_type.title, class: "label", style: "background-color: " + collection_type.badge_color + ";")
    end

    # The total number of parents that this collection belongs to, visible or not.
    def total_parent_collections
      parent_collections.nil? ? 0 : parent_collections.response['numFound']
    end

    # The number of parent collections shown on the current page. This will differ from total_parent_collections
    # due to pagination.
    def parent_collection_count
      parent_collections.nil? ? 0 : parent_collections.documents.size
    end

    def user_can_nest_collection?
      current_ability.can?(:deposit, solr_document)
    end

    def user_can_create_new_nest_collection?
      current_ability.can?(:create_collection_of_type, collection_type)
    end

    def show_path
      Hyrax::Engine.routes.url_helpers.dashboard_collection_path(id)
    end

    def banner_file
      branding_banner_file( id: id )
    end

    def logo_record
      branding_logo_record( id: id )
    end

    # A presenter for selecting a work type to create
    # this is needed here because the selector is in the header on every page
    def create_work_presenter
      @create_work_presenter ||= create_work_presenter_class.new(current_ability.current_user)
    end

    def create_many_work_types?
      if Flipflop.only_use_data_set_work_type?
        false
      else
        create_work_presenter.many?
      end
    end

    def draw_select_work_modal?
      create_many_work_types?
    end

    def first_work_type
      create_work_presenter.first_model
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

    def subcollection_count=(total)
      @subcollection_count = total unless total.nil?
    end

    # For the Managed Collections tab, determine the label to use for the level of access the user has for this admin set.
    # Checks from most permissive to most restrictive.
    # @return String the access label (e.g. Manage, Deposit, View)
    def managed_access
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.manage') if current_ability.can?(:edit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.deposit') if current_ability.can?(:deposit, solr_document)
      return I18n.t('hyrax.dashboard.my.collection_list.managed_access.view') if current_ability.can?(:read, solr_document)
      ''
    end

    # Determine if the user can perform batch operations on this collection.  Currently, the only
    # batch operation allowed is deleting, so this is equivalent to checking if the user can delete
    # the collection determined by criteria...
    # * user must be able to edit the collection to be able to delete it
    # * the collection does not have to be empty
    # @return Boolean true if the user can perform batch actions; otherwise, false
    def allow_batch?
      return true if current_ability.can?(:edit, solr_document)
      false
    end

    def tombstone_permissions_hack?
      false
    end

  end

end
