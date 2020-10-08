# frozen_string_literal: true

module Hyrax

  class DsFileSetPresenter < Hyrax::FileSetPresenter

    DS_FILE_SET_PRESENTER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.ds_file_set_presenter_debug_verbose

    include Deepblue::DeepbluePresenterBehavior

    delegate :doi,
             :doi_minted?,
             :doi_minting_enabled?,
             :doi_pending?,
             :file_size,
             :original_checksum,
             :mime_type,
             :title,
             :virus_scan_service,
             :virus_scan_status,
             :virus_scan_status_date, to: :solr_document

    attr_accessor :cc_single_use_link
    attr_accessor :cc_parent_single_use_link
    attr_accessor :parent_presenter

    def initialize( solr_document, current_ability, request = nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      super( solr_document, current_ability, request )
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
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false unless ::Deepblue::FileContentHelper.read_me_file_set_enabled
      return false if Array( parent.read_me_file_set_id ).first == id
      return false unless ::Deepblue::FileContentHelper.read_me_file_set_view_mime_types.include? mime_type
      return false if file_size > ::Deepblue::FileContentHelper.read_me_file_set_view_max_size
      return can_edit_file?
    end

    def can_delete_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if single_use_show?=#{single_use_show?}",
                                             "false if doi_minted?=#{doi_minted?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             # "false if parent_doi_minted?=#{parent_doi_minted?}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
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
                                           "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false unless ::DeepBlueDocs::Application.config.file_sets_contents_view_allow
      return false if single_use_show?
      return false unless ( current_ability.admin? ) # || current_ability.can?(:read, id) )
      return false unless ::DeepBlueDocs::Application.config.file_sets_contents_view_mime_types.include?( mime_type )
      return false if file_size.blank?
      return false if file_size > ::DeepBlueDocs::Application.config.file_sets_contents_view_max_size
      return true
    end

    def can_display_provenance_log?
      return false unless display_provenance_log_enabled?
      return false if single_use_show?
      current_ability.admin?
    end

    def can_download_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if file_size_too_large_to_download?=#{file_size_too_large_to_download?}",
                                             "true if single_use_show?=#{single_use_show?}",
                                             "true if current_ability.can?( :download, id )=#{current_ability.can?( :download, id )}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE

      return false if file_size_too_large_to_download?
      return true if single_use_show?
      return true if current_ability.can?( :download, id )
      false
    end

    def can_download_file_confirm?
      size = file_size
      max_file_size_to_download = ::DeepBlueDocs::Application.config.max_file_size_to_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "max_file_size_to_download < size=#{max_file_size_to_download < size}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      max_file_size_to_download >= size
    end

    def can_download_file_maybe?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "true if single_use_show?=#{single_use_show?}",
                                             "true current_ability.admin?=#{current_ability.admin?}",
                                             "false if embargoed?=#{embargoed?}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return true if single_use_show?
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
                                             "false if single_use_show?=#{single_use_show?}",
                                             "false if parent.tombstone.present?=#{parent.tombstone.present?}",
                                             "true current_ability.admin?=#{current_ability.admin?}",
                                             "true editor?=#{editor?}",
                                             "and pending_publication?=#{pending_publication?}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
      return false if parent.tombstone.present?
      return true if current_ability.admin?
      return true if editor? && pending_publication?
      false
    end

    def can_mint_doi_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false unless doi_minting_enabled?=#{doi_minting_enabled?}",
                                             "false if single_use_show?=#{single_use_show?}",
                                             "false if parent.tombstone.present?=#{parent.tombstone.present?}",
                                             "true if doi_pending?=#{doi_pending?}",
                                             "true if doi_minted?=#{doi_minted?}",
                                             "current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false unless doi_minting_enabled?
      return false if single_use_show?
      return false if parent.tombstone.present?
      return false if doi_pending? || doi_minted?
      return true if current_ability.admin?
      current_ability.can?( :edit, id )
    end

    def can_view_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if parent.tombstone.present?=#{parent.tombstone.present?}",
                                             "true if single_use_show?=#{single_use_show?}",
                                             "true if current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "true if published?=#{published?}",
                                             "false if parent.embargoed?=#{parent.embargoed?}",
                                             "else false",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false if parent.tombstone.present?
      return true if single_use_show?
      return true if current_ability.can?( :edit, id )
      return true if published?
      return false if parent.embargoed?
      false
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
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false unless current_ability.current_user.present?
      return false unless current_ability.current_user.email.present?
      parent_data_set.edit_users.include? current_ability.current_user.email
    end

    def current_user_can_read?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_ability.current_user&.email=#{current_ability.current_user&.email}",
                                             "parent_data_set.read_users=#{parent_data_set.read_users}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false unless current_ability.current_user.present?
      return false unless current_ability.current_user.email.present?
      parent_data_set.read_users.include? current_ability.current_user.email
    end

    def description_file_set
      rv = @solr_document.description_file_set
      return rv.first if rv.present?
      rv
    end

    def download_path_link( curation_concern = solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "single_use_show?=#{single_use_show?}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return "/data/downloads/#{curation_concern.id}" unless single_use_show? # TODO: fix
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
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      rv = "/data/single_use_link/download/#{su_link.downloadKey}" # TODO: fix
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      # return "/data/downloads/#{curation_concern.id}/single_use_link/#{su_link.downloadKey}" # TODO: fix
      return rv
    end

    def embargoed?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_document.visibility=#{solr_document.visibility}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      solr_document.visibility == 'embargo'
    end

    def show_path_link( curation_concern = solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "id=#{id}",
                                             "single_use_show?=#{single_use_show?}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return "/data/concern/file_sets/#{id}" unless single_use_show? # TODO: fix
      su_link = single_use_link_show( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "su_link.downloadKey=#{su_link.downloadKey}",
                                             "su_link.itemId=#{su_link.itemId}",
                                             "su_link.path=#{su_link.path}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      rv = "/data/single_use_link/show/#{su_link.downloadKey}" # TODO: fix
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      # return "/data/downloads/#{curation_concern.id}/single_use_link/#{su_link.downloadKey}" # TODO: fix
      return rv
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
    def link_name
      if ( current_ability.admin? || current_ability.can?(:read, id) )
        first_title
      else
        'File'
      end
    end

    def member_thumbnail_url_options( member )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "member.can_download_file?=#{member.can_download_file?}",
                                             "member.single_use_show?=#{member.single_use_show?}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      suppress_link = !member.can_download_file? || member.single_use_show?
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
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      ids = ActiveFedora::SolrService.query("{!field f=member_ids_ssim}#{id}",
                                            fl: ActiveFedora.id_field)
                .map { |x| x.fetch(ActiveFedora.id_field) }
      Hyrax::PresenterFactory.build_for(ids: ids,
                                        presenter_class: WorkShowPresenter,
                                        presenter_args: current_ability).first
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
      #                                        "" ] DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      parent.workflow.state == 'deposited' && solr_document.visibility == 'open'
    end

    def relative_url_root
      rv = ::DeepBlueDocs::Application.config.relative_url_root
      return rv if rv
      ''
    end

    def single_use_link_create_download( curation_concern = solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      user_id = nil
      user_id = current_ability.current_user.id unless single_use_show?
      rv = SingleUseLink.create( itemId: curation_concern.id,
                                 path: "/data/downloads/#{curation_concern.id}", # TODO: fix
                                 user_id: user_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "rv.downloadKey=#{rv.downloadKey}",
                                             "rv.itemId=#{rv.itemId}",
                                             "rv.path=#{rv.path}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    def single_use_link_create_show( curation_concern = solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.class.name=#{curation_concern.class.name}",
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      path = "/data/concern/file_sets/#{curation_concern.id}" # TODO: fix
      user_id = nil
      user_id = current_ability.current_user.id unless single_use_show?
      rv = SingleUseLink.create( itemId: curation_concern.id,
                                 path: path,
                                 user_id: user_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "rv.downloadKey=#{rv.downloadKey}",
                                             "rv.itemId=#{rv.itemId}",
                                             "rv.path=#{rv.path}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    def single_use_link_download( curation_concern = solr_document )
      @single_use_link_download ||= single_use_link_create_download( curation_concern )
    end

    def single_use_link_show( curation_concern = solr_document )
      @single_use_link_show ||= single_use_link_create_show( curation_concern )
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
                                               "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
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
      cc_single_use_link.present? || cc_parent_single_use_link.present?
    end

    def thumbnail_post_process( tag )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "tag.class.name=#{tag.class.name}",
                                             "tag=#{tag}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return tag if tag.blank?
      rv = tag.to_s.dup
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv.class.name=#{rv.class.name}",
                                             "rv=#{rv}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      rv.gsub!( 'data-context-href', 'data-reference' )
      # TODO: make sure that icon does not have a download link
      if single_use_show?
        rv.gsub!( /\/(data\/)?concern\/file_sets\/[^\?]+(\?locale=[^"']+)?/, download_path_link( solr_document ) )
      else
        rv.gsub!( 'concern/file_sets', 'downloads' )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
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

    def tombstone
      solr_value = @solr_document[Solrizer.solr_name('tombstone', :symbol)]
      return nil if solr_value.blank?
      solr_value.first
    end

    def tombstone_enabled?
      true
    end

  end

end
