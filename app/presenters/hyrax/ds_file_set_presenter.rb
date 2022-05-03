# frozen_string_literal: true

module Hyrax

  class DsFileSetPresenter < Hyrax::FileSetPresenter

    mattr_accessor :ds_file_set_presenter_debug_verbose,
                   default: Rails.configuration.ds_file_set_presenter_debug_verbose

    mattr_accessor :ds_file_set_presenter_view_debug_verbose,
                   default: Rails.configuration.ds_file_set_presenter_view_debug_verbose

    include Deepblue::DeepbluePresenterBehavior

    attr_accessor :show_actions_debug_verbose
    def show_actions_debug_verbose
      @show_actions_debug_verbose ||= false
    end
    attr_accessor :show_actions_bold_puts
    def show_actions_bold_puts
      @show_actions_bold_puts ||= false
    end

    delegate :checksum_algorithm,
             :checksum_value,
             :doi,
             :doi_minted?,
             :doi_minting_enabled?,
             :doi_pending?,
             :file_size,
             :original_checksum,
             :mime_type,
             :edit_groups,
             :read_groups,
             :title,
             :virus_scan_service,
             :virus_scan_status,
             :virus_scan_status_date, to: :solr_document

    delegate :rights_license, to: :parent_presenter

    attr_accessor :cc_anonymous_link
    attr_accessor :cc_parent_anonymous_link
    attr_accessor :cc_parent_single_use_link
    attr_accessor :cc_single_use_link
    attr_accessor :parent_presenter

    def initialize( solr_document, current_ability, request = nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if ds_file_set_presenter_debug_verbose
      super( solr_document, current_ability, request )
    end

    def debug_verbose
      DsFileSetPresenter.ds_file_set_presenter_debug_verbose
    end

    def debug_verbose
      DsFileSetPresenter.ds_file_set_presenter_view_debug_verbose
    end

    def anonymous_link_download( main_app:, curation_concern: solr_document )
      @anonymous_link_download ||= anonymous_link_find_or_create( main_app: main_app,
                                                                  curation_concern: curation_concern,
                                                                  link_type: 'download' )
    end

    def anonymous_link_find_or_create( main_app:, curation_concern: solr_document, link_type: )
      debug_verbose = ds_file_set_presenter_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "link_type=#{link_type}",
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if debug_verbose
      case link_type
      when 'download'
        path = anonymous_link_path_download( main_app: main_app, curation_concern: curation_concern )
      when 'show'
        path = anonymous_link_path_show( main_app: main_app, curation_concern: curation_concern )
      else
        RuntimeError "Should never get here: unknown link_type=#{link_type}"
      end
      AnonymousLink.find_or_create( id: id, path: path, debug_verbose: debug_verbose )
    end

    def anonymous_link_need_create_download_button?( main_app:, curation_concern: solr_document )
      debug_verbose = ds_file_set_presenter_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      anon_links = AnonymousLink.where( item_id: curation_concern.id )
      anon_links.each do |link|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "link=#{link}",
                                               "link.path=#{link.path}",
                                               "" ] if debug_verbose
        return false if link.path.include? 'downloads'
      end
      true
    end

    def anonymous_link_need_create_show_button?( main_app:, curation_concern: solr_document )
      path = anonymous_link_path_show( main_app: main_app, curation_concern: curation_concern )
      anon_links = AnonymousLink.where( item_id: curation_concern.id, path: path )
      anon_links.blank?
    end

    def anonymous_link_path_download( main_app:, curation_concern: solr_document )
      # hyrax.download_path( id: id )
      Hyrax::Engine.routes.url_helpers.download_path( id: curation_concern.id )
    end

    def anonymous_link_path_show( main_app:, curation_concern: solr_document )
      # current_show_path
      "/data/concern/file_sets/#{id}" # TODO: fix
    end

    def anonymous_link_presenter_class
      AnonymousLinkPresenter
    end

    def anonymous_link_show( main_app:, curation_concern: solr_document )
      @anonymous_link_show ||= anonymous_link_find_or_create( main_app: main_app,
                                                              curation_concern: solr_document,
                                                              link_type: 'show' )
    end

    def anonymous_links
      @anonymous_links ||= anonymous_links_init
    end

    def anonymous_links_init
      debug_verbose = ds_file_set_presenter_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      anon_links = AnonymousLink.where( item_id: id )
      anon_links = anon_links.select do |anon_link|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "anon_link=#{anon_link}",
                                               "anon_link.valid?=#{anon_link.valid?}",
                                               "anon_link.expired?=#{anon_link.expired?}",
                                               "anon_link.item_id=#{anon_link.item_id}",
                                               "anon_link.path=#{anon_link.path}",
                                               "anon_link.user_id=#{anon_link.user_id}",
                                               "" ] if debug_verbose
        if anon_link.expired?
          anon_link.delete
          false
        else
          true
        end
      end
      anon_links.map { |link| anonymous_link_presenter_class.new(link) }
    end

    def anonymous_show?
      anonymous_use_show? || single_use_show?
    end

    def anonymous_use_show?
      cc_anonymous_link.present? || cc_parent_anonymous_link.present?
    end

    def controller_class
      ::Hyrax::FileSetsController
    end

    def can_assign_to_work_as_read_me?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "parent.class.name=#{parent.class.name}",
                                             "parent.id=#{parent.id}",
                                             "Array( parent.read_me_file_set_id ).first=#{Array( parent.read_me_file_set_id ).first}",
                                             "id=#{id}",
                                             "false if Array( parent.read_me_file_set_id ).first == id=#{Array( parent.read_me_file_set_id ).first == id}",
                                             "false unless not right mime_type=#{::Deepblue::FileContentHelper.read_me_file_set_view_mime_types.include? mime_type}",
                                             "false if too big=#{file_size > ::Deepblue::FileContentHelper.read_me_file_set_view_max_size}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return false unless ::Deepblue::FileContentHelper.read_me_file_set_enabled
      return false if Array( parent.read_me_file_set_id ).first == id
      return false unless ::Deepblue::FileContentHelper.read_me_file_set_view_mime_types.include? mime_type
      return false if file_size > ::Deepblue::FileContentHelper.read_me_file_set_view_max_size
      return can_edit_file?
    end

    def can_delete_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if anonymous_show?=#{anonymous_show?}",
                                             "false if doi_minted?=#{doi_minted?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             # "false if parent_doi_minted?=#{parent_doi_minted?}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return false if anonymous_show?
      return false if doi_minted?
      return true if current_ability.admin?
      # return false if parent_doi_minted?
      can_edit_file?
    end

    def can_display_file_contents?
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "mime_type=#{mime_type}",
                                           "file_size=#{file_size}",
                                           "" ] if ds_file_set_presenter_debug_verbose
      return false unless ::DeepBlueDocs::Application.config.file_sets_contents_view_allow
      return false if anonymous_show?
      return false unless ( current_ability.admin? ) # || current_ability.can?(:read, id) )
      return false unless ::DeepBlueDocs::Application.config.file_sets_contents_view_mime_types.include?( mime_type )
      return false if file_size.blank?
      return false if file_size > ::DeepBlueDocs::Application.config.file_sets_contents_view_max_size
      return true
    end

    def can_display_provenance_log?
      return false unless display_provenance_log_enabled?
      return false if anonymous_show?
      current_ability.admin?
    end

    def can_download_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if file_size_too_large_to_download?=#{file_size_too_large_to_download?}",
                                             "true if anonymous_show?=#{anonymous_show?}",
                                             "true if current_ability.can?( :download, id )=#{current_ability.can?( :download, id )}",
                                             "" ] if ds_file_set_presenter_debug_verbose

      return false if file_size_too_large_to_download?
      return true if anonymous_show?
      return true if current_ability.can?( :download, id )
      false
    end

    def can_download_file_confirm?
      size = file_size
      max_file_size_to_download = ::DeepBlueDocs::Application.config.max_file_size_to_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "max_file_size_to_download < size=#{max_file_size_to_download < size}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      max_file_size_to_download >= size
    end

    def can_download_file_maybe?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "true if anonymous_show?=#{anonymous_show?}",
                                             "true current_ability.admin?=#{current_ability.admin?}",
                                             "false if embargoed?=#{embargoed?}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return true if anonymous_show?
      return true if current_ability.admin?
      return false if embargoed?
      true
    end

    def can_download_using_globus_maybe?
      false
    end

    def can_edit_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if anonymous_show?=#{anonymous_show?}",
                                             "false if parent.tombstone.present?=#{parent.tombstone.present?}",
                                             "true current_ability.admin?=#{current_ability.admin?}",
                                             "true editor?=#{editor?}",
                                             "and pending_publication?=#{pending_publication?}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return false if anonymous_show?
      return false if parent.tombstone.present?
      return true if current_ability.admin?
      return true if editor? && pending_publication?
      false
    end

    def can_mint_doi_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false unless doi_minting_enabled?=#{doi_minting_enabled?}",
                                             "false if anonymous_show?=#{anonymous_show?}",
                                             "false if parent.tombstone.present?=#{parent.tombstone.present?}",
                                             "true if doi_pending?=#{doi_pending?}",
                                             "true if doi_minted?=#{doi_minted?}",
                                             "current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return false unless doi_minting_enabled?
      return false if anonymous_show?
      return false if parent.tombstone.present?
      return false if doi_pending? || doi_minted?
      return true if current_ability.admin?
      current_ability.can?( :edit, id )
    end

    def can_subscribe_to_analytics_reports?
      parent_presenter.can_subscribe_to_analytics_reports?
    end

    def can_view_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if parent.tombstone.present?=#{parent.tombstone.present?}",
                                             "true if anonymous_show?=#{anonymous_show?}",
                                             "true if current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "true if published?=#{published?}",
                                             "false if parent.embargoed?=#{parent.embargoed?}",
                                             "else false",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return false if parent.tombstone.present?
      return true if anonymous_show?
      return true if current_ability.can?( :edit, id )
      return true if published?
      return false if parent.embargoed?
      false
    end

    def creator_for_json
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "parent.class.name=#{@parent.class.name}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      authors = ""
      parent.creator.each do |author|
        authors +=  "{ \"@type\": \"Person\",
                      \"name\": \"#{author}\"},"
      end
      # remove last comma
      authors[0...-1]
    end

    def create_cc_for_json
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "parent.class.name=#{@parent.class.name}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      if parent.rights_license[0] == "http://creativecommons.org/publicdomain/zero/1.0/"
        "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication"
      elsif parent.rights_license[0] == "http://creativecommons.org/licenses/by/4.0/"
        "Attribution 4.0 International (CC BY 4.0)"
      elsif parent.rights_license[0] == "http://creativecommons.org/licenses/by-nc/4.0/"
        "Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)"
      elsif parent.rights_license_other.blank?
        ''
      else
        parent.rights_license_other.first
      end
    end

    def curation_notes_admin
      rv = @solr_document.curation_notes_admin
      return rv
    end

    def curation_notes_user
      rv = @solr_document.curation_notes_user
      return rv
    end

    def current_user_can_edit?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_ability.current_user&.email=#{current_ability.current_user&.email}",
                                             "parent_data_set.edit_users=#{parent_data_set.edit_users}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return false unless current_ability.current_user.present?
      return false unless current_ability.current_user.email.present?
      parent_data_set.edit_users.include? current_ability.current_user.email
    end

    def current_user_can_read?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_ability.current_user&.email=#{current_ability.current_user&.email}",
                                             "parent_data_set.read_users=#{parent_data_set.read_users}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return false unless current_ability.current_user.present?
      return false unless current_ability.current_user.email.present?
      parent_data_set.read_users.include? current_ability.current_user.email
    end

    def description_file_set
      rv = @solr_document.description_file_set
      return rv.first if rv.present?
      rv
    end

    def download_path_link( main_app:, curation_concern: solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "main_app.class.name=#{main_app.class.name}",
                                             "id=#{id}",
                                             "anonymous_show?=#{anonymous_show?}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return "/data/downloads/#{curation_concern.id}" unless anonymous_show? # TODO: fix
      # return Rails.application.routes.url_helpers.url_for( only_path: true,
      #                                                      action: 'show',
      #                                                      controller: 'downloads',
      #                                                      id: curation_concern.id ) unless anonymous_show?
      return download_path_anonymous_link( main_app: main_app, curation_concern: curation_concern ) if anonymous_show?
      return download_path_single_use_link( main_app: main_app, curation_concern: curation_concern ) if single_use_show?
      return "/data/downloads/#{curation_concern.id}"
    end

    def download_path_anonymous_link( main_app:, curation_concern: solr_document )
      debug_verbose = ds_file_set_presenter_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      anon_link = anonymous_link_find_or_create( main_app: main_app,
                                                 curation_concern: curation_concern,
                                                 link_type: 'download' )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             "anon_link.download_key=#{anon_link.download_key}",
                                             "anon_link.item_id=#{anon_link.item_id}",
                                             "anon_link.path=#{anon_link.path}",
                                             "" ] if debug_verbose
      rv = "/data/anonymous_link/download/#{anon_link.download_key}" # TODO: fix
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if debug_verbose
      # return "/data/downloads/#{curation_concern.id}/anonymous_link/#{anon_link.download_key}" # TODO: fix
      return rv
    end

    def download_path_single_use_link( main_app:, curation_concern: solr_document )
      su_link = single_use_link_download( main_app: main_app, curation_concern: curation_concern )
      debug_verbose = ds_file_set_presenter_debug_verbose || ::Hyrax::SingleUseLinkService.single_use_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "su_link.download_key=#{su_link.download_key}",
                                             "su_link.item_id=#{su_link.item_id}",
                                             "su_link.path=#{su_link.path}",
                                             "" ] if debug_verbose
      rv = "/data/single_use_link/download/#{su_link.download_key}" # TODO: fix
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if debug_verbose
      # return "/data/downloads/#{curation_concern.id}/single_use_link/#{su_link.download_key}" # TODO: fix
      return rv
    end

    def embargoed?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_document.visibility=#{solr_document.visibility}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      solr_document.visibility == 'embargo'
    end

    def file_name( parent_presenter, link_to )
      if parent_presenter.tombstone.present?
        rv = link_name
      elsif file_size_too_large_to_download?
        rv = link_name
      else
        rv = link_to
      end
      return rv
    end

    def file_set
      @file_set ||= ::Deepblue::WorkViewContentService.content_find_by_id( id: id )
    end

    def file_contents
      return "" unless file_set.present?
      content = ::Deepblue::WorkViewContentService.content_read_file( file_set: file_set )
      return "" if content.nil?
      return content
    end

    def file_size
      size = @solr_document.file_size
      return 0 if size.nil?
      size
    end

    def file_size_human_readable
      size = file_size
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( size, precision: 3 )
    end

    def file_size_too_large_to_download?
      size = @solr_document.file_size
      return false if size.nil?
      size >= DeepBlueDocs::Application.config.max_file_size_to_download
    end

    def first_title
      title.first
    end

    def is_tabbed?
      return true if current_ability.admin?
      false
    end

    def json_metadata_properties
      ::FileSet.metadata_keys_json
    end

    def itemscope_itemtype
      if parent.itemtype == "http://schema.org/Dataset"
        "http://schema.org/CreativeWork"
      else
        "http://schema.org/Dataset"
      end
    end

    # To handle large files.
    def link_name( truncate: true )
      if ( current_ability.admin? || current_ability.can?(:read, id) )
        title_first( truncate: truncate )
      else
        'File'
      end
    end

    def member_thumbnail_url_options( member )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "member.can_download_file?=#{member.can_download_file?}",
                                             "member.anonymous_show?=#{member.anonymous_show?}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      suppress_link = !member.can_download_file? || member.anonymous_show?
      { suppress_link: suppress_link }
    end

    def parent
      parent_presenter
    end

    def parent_presenter
      @parent_presenter ||= fetch_parent_presenter
    end

    def fetch_parent_presenter
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      ids = ActiveFedora::SolrService.query("{!field f=member_ids_ssim}#{id}",
                                            fl: ActiveFedora.id_field)
                .map { |x| x.fetch(ActiveFedora.id_field) }
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "id=#{id}",
      #                                        "ids=#{ids}",
      #                                        "" ] if ds_file_set_presenter_debug_verbose
      rv = Hyrax::PresenterFactory.build_for(ids: ids,
                                        presenter_class: WorkShowPresenter,
                                        presenter_args: current_ability).first
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "id=#{id}",
      #                                        "rv=#{rv}",
      #                                        "rv.class.name=#{rv.class.name}",
      #                                        "" ] if ds_file_set_presenter_debug_verbose
      return rv
    end

    def parent_data_set
      @parent_data_set ||= DataSet.find parent.id
    end

    def parent_doi_minted?
      parent_data_set.doi_minted?
    end

    def parent_public?
      parent_data_set.public?
    end

    def parent_workflow
      parent.workflow
    end

    def pending_publication?
      parent.workflow.state != 'deposited'
    end

    def published?
      # ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "parent.workflow.state=#{parent.workflow.state}",
      #                                        "solr_document.visibility=#{solr_document.visibility}",
      #                                        "" ] ds_file_set_presenter_debug_verbose
      parent.workflow.state == 'deposited' && solr_document.visibility == 'open'
    end

    def relative_url_root
      rv = ::DeepBlueDocs::Application.config.relative_url_root
      return rv if rv
      ''
    end

    def show_anonymous_link_section?
      debug_verbose = ds_file_set_presenter_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if anonymous_show?=#{anonymous_show?}",
                                             "false if published?=#{published?}",
                                             "" ] if debug_verbose
      return false if anonymous_show?
      return false if published?
      true
    end

    def show_path_link( main_app:, curation_concern: solr_document )
      debug_verbose = ds_file_set_presenter_debug_verbose || ::Hyrax::AnonymousLinkService.anonymous_link_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "id=#{id}",
                                             "anonymous_show?=#{anonymous_show?}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return "/data/concern/file_sets/#{id}" unless anonymous_show? # TODO: fix
      if anonymous_use_show?
        anon_link = anonymous_link_show( main_app: main_app, curation_concern: curation_concern )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "anon_link=#{anon_link}",
                                               "anon_link.download_key=#{anon_link.download_key}",
                                               "anon_link.item_id=#{anon_link.item_id}",
                                               "anon_link.path=#{anon_link.path}",
                                               "" ] if debug_verbose
        rv = "/data/anonymous_link/show/#{anon_link.download_key}" # TODO: fix
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if debug_verbose
        # return "/data/downloads/#{curation_concern.id}/anonymous_link/#{su_link.download_key}" # TODO: fix
      end
      if single_use_show?
        su_link = single_use_link_show( main_app: main_app, curation_concern: curation_concern )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "su_link=#{su_link}",
                                               "su_link.download_key=#{su_link.download_key}",
                                               "su_link.item_id=#{su_link.item_id}",
                                               "su_link.path=#{su_link.path}",
                                               "" ] if ds_file_set_presenter_debug_verbose
        rv = "/data/single_use_link/show/#{su_link.download_key}" # TODO: fix
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if ds_file_set_presenter_debug_verbose
        # return "/data/downloads/#{curation_concern.id}/single_use_link/#{su_link.download_key}" # TODO: fix
      end
      return rv
    end

    def single_use_link_create_download( main_app:, curation_concern: solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      user_id = nil
      user_id = current_ability.current_user.id unless anonymous_show?
      rv = SingleUseLink.create( item_id: curation_concern.id,
                                 path: "/data/downloads/#{curation_concern.id}", # TODO: fix
                                 user_id: user_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "rv.download_key=#{rv.download_key}",
                                             "rv.item_id=#{rv.item_id}",
                                             "rv.path=#{rv.path}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return rv
    end

    def single_use_link_create_show( main_app:, curation_concern: solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      path = "/data/concern/file_sets/#{curation_concern.id}" # TODO: fix
      user_id = nil
      user_id = current_ability.current_user.id unless anonymous_show?
      rv = SingleUseLink.create( item_id: curation_concern.id,
                                 path: path,
                                 user_id: user_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "rv.download_key=#{rv.download_key}",
                                             "rv.item_id=#{rv.item_id}",
                                             "rv.path=#{rv.path}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return rv
    end

    def single_use_link_download( main_app:, curation_concern: solr_document )
      @single_use_link_download ||= single_use_link_create_download( main_app: main_app, curation_concern: curation_concern )
    end

    def single_use_link_presenter_class
      SingleUseLinkPresenter
    end

    def single_use_link_show( main_app:, curation_concern: solr_document )
      @single_use_link_show ||= single_use_link_create_show( main_app: main_app, curation_concern: curation_concern )
    end

    def single_use_links
      @single_use_links ||= single_use_links_init
    end

    def single_use_links_init
      su_links = SingleUseLink.where( item_id: id, user_id: current_ability.current_user.id )
      su_links = su_links.select do |su_link|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "su_link=#{su_link}",
                                               "su_link.valid?=#{su_link.valid?}",
                                               "su_link.expired?=#{su_link.expired?}",
                                               "su_link.item_id=#{su_link.item_id}",
                                               "su_link.path=#{su_link.path}",
                                               "su_link.user_id=#{su_link.user_id}",
                                               "" ] if ds_file_set_presenter_debug_verbose
        if su_link.expired?
          su_link.delete
          false
        else
          true
        end
      end
      su_links.map { |link| single_use_link_presenter_class.new(link) }
    end

    def single_use_show?
      cc_single_use_link.present? || cc_parent_single_use_link.present?
    end

    def thumbnail_post_process( tag:, main_app: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "tag.class.name=#{tag.class.name}",
                                             "tag=#{tag}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return tag if tag.blank?
      rv = tag.to_s.dup
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv.class.name=#{rv.class.name}",
                                             "rv=#{rv}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      rv.gsub!( 'data-context-href', 'data-reference' )
      # TODO: make sure that icon does not have a download link
      # TODO: need to figure out the type of the show?
      if anonymous_show?
        rv.gsub!( /\/(data\/)?concern\/file_sets\/[^\?]+(\?locale=[^"']+)?/, download_path_link( main_app: main_app,
                                                                                                 curation_concern: solr_document ) )
      else
        rv.gsub!( 'concern/file_sets', 'downloads' )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if ds_file_set_presenter_debug_verbose
      return rv
    end

    def tombstone_permissions_hack?
      false
    end

    def user_can_perform_any_action?
      can_view_file? || can_download_file? || can_edit_file? || can_delete_file?
    end

    # begin display_provenance_log

    def display_provenance_log_enabled?
      true
    end

    def provenance_log_entries?
      file_path = Deepblue::ProvenancePath.path_for_reference( id )
      File.exist? file_path
    end

    # end display_provenance_log

    def title_first( truncate: true )
      # sometimes files don't have titles, this can happen for lost and found files
      rv = title&.first
      return 'File' if rv.blank?
      return truncate(rv, length: 40, omission: "...#{rv[-5, 5]}") if truncate
      return rv
    end

    def tombstone
      solr_value = @solr_document['tombstone_ssim']
      return nil if solr_value.blank?
      solr_value.first
    end

    def tombstone_enabled?
      true
    end

  end

end
