# frozen_string_literal: true

module Deepblue

  module TotalFileSizePresenterBehavior

    # delegate :total_file_size, :total_file_size_human_readable, to: :solr_document

    def total_file_count
      solr_value = @solr_document['file_set_ids_ssim']
      return 0 if solr_value.blank?
      solr_value.size
    end

    def total_file_size
      solr_value = @solr_document['total_file_size_lts']
      return 0 if solr_value.blank?
      solr_value
    end

    def total_file_size_human_readable
      human_readable( total_file_size )
    end

    def does_work_have_no_files
      if self.file_set_presenters.present? && self.file_set_presenters.size > 0
        return false
      else
        return true
      end
    end

  end

end
