# frozen_string_literal: true
# Reviewed: hyrax4

# monkey override Hyrax::CollectionPresenter in Hyrax gem.

module Hyrax

  class CollectionPresenter
    include ModelProxy
    include PresentsAttributes
    include ActionView::Helpers::NumberHelper
    include ::Hyrax::BrandingHelper
    include ActionView::Helpers::TagHelper

    mattr_accessor :collection_presenter_debug_verbose,
                   default: Rails.configuration.collection_presenter_debug_verbose

    attr_accessor :show_actions_debug_verbose
    def show_actions_debug_verbose
      @show_actions_debug_verbose ||= false
    end
    attr_accessor :show_actions_bold_puts
    def show_actions_bold_puts
      @show_actions_bold_puts ||= false
    end

    attr_accessor :solr_document, :current_ability, :request
    attr_reader :subcollection_count
    attr_accessor :parent_collections # This is expected to be a Blacklight::Solr::Response with all of the parent collections
    attr_writer :collection_type

    class_attribute :create_work_presenter_class
    self.create_work_presenter_class = ::Deepblue::SelectTypeListPresenter

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_document.class.name=#{solr_document.class.name}",
                                             "" ] if collection_presenter_debug_verbose
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
      @subcollection_count = 0
    end

    # CurationConcern methods
    delegate :collection?,
             :doi,
             :doi_minted?,
             :doi_minting_enabled?,
             :doi_needs_minting?,
             :doi_pending?,
             :doi_pending_timeout?,
             :human_readable_type,
             :representative_id,
             :stringify_keys,
             :to_s, to: :solr_document

    # hyrax2 # delegate(*Hyrax::CollectionType.collection_type_settings_methods, to: :collection_type, prefix: :collection_type_is)
    delegate(*Hyrax::CollectionType.settings_attributes, to: :collection_type, prefix: :collection_type_is)
    alias nestable? collection_type_is_nestable?

    def collection_type
      @collection_type ||= collection_type_init
    end

    def collection_type_init
      Hyrax::CollectionType.find_by_gid!(collection_type_gid)
    rescue ActiveRecord::RecordNotFound
      ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "Failed to find collection_type_gid: #{collection_type_gid}" ]
      nil
    end

    # Metadata Methods
    delegate :title,
             :description,
             :creator,
             :contributor,
             :subject,
             :publisher,
             :keyword,
             :language,
             :embargo_release_date,
             :lease_expiration_date,
             :license,
             :date_created,
             :resource_type,
             :based_near,
             :related_url,
             :identifier,
             :thumbnail_path,
             :title_or_label,
             :collection_type_gid,
             :create_date,
             :modified_date,
             :visibility,
             :edit_groups,
             :edit_people,
             :curation_notes_admin,
             :curation_notes_user,
             :referenced_by,
             to: :solr_document

    # Terms is the list of fields displayed by
    # app/views/collections/_show_descriptions.html.erb
    def self.terms
      [:total_items,
       :alternative_title,
       :size,
       :resource_type,
       :creator,
       :contributor,
       :keyword,
       :license,
       :publisher,
       :doi,
       :date_created,
       :subject_discipline,
       :language,
       :identifier,
       :based_near,
       :related_url,
       :referenced_by ]
    end

    def self.admin_only_terms
      [:edit_groups,
       :edit_people,
       :read_groups ]
    end

    def terms_with_values
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false unless doi_minting_enabled?=#{doi_minting_enabled?}",
                                             "true if doi_needs_minting?=#{doi_needs_minting?}",
                                             "false if doi_pending?=#{doi_pending?}",
                                             "false if doi_minted?=#{doi_minted?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "" ] if collection_presenter_debug_verbose
      rv = self.class.terms.select { |t| self[t].present? }
      rv += self.class.admin_only_terms.select { |t| self[t].present? } if current_ability.admin?
      return rv
    end

    ##
    # @param [Symbol] key
    # @return [Object]
    def [](key)
      case key
      when :size
        size
      when :total_items
        total_items
      else
        begin
          return solr_document.send key
        rescue NoMethodError
          # TODO: fix this
          return "#{key} not found" if collection_presenter_debug_verbose
          return ""
        end
      end
    end

    def json_metadata_properties
      ::Collection.metadata_keys_json
    end

    def can_download_using_globus_maybe?
      false
    end
    def can_mint_doi_collection?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false unless doi_minting_enabled?=#{doi_minting_enabled?}",
                                             "true if doi_needs_minting?=#{doi_needs_minting?}",
                                             "false if doi_pending?=#{doi_pending?}",
                                             "false if doi_minted?=#{doi_minted?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "" ] if collection_presenter_debug_verbose
      return false unless doi_minting_enabled?
      return true if doi_needs_minting?
      return false if doi_pending?
      return false if doi_minted?
      return true if current_ability.admin?
      current_ability.can?( :edit, id )
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
      rv = Rails.configuration.relative_url_root
      return rv if rv
      ''
    end

    def size
      # TODO: fix this
      return number_to_human_size(@solr_document['bytes_lts'])
    rescue Exception
      0
    end

    # monkey # (at)deprecated to be removed in 4.0.0; this feature was replaced with a
    #   hard-coded null implementation
    # @return [String] 'unknown'
    def size2
      Deprecation.warn('#size has been deprecated for removal in Hyrax 4.0.0; ' \
                       'The implementation of the indexed Collection size ' \
                       'feature is extremely inefficient, so it has been removed. ' \
                       'This method now returns a hard-coded `"unknown"` for ' \
                       'compatibility.')
      'unknown'
    end

    def sorted_methods
      methods.sort
    end

    def ld_json_creator
      ::DeepbluePresenterHelper.ld_json_creator( self )
    end

    def ld_json_description
      ::DeepbluePresenterHelper.ld_json_description( self )
    end

    def ld_json_identifier
      ::DeepbluePresenterHelper.ld_json_identifier( self )
    end

    def ld_json_license
      ::DeepbluePresenterHelper.ld_json_license( self )
    end

    def ld_json_license_name
      ::DeepbluePresenterHelper.ld_json_license_name( self )
    end

    def ld_json_license_url
      ::DeepbluePresenterHelper.ld_json_license_url( self )
    end

    def ld_json_type
      'Dataset' # TODO - this is dependent on the class
    end

    def ld_json_url
      "https://deepblue.lib.umich.edu/data/collections/#{id}"
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
      field_pairs = { "member_of_collection_ids_ssim" => id.to_s }
      SolrQueryService.new
                      .with_field_pairs(field_pairs: field_pairs)
                      .count
    end

    def total_viewable_items
      field_pairs = { "member_of_collection_ids_ssim" => id.to_s }
      SolrQueryService.new
                      .with_field_pairs(field_pairs: field_pairs)
                      .accessible_by(ability: current_ability)
                      .count
    end

    def total_viewable_works
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "current_ability=#{current_ability}",
                                             "" ] if collection_presenter_debug_verbose
      field_pairs = { "member_of_collection_ids_ssim" => id.to_s }
      SolrQueryService.new
                      .with_field_pairs(field_pairs: field_pairs)
                      .with_generic_type(generic_type: "Work")
                      .accessible_by(ability: current_ability)
                      .count
    end

    def total_viewable_collections
      field_pairs = { "member_of_collection_ids_ssim" => id.to_s }
      SolrQueryService.new
                      .with_field_pairs(field_pairs: field_pairs)
                      .with_generic_type(generic_type: "Collection")
                      .accessible_by(ability: current_ability)
                      .count
    end

    def collection_type_badge
      title = collection_type&.title
      title ||= "UNKNOWN"
      badge_color = collection_type&.badge_color
      badge_color = "pink"
      content_tag(:span, title, class: "label", style: "background-color: " + badge_color + ";")
    end

    # The total number of parents that this collection belongs to, visible or not.
    def total_parent_collections
      parent_collections.blank? ? 0 : parent_collections.response['numFound']
    end

    # The number of parent collections shown on the current page. This will differ from total_parent_collections
    # due to pagination.
    def parent_collection_count
      parent_collections.blank? ? 0 : parent_collections.documents.size
    end

    def user_can_nest_collection?
      current_ability.can?(:deposit, solr_document)
    end

    def user_can_create_new_nest_collection?
      current_ability.can?(:create_collection_of_type, collection_type)
    end

    def show_path
      Hyrax::Engine.routes.url_helpers.dashboard_collection_path(id, locale: I18n.locale)
    end

    ##
    # @return [#to_s, nil] a download path for the banner file
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

    ##
    # monkey # (at)deprecated this implementation requires an extra db round trip, had a
    #   buggy cacheing mechanism, and was largely duplicative of other code.
    #   all versions of this code are replaced by
    #   {CollectionsHelper#available_parent_collections_data}.
    def available_parent_collections(scope:)
      Deprecation.warn("#{self.class}#available_parent_collections is " \
                       "deprecated. Use available_parent_collections_data " \
                       "helper instead.")
      return @available_parents if @available_parents.present?
      collection = ::Collection.find(id)
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

    def schema_presenter?
      return false unless @presenter.respond_to? :title
      return false unless @presenter.respond_to? :doi
      return false if @presenter.respond_to? :checksum_value
      return true
    end

    def tombstone_permissions_hack?
      false
    end

  end

end
