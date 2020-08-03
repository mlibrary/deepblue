# frozen_string_literal: true

module Hyrax

  class DsFileSetPresenter < Hyrax::FileSetPresenter

    DS_FILE_SET_PRESENTER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.ds_file_set_presenter_debug_verbose

    delegate :doi,
             :doi_minted?,
             :doi_minting_enabled?,
             :doi_pending?,
             :file_size,
             :file_size_human_readable,
             :original_checksum,
             :mime_type,
             :title,
             :virus_scan_service,
             :virus_scan_status,
             :virus_scan_status_date, to: :solr_document

    attr_accessor :single_use_link

    def initialize( solr_document, current_ability, request = nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      super( solr_document, current_ability, request )
    end

    def single_use_links
      @single_use_links ||= init_single_use_links
    end

    def init_single_use_links
      su_links = SingleUseLink.where( itemId: id )
      su_links.each do |su_link|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "su_link=#{su_link}",
                                               "su_link.valid?=#{su_link.valid?}",
                                               "su_link.itemId=#{su_link.itemId}",
                                               "su_link.path=#{su_link.path}",
                                               "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      end
      su_links.map { |link| link_presenter_class.new(link) }
    end

    def single_use_show?
      single_use_link.present?
    end

    def single_use_link_download( curation_concern )
      @single_use_link_download ||= create_single_use_link_download( curation_concern )
    end

    def create_single_use_link_download( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      rv = SingleUseLink.create( itemId: curation_concern.id, path: "/data/download/#{curation_concern.id}" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "rv.downloadKey=#{rv.downloadKey}",
                                             "rv.itemId=#{rv.itemId}",
                                             "rv.path=#{rv.path}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    def download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "single_use_show?=#{single_use_show?}",
                                             "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return "/data/download/#{curation_concern.id}" unless single_use_show? # TODO: fix
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
      # return "/data/download/#{curation_concern.id}/single_use_link/#{su_link.downloadKey}" # TODO: fix
      return rv
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

    def display_file_contents_allowed?
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "mime_type=#{mime_type}",
                                           "file_size=#{file_size}",
                                           "" ] if DS_FILE_SET_PRESENTER_DEBUG_VERBOSE
      return false unless ::DeepBlueDocs::Application.config.file_sets_contents_view_allow
      return false unless ( current_ability.admin? ) # || current_ability.can?(:read, id) )
      return false unless ::DeepBlueDocs::Application.config.file_sets_contents_view_mime_types.include?( mime_type )
      return false if file_size.blank?
      return false if file_size > ::DeepBlueDocs::Application.config.file_sets_contents_view_max_size
      return true
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

    def file_size_too_large_to_download?
      !@solr_document.file_size.nil? && @solr_document.file_size >= DeepBlueDocs::Application.config.max_work_file_size_to_download
    end

    def first_title
      title.first
    end

    def json_metadata_properties
      ::FileSet.metadata_keys_json
    end

    # To handle large files.
    def link_name
      if ( current_ability.admin? || current_ability.can?(:read, id) )
        first_title
      else
        'File'
      end
    end
    ## User access begin

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

    ## User access end

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
