# frozen_string_literal: true
#
module Deepblue

  module ZipDownloadPresenterBehavior

    def zip_download_allowed?
      # TODO: improve this
      current_ability.admin? || solr_document.visibility != "embargo"
    end

    def zip_download_total_file_size_too_big?
      return true if solr_document.total_file_size.blank?
      solr_document.total_file_size > ZipDownloadService.zip_download_max_total_file_size_to_download
    end

  end

end
