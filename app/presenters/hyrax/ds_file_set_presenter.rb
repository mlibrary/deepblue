# frozen_string_literal: true

module Hyrax

  class DsFileSetPresenter < Hyrax::FileSetPresenter

    DS_FILE_SET_PRESENTER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.ds_file_set_presenter_debug_verbose

    include Deepblue::DeepbluePresenterBehavior

    delegate :doi,
             :doi_minted?,
             :doi_minting_enabled?,
             :doi_pending?,
             :original_checksum,
             :mime_type,
             :title,
             :virus_scan_service,
             :virus_scan_status,
             :virus_scan_status_date, to: :solr_document

    attr_accessor :cc_single_use_link
    attr_accessor :cc_parent_single_use_link

    def initialize( solr_document, current_ability, request = nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      super( solr_document, current_ability, request )
    end

    def current_user_can_edit?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user&.email=#{current_user&.email}",
                                             "parent_data_set.edit_users=#{parent_data_set.edit_users}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return unless current_user.present?
      parent_data_set.edit_users.include? current_user.email
    end

    def current_user_can_read?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_user&.email=#{current_user&.email}",
                                             "parent_data_set.read_users=#{parent_data_set.read_users}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return unless current_user.present?
      parent_data_set.read_users.include? current_user.email
    end

    def can_delete_file?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if single_use_show?=#{single_use_show?}",
                                             "false if doi_minted?=#{doi_minted?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "false if parent_doi_minted?=#{parent_doi_minted?}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
      return false if doi_minted?
      return true if current_ability.admin?
      return false if parent_doi_minted?
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
      max_work_file_size_to_download = ::DeepBlueDocs::Application.config.max_work_file_size_to_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "max_work_file_size_to_download < size=#{max_work_file_size_to_download < size}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      max_work_file_size_to_download >= size
    end

    def can_download_file_maybe?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if single_use_show?=#{single_use_show?}",
                                             "true current_ability.admin?=#{current_ability.admin?}",
                                             "false if solr_document.visibility == 'embargo'=#{solr_document.visibility == 'embargo'}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
      return true if current_ability.admin?
      return false if solr_document.visibility == 'embargo'
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
                                             "and parent.workflow.state != 'deposited'=#{parent.workflow.state != 'deposited'}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
      return false if parent.tombstone.present?
      return true if current_ability.admin?
      return true if editor? && parent.workflow.state != 'deposited'
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
                                             "true if parent.workflow.state == 'deposited'=#{parent.workflow.state == 'deposited'}",
                                             "current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false if parent.tombstone.present?
      return true if single_use_show?
      return true if parent.workflow.state == 'deposited'
      current_ability.can?( :edit, id )
    end

    def curation_notes_admin
      rv = @solr_document.curation_notes_admin
      return rv
    end

    def curation_notes_user
      rv = @solr_document.curation_notes_user
      return rv
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
      size >= DeepBlueDocs::Application.config.max_work_file_size_to_download
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

    def parent_data_set
      @parent_data_set ||= DataSet.find parent.id
    end

    def parent_doi_minted?
      parent_data_set.doi_minted?
    end

    def parent_public?
      parent_data_set.public?
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
                                 path: "/data/downloads/#{curation_concern.id}",
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
      su_links.each do |su_link|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "su_link=#{su_link}",
                                               "su_link.valid?=#{su_link.valid?}",
                                               "su_link.itemId=#{su_link.itemId}",
                                               "su_link.path=#{su_link.path}",
                                               "su_link.user_id=#{su_link.user_id}",
                                               "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
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
