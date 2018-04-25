# Generated via
#  `rails generate hyrax:work DataSet`
module Hyrax
  class DataSetPresenter < Hyrax::WorkShowPresenter

    # :authoremail, :date_coverage,
    delegate  :doi,
             :fundedby,
             :grantnumber,
             :isReferencedBy,
             :methodology,
             :tombstone,
             :total_file_size,
             to: :solr_document

    # def authoremail
    #   @solr_document.authoremail
    # end

    def box_enabled?
      DeepBlueDocs::Application.config.box_integration_enabled
    end

    def box_link( only_if_exists_in_box: false )
      return nil unless box_enabled?
      concern_id = @solr_document.id
      return ::BoxHelper.box_link( concern_id, only_if_exists_in_box: only_if_exists_in_box )
    end

    def box_link_display_for_work?( current_user )
      return false unless box_enabled?
      rv = ::BoxHelper.box_link_display_for_work?( work_id: @solr_document.id,
                                                   work_file_count: total_file_count,
                                                   is_admin: current_ability.admin?,
                                                   user_email: EmailHelper.user_email_from( current_user ) )
      return rv
    end

    # # display date range as from_date To to_date
    # def date_coverage
    #   return @solr_document.date_coverage.sub("/open", "") if @solr_document.date_coverage&.match("/open")
    #   @solr_document.date_coverage.sub("/", " to ") if @solr_document.date_coverage
    # end

    def doi
      @solr_document[Solrizer.solr_name('doi', :symbol)].first
    end

    def fundedby
      @solr_document.fundedby
    end

    def globus_external_url
      concern_id = @solr_document.id
      ::GlobusJob.external_url concern_id
    end

    def globus_files_available?
      concern_id = @solr_document.id
      ::GlobusJob.files_available? concern_id
    end

    def globus_files_prepping?
      concern_id = @solr_document.id
      ::GlobusJob.files_prepping? concern_id
    end

    def grantnumber
      @solr_document.grantnumber
    end

    def hdl
      #@object_profile[:hdl]
    end

    def human_readable( value )
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
    end

    def identifiers_minted?(identifier)
      #the first time this is called, doi will not be solr.
      begin
        @solr_document[Solrizer.solr_name('doi', :symbol)].first
      rescue
        nil
      end
    end

    def identifiers_pending?(identifier)
      @solr_document[Solrizer.solr_name('doi', :symbol)].first == GenericWork::PENDING
    end

    def isReferencedBy
      @solr_document.isReferencedBy
    end

    def label_with_total_file_size( label )
      total = total_file_size
      if 0 == total
        label
      else
        count = total_file_count
        files = 1 == count ? 'file' : 'files'
        "#{label} (#{total_file_size_human_readable} in #{count} #{files})"
      end
    end

    def tombstone
      if @solr_document[Solrizer.solr_name('tombstone', :symbol)].nil?
        nil
      else
        @solr_document[Solrizer.solr_name('tombstone', :symbol)].first
      end
    end

    def total_file_count
      if @solr_document[Solrizer.solr_name('file_set_ids', :symbol)].nil?
        0
      else
        @solr_document[Solrizer.solr_name('file_set_ids', :symbol)].size
      end
    end

    def total_file_size
      total = @solr_document[Solrizer.solr_name('total_file_size', Hyrax::FileSetIndexer::STORED_LONG)]
      if total.nil?
        total = 0
      end
      total
    end

    def total_file_size_human_readable
      human_readable( total_file_size )
    end

  end

end
