# frozen_string_literal: true
#
module Deepblue

  module ZipDownloadPresenterBehavior

    mattr_accessor :zip_download_presenter_behavior_debug_verbose
    @@zip_download_presenter_behavior_debug_verbose = ::Deepblue::ZipDownloadService.zip_download_presenter_behavior_debug_verbose

    def can_download_zip?
      can_download_zip_maybe? && can_download_zip_confirm?
    end

    def can_download_zip_confirm?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if zip_download_total_file_size_too_big?=#{zip_download_total_file_size_too_big?}",
                                             "" ] if zip_download_presenter_behavior_debug_verbose
      return false if zip_download_total_file_size_too_big?
      true
    end

    def can_download_zip_maybe?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false unless zip_download_enabled?=#{zip_download_enabled?}",
                                             "true if anonymous_show?=#{anonymous_show?}",
                                             "true if can_edit_work?=#{can_edit_work?}",
                                             "false if embargoed?=#{embargoed?}",
                                             "else true",
                                             "" ] if zip_download_presenter_behavior_debug_verbose
      return false unless zip_download_enabled?
      return true if anonymous_show?
      return true if can_edit_work?
      return false if embargoed?
      true
    end

    def zip_download_enabled?
      ::Deepblue::ZipDownloadService.zip_download_enabled
    end

    def zip_download_link( curation_concern = solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ] if zip_download_presenter_behavior_debug_verbose
      return "id is nil" if id.nil?
      curation_concern = ::PersistHelper.find( id ) if curation_concern.nil?
      # return "curation_concern.nil?=#{curation_concern.nil?}"
      url = zip_download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "url=#{url}",
                                             "" ] if zip_download_presenter_behavior_debug_verbose
      return url
    end

    def zip_download_max_total_file_size_to_download
      ::Deepblue::ZipDownloadService.zip_download_max_total_file_size_to_download
    end

    def zip_download_min_total_file_size_to_download_warn
      ::Deepblue::ZipDownloadService.zip_download_min_total_file_size_to_download_warn
    end

    def zip_download_total_file_size_too_big?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_document.total_file_size=#{solr_document.total_file_size}",
                                             "true if solr_document.total_file_size.blank? #{solr_document.total_file_size.blank?}",
                                             "" ] if zip_download_presenter_behavior_debug_verbose
      return true if solr_document.total_file_size.blank?
      solr_document.total_file_size > zip_download_max_total_file_size_to_download
    end

    def zip_download_total_file_size_warn?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_document.total_file_size=#{solr_document.total_file_size}",
                                             "false if solr_document.total_file_size.blank? #{solr_document.total_file_size.blank?}",
                                             "" ] if zip_download_presenter_behavior_debug_verbose
      return false if solr_document.total_file_size.blank?
      solr_document.total_file_size > zip_download_min_total_file_size_to_download_warn
    end

    def zip_download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "anonymous_show?=#{anonymous_show?}",
                                             "" ] if zip_download_presenter_behavior_debug_verbose
      return curation_concern.for_zip_download_route unless anonymous_show?
      # return Rails.application.routes.url_helpers.url_for( only_path: true,
      #                                                      action: 'show',
      #                                                      controller: 'downloads',
      #                                                      id: curation_concern.id ) unless anonymous_show?
      su_link = single_use_link_download( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "su_link=#{su_link}",
                                             "su_link.downloadKey=#{su_link.downloadKey}",
                                             "su_link.itemId=#{su_link.itemId}",
                                             "su_link.path=#{su_link.path}",
                                             "" ] if zip_download_presenter_behavior_debug_verbose
      rv = "/data/single_use_link/download/#{su_link.downloadKey}" # TODO: fix
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if zip_download_presenter_behavior_debug_verbose
      # return "/data/downloads/#{curation_concern.id}/single_use_link/#{su_link.downloadKey}" # TODO: fix
      return rv
    end

  end

end
