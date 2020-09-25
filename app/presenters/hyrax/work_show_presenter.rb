# frozen_string_literal: true

# require File.join(Gem::Specification.find_by_name("hyrax").full_gem_path, "app/presenters/hyrax/work_show_presenter.rb")

# monkey patch Hyrax::WorkShowPresenter
module Hyrax

  class WorkShowPresenter

    WORK_SHOW_PRESENTER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.work_show_presenter_debug_verbose

    include ModelProxy
    include PresentsAttributes

    attr_accessor :solr_document, :current_ability, :request

    class_attribute :collection_presenter_class

    # modify this attribute to use an alternate presenter class for the collections
    self.collection_presenter_class = CollectionPresenter

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, :export_formats, :export_as, to: :solr_document

    # delegate fields from Hyrax::Works::Metadata to solr_document
    delegate :based_near_label, :related_url, :depositor, :identifier, :resource_type,
             :keyword, :itemtype, :admin_set, to: :solr_document

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context. Used so
    #                                  the GraphExporter knows what URLs to draw.
    def initialize(solr_document, current_ability, request = nil)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    # CurationConcern methods
    delegate :stringify_keys,
             :human_readable_type,
             :collection?,
             :to_s,
             to: :solr_document

    # Metadata Methods
    delegate :authoremail,
             :contributor,
             :creator,
             :curation_notes_admin,
             :curation_notes_user,
             :date_created,
             :depositor,
             :description,
             :doi_minted?,
             :doi_minting_enable?,
             :doi_pending?,
             :language,
             :embargo_release_date,
             :lease_expiration_date,
             :license, :source,
             :member_of_collection_ids,
             :methodology,
             :publisher,
             :read_me_file_set_id,
             :rights_license,
             :rights_statement,
             :rendering_ids,
             :representative_id,
             :subject,
             :title,
             :thumbnail_id,
             to: :solr_document

    attr_accessor :cc_single_use_link

    def can_delete_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if single_use_show?=#{single_use_show?}",
                                             "false if doi_minted?=#{doi_minted?}",
                                             "false if tombstoned?=#{tombstoned?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
      return false if doi_minted?
      return false if tombstoned?
      return true if current_ability.admin?
      can_edit_work?
    end

    def can_display_provenance_log?
      return false unless display_provenance_log_enabled?
      return false if single_use_show?
      current_ability.admin?
    end

    def can_display_trophy_link?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if single_use_show?=#{single_use_show?}",
                                             "false if tombstoned?=#{tombstoned?}",
                                             # "true if current_ability.admin?=#{current_ability.admin?}",
                                             "false if workflow.state != 'deposited'=#{workflow.state != 'deposited'}",
                                             "true if current_ability.can?( :transfer, id )=#{current_ability.can?( :transfer, id )}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
      return false if tombstoned?
      # return true if current_ability.admin?
      return false if workflow.state != 'deposited'
      return true if current_ability.can?( :transfer, id ) # on the assumption that this indicates ownership
      false
    end

    def can_download_using_globus?
      return false unless globus_enabled?
      return false if single_use_show?
      return true if current_ability.admin?
      return false if embargoed?
      true
    end

    def can_download_zip?
      can_download_zip_maybe? && can_download_zip_confirm?
    end

    def can_download_zip_confirm?
      max_work_file_size_to_download = ::DeepBlueDocs::Application.config.max_work_file_size_to_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "max_work_file_size_to_download < total_file_size=#{max_work_file_size_to_download < total_file_size}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      max_work_file_size_to_download >= total_file_size
    end

    def can_download_zip_maybe?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if zip_download_enabled?=#{zip_download_enabled?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "false if embargoed?=#{embargoed?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false unless zip_download_enabled?
      return true if current_ability.admin?
      return false if embargoed?
      true
    end

    def can_edit_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if single_use_show?=#{single_use_show?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "false if tombstoned?=#{tombstoned?}",
                                             "true if editor?=#{editor?}",
                                             "and workflow.state != 'deposited'=#{workflow.state != 'deposited'}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
      return true if current_ability.admin?
      return false if tombstoned?
      return true if editor? && workflow.state != 'deposited'
      false
    end

    def can_mint_doi_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false unless doi_minting_enabled?=#{doi_minting_enabled?}",
                                             "false if tombstoned?=#{tombstoned?}",
                                             "true if doi_pending?=#{doi_pending?}",
                                             "true if doi_minted?=#{doi_minted?}",
                                             "false if single_use_show?=#{single_use_show?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false unless doi_minting_enabled?
      return false if tombstoned?
      return false if doi_pending? || doi_minted?
      return false if single_use_show?
      return true if current_ability.admin?
      current_ability.can?( :edit, id )
    end

    def can_perform_workflow_actions?
      return false if tombstoned?
      return true if current_ability.admin?
      return false unless current_ability.current_user.present?
      return true if depositor == current_ability.current_user.email
      return true if current_ability.current_user.user_approver?( current_ability.current_user )
      return false
    end

    def can_transfer_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if single_use_show?=#{single_use_show?}",
                                             "false if tombstoned?=#{tombstoned?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "true if current_ability.can?( :transfer, id )=#{current_ability.can?( :transfer, id )}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
      return false if tombstoned?
      return true if current_ability.admin?
      return true if current_ability.can?( :transfer, id )
      false
    end

    def can_view_work_details?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if tombstoned?=#{tombstoned?}",
                                             "true if single_use_show?=#{single_use_show?}",
                                             "true if current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "true if current_ability.current_user.present? && current_ability.current_user.user_approver?( current_ability.current_user )=#{current_ability.current_user.present? && current_ability.current_user.user_approver?( current_ability.current_user )}",
                                             "true if workflow.state == 'deposited' && solr_document.visibility == 'open'=#{workflow.state == 'deposited' && solr_document.visibility == 'open'}",
                                             "false if embargoed?=#{embargoed?}",
                                             "current_ability.current_user_can_read?=#{current_user_can_read?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if tombstoned?
      return true if workflow.state == 'deposited' && solr_document.visibility == 'open'
      return true if single_use_show?
      return true if current_ability.can?( :edit, id )
      return true if current_ability.current_user.present? && current_ability.current_user.user_approver?( current_ability.current_user )
      return false if embargoed?
      current_user_can_read?
    end

    def can_view_work_metadata?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "true if workflow.state == 'deposited' && solr_document.visibility == 'open'=#{workflow.state == 'deposited' && solr_document.visibility == 'open'}",
                                             "true if embargoed?=#{embargoed?}",
                                             "true if tombstoned?=#{tombstoned?}",
                                             "true if single_use_show?=#{single_use_show?}",
                                             "true if current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "true if current_ability.current_user.present? && current_ability.current_user.user_approver?( current_ability.current_user )=#{current_ability.current_user.present? && current_ability.current_user.user_approver?( current_ability.current_user )}",
                                             "current_user_can_read?=#{current_user_can_read?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return true if workflow.state == 'deposited' && solr_document.visibility == 'open'
      return true if embargoed?
      return true if tombstoned?
      return true if single_use_show?
      return true if current_ability.can?( :edit, id )
      return true if current_ability.current_user.present? && current_ability.current_user.user_approver?( current_ability.current_user )
      current_user_can_read?
    end

    def current_user_can_edit?
      # override with something more useful
      return false
     end

    def current_user_can_read?
      # override with something more useful
      return false
    end

    def embargoed?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_document.visibility=#{solr_document.visibility}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      solr_document.visibility == 'embargo'
    end

    def itemscope_itemtype
      if itemtype == "http://schema.org/Dataset"
        "http://schema.org/CreativeWork"
      else
        "http://schema.org/Dataset"
      end
    end

    def member_presenter_factory
      # monkey - add debugging around creating member presenter factory
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      rv = MemberPresenterFactory.new( solr_document, current_ability, request )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv.class.name=#{rv.class.name}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    def member_presenters( ids = member_presenter_factory.file_set_ids,
                           presenter_class = member_presenter_factory.composite_presenter_class )
      # monkey -- replace delegation to member_presenter_factory.member_presenters with member_presenters_init
      # monkey -- add debug
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ids=#{ids}",
                                             "presenter_class=#{presenter_class}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      @work_show_member_presenters ||= member_presenters_init( ids, presenter_class )
    end

    # @param [Array<String>] ids a list of ids to build presenters for
    # @return [Array<presenter_class>] presenters for the array of ids (not filtered by class)
    def member_presenters_for( an_array_of_ids )
      # monkey -- add debug
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "an_array_of_ids=#{an_array_of_ids}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      member_presenters( an_array_of_ids )
    end

    def member_presenters_init( ids = member_presenter_factory.ordered_ids,
                                presenter_class = member_presenter_factory.composite_presenter_class )
      # replace direct reference to member_presenter_factory.member_presenters with the following initialization
      # that transfers the single use flag to all member presenters
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ids=#{ids}",
                                             "presenter_class=#{presenter_class}",
                                             "cc_single_use_link=#{cc_single_use_link}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      presenters = member_presenter_factory.member_presenters( ids, presenter_class )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "presenters.size=#{presenters.size}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return presenters if cc_single_use_link.blank?
      presenters.each do |member_presenter|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "member_presenter.class.name=#{member_presenter.class.name}",
                                               "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
        if member_presenter.respond_to? :cc_parent_single_use_link
          member_presenter.cc_parent_single_use_link = cc_single_use_link
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "member_presenter.cc_parent_single_use_link=#{member_presenter.cc_parent_single_use_link}",
                                                 "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "presenters.size=#{presenters.size}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      presenters
    end

    def page_title
      part1 = human_readable_type
      part1 = "Data Set" if part1 == "Work"
      "#{part1} | #{title.first} | ID: #{id} | #{I18n.t('hyrax.product_name')}"
    end

    def pending_publication?
      workflow.state != 'deposited'
    end

    def published?
      workflow.state == 'deposited' && solr_document.visibility == 'open'
    end

    def relative_url_root
      rv = ::DeepBlueDocs::Application.config.relative_url_root
      return rv if rv
      ''
    end

    # @return FileSetPresenter presenter for the representative FileSets
    def representative_presenter
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "representative_id=#{representative_id}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return nil if representative_id.blank?
      @representative_presenter ||=
          begin
            # begin monkey - replace the lookup of member presenters so it won't cache
            result = member_presenters_init([representative_id],
                                            member_presenter_factory.composite_presenter_class ).first
            # end monkey
            return nil if result.try(:id) == id
            if result.respond_to?(:representative_presenter)
              result.representative_presenter
            else
              result
            end
          end
    end

    def single_use_link_create_download( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      user_id = nil
      user_id = current_ability.current_user.id unless single_use_show?
      rv = SingleUseLink.create( itemId: curation_concern.id,
                                 path: "/data/concern/data_sets/#{id}/single_use_link_zip_download",
                                 user_id: user_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    def single_use_link_download( curation_concern )
      @single_use_link_download ||= single_use_link_create_download( curation_concern )
    end

    def single_use_links
      @single_use_links ||= single_use_links_init
    end

    def single_use_links_init
      su_links = SingleUseLink.where( itemId: id, user_id: current_ability.current_user.id )
      su_links = su_links.select do |su_link|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "su_link=#{su_link}",
                                               "su_link.valid?=#{su_link.valid?}",
                                               "su_link.expired?=#{su_link.expired?}",
                                               "su_link.itemId=#{su_link.itemId}",
                                               "su_link.path=#{su_link.path}",
                                               "su_link.user_id=#{su_link.user_id}",
                                               "su_link.user_comment=#{su_link.user_comment}",
                                               "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
        if su_link.expired?
          su_link.delete
          false
        else
          true
        end
      end
      su_links.map { |link| link_presenter_class.new(link) }
    end

    def single_use_show?
      cc_single_use_link.present?
    end

    def tombstone
      @tombstone ||= tombstone_init
    end

    def tombstone_init
      return nil unless tombstone_enabled?
      solr_value = @solr_document[Solrizer.solr_name('tombstone', :symbol)]
      return nil if solr_value.blank?
      solr_value.first
    end

    def tombstone_enabled?
      true
    end

    def tombstoned?
      tombstone.present?
    end

    def zip_download_link( curation_concern = solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return "id is nil" if id.nil?
      curation_concern = ActiveFedora::Base.find( id ) if curation_concern.nil?
      # return "curation_concern.nil?=#{curation_concern.nil?}"
      url = zip_download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "url=#{url}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return url
    end

    def zip_download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "single_use_show?=#{single_use_show?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return curation_concern.for_zip_download_route unless single_use_show?
      # return Rails.application.routes.url_helpers.url_for( only_path: true,
      #                                                      action: 'show',
      #                                                      controller: 'downloads',
      #                                                      id: curation_concern.id ) unless single_use_show?
      su_link = single_use_link_download( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "su_link.downloadKey=#{su_link.downloadKey}",
                                             "su_link.itemId=#{su_link.itemId}",
                                             "su_link.path=#{su_link.path}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      rv = "/data/single_use_link/download/#{su_link.downloadKey}" # TODO: fix
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      # return "/data/downloads/#{curation_concern.id}/single_use_link/#{su_link.downloadKey}" # TODO: fix
      return rv
    end


    def workflow
      # @workflow ||= WorkflowPresenter.new(solr_document, current_ability)
      @workflow ||= workflow_init
    end

    def workflow_init
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      rv = WorkflowPresenter.new(solr_document, current_ability)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    def inspect_work
      # @inspect_workflow ||= InspectWorkPresenter.new(solr_document, current_ability)
      @inspect_workflow ||= inspect_work_init
    end

    def inspect_work_init
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      rv = InspectWorkPresenter.new(solr_document, current_ability)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    # @return [String] a download URL, if work has representative media, or a blank string
    def download_url
      return '' if representative_presenter.nil?
      Hyrax::Engine.routes.url_helpers.download_url(representative_presenter, host: request.host)
    end

    # @return [Boolean] render a IIIF viewer
    def iiif_viewer?
      representative_id.present? &&
          representative_presenter.present? &&
          representative_presenter.image? &&
          Hyrax.config.iiif_image_server? &&
          members_include_viewable_image?
    end

    alias universal_viewer? iiif_viewer?
    deprecation_deprecate universal_viewer?: "use iiif_viewer? instead"

    # @return [Symbol] the name of the IIIF viewer partial to render
    # @example A work presenter with a custom iiif viewer
    #   module Hyrax
    #     class GenericWorkPresenter < Hyrax::WorkShowPresenter
    #       def iiif_viewer
    #         :my_iiif_viewer
    #       end
    #     end
    #   end
    #
    #   Custom iiif viewer partial at app/views/hyrax/base/iiif_viewers/_my_iiif_viewer.html.erb
    #   <h3>My IIIF Viewer!</h3>
    #   <a href=<%= main_app.polymorphic_url([main_app, :manifest, presenter], { locale: nil }) %>>Manifest</a>
    def iiif_viewer
      :universal_viewer
    end

    # Get presenters for the collections this work is a member of via the member_of_collections association.
    # @return [Array<CollectionPresenter>] presenters
    def member_of_collection_presenters
      PresenterFactory.build_for(ids: member_of_authorized_parent_collections,
                                 presenter_class: collection_presenter_class,
                                 presenter_args: presenter_factory_arguments)
    end

    def date_modified
      solr_document.date_modified.try(:to_formatted_s, :standard)
    end

    def date_uploaded
      solr_document.date_uploaded.try(:to_formatted_s, :standard)
    end

    def link_name
      current_ability.can?(:read, id) ? to_s : 'File'
    end

    def export_as_nt
      graph.dump(:ntriples)
    end

    def export_as_jsonld
      graph.dump(:jsonld, standard_prefixes: true)
    end

    def export_as_ttl
      graph.dump(:ttl)
    end

    def editor?
      return false if single_use_show?
      current_ability.can?(:edit, solr_document)
    end

    def tweeter
      TwitterPresenter.twitter_handle_for(user_key: depositor)
    end

    def presenter_types
      Hyrax.config.registered_curation_concern_types.map(&:underscore) + ["collection"]
    end

    # @return [Array] presenters grouped by model name, used to show the parents of this object
    def grouped_presenters(filtered_by: nil, except: nil)
      # TODO: we probably need to retain collection_presenters (as parent_presenters)
      #       and join this with member_of_collection_presenters
      grouped = member_of_collection_presenters.group_by(&:model_name).transform_keys { |key| key.to_s.underscore }
      grouped.select! { |obj| obj.downcase == filtered_by } unless filtered_by.nil?
      grouped.except!(*except) unless except.nil?
      grouped
    end

    def work_featurable?
      user_can_feature_works? && solr_document.public?
    end

    def display_feature_link?
      work_featurable? && FeaturedWork.can_create_another? && !featured?
    end

    def display_unfeature_link?
      work_featurable? && featured?
    end

    def stats_path
      Hyrax::Engine.routes.url_helpers.stats_work_path(self, locale: I18n.locale)
    end

    def model
      solr_document.to_model
    end

    delegate :ordered_ids, :file_set_presenters, :work_presenters, to: :member_presenter_factory

    # @return [Array] list to display with Kaminari pagination
    def list_of_item_ids_to_display
      paginated_item_list(page_array: authorized_item_ids)
    end

    # @return [Integer] total number of pages of viewable items
    def total_pages
      (total_items.to_f / rows_from_params.to_f).ceil
    end

    def manifest_url
      manifest_helper.polymorphic_url([:manifest, self])
    end

    # IIIF rendering linking property for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add a 'rendering' (eg. a link a download for the resource)
    #
    # @return [Array] array of rendering hashes
    def sequence_rendering
      renderings = []
      if solr_document.rendering_ids.present?
        solr_document.rendering_ids.each do |file_set_id|
          renderings << manifest_helper.build_rendering(file_set_id)
        end
      end
      renderings.flatten
    end

    # IIIF metadata for inclusion in the manifest
    #  Called by the `iiif_manifest` gem to add metadata
    #
    # @return [Array] array of metadata hashes
    def manifest_metadata
      metadata = []
      Hyrax.config.iiif_metadata_fields.each do |field|
        metadata << {
            'label' => I18n.t("simple_form.labels.defaults.#{field}"),
            'value' => Array.wrap(send(field))
        }
      end
      metadata
    end

    # determine if the user can add this work to a collection
    # @param collections <Collections> list of collections to which this user can deposit
    # @return true if the user can deposit to at least one collection OR if the user can create a collection; otherwise, false
    def show_deposit_for?(collections:)
      collections.present? || current_ability.can?(:create_any, Collection)
    end

    private

      def link_presenter_class
        SingleUseLinkPresenter
      end

      # list of item ids to display is based on ordered_ids
      def authorized_item_ids
        @member_item_list_ids ||= begin
          items = ordered_ids
          items.delete_if { |m| !current_ability.can?(:read, m) } if Flipflop.hide_private_items?
          items
        end
      end

      # Uses kaminari to paginate an array to avoid need for solr documents for items here
      def paginated_item_list(page_array:)
        Kaminari.paginate_array(page_array, total_count: page_array.size).page(current_page).per(rows_from_params)
      end

      def total_items
        authorized_item_ids.size
      end

      def rows_from_params
        request.params[:rows].nil? ? Hyrax.config.show_work_item_rows : request.params[:rows].to_i
      end

      def current_page
        page = request.params[:page].nil? ? 1 : request.params[:page].to_i
        page > total_pages ? total_pages : page
      end

      def manifest_helper
        @manifest_helper ||= ManifestHelper.new(request.base_url)
      end

      def featured?
        @featured = FeaturedWork.where(work_id: solr_document.id).exists? if @featured.nil?
        @featured
      end

      def user_can_feature_works?
        return false if single_use_show?
        current_ability.can?(:create, FeaturedWork)
      end

      def presenter_factory_arguments
        [current_ability, request]
      end

      def graph
        GraphExporter.new(solr_document, request).fetch
      end

      def member_of_authorized_parent_collections
        # member_of_collection_ids with current_ability access
        @member_of ||= Hyrax::CollectionMemberService.run(solr_document, current_ability).map(&:id)
      end

      def members_include_viewable_image?
        file_set_presenters.any? { |presenter| presenter.image? && current_ability.can?(:read, presenter.id) }
      end

  end

end
