# frozen_string_literal: true

module Hyrax

  class DataSetPresenter < DeepbluePresenter

    DATA_SET_PRESENTER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.data_set_presenter_debug_verbose

    delegate  :authoremail,
              :curation_notes_admin,
              :curation_notes_user,
              :date_coverage,
              :date_published, :date_published2,
              :doi,
              :doi_minted?,
              :doi_minting_enabled?,
              :doi_pending?,
              :fundedby,
              :fundedby_other,
              :grantnumber,
              :methodology,
              :prior_identifier,
              :read_me_file_set_id,
              :referenced_by,
              :rights_license,
              :rights_license_other,
              :subject_discipline,
              :total_file_size,
              :access_deepblue,
              to: :solr_document

    attr_accessor :controller

    delegate :can_display_provenance_log?,
                  :can_display_read_me?,
                  :current_user,
                  :current_user_can_edit?,
                  :current_user_can_read?,
                  :ingest_allowed_base_directories,
                  :ingest_base_directory,
                  :ingest_depositor,
                  :ingest_email_after,
                  :ingest_email_before,
                  :ingest_email_depositor,
                  :ingest_email_ingester,
                  :ingest_email_rest,
                  :ingest_email_rest_emails,
                  :ingest_file_path_list,
                  :ingest_ingester,
                  :ingest_script,
                  :ingest_script_messages,
                  :ingest_script_title,
                  :ingest_use_defaults,
                  :is_tabbed?,
                  :params,
                  :read_me_text_is_html?,
                  :read_me_text,
                  :read_me_text_html,
                  :read_me_text_simple_format,
                  :tombstone_permissions_hack?,
                  :zip_download_enabled?, to: :controller

    # def initialize( solr_document, current_ability, request = nil )
    #   ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
    #                                          Deepblue::LoggingHelper.called_from,
    #                                          Deepblue::LoggingHelper.obj_class( 'class', self ),
    #                                          "solr_document = #{solr_document}",
    #                                          "solr_document.class.name = #{solr_document.class.name}",
    #                                          "current_ability = #{current_ability}",
    #                                          "request = #{request}",
    #                                          "" ] if DATA_SET_PRESENTER_DEBUG_VERBOSE
    #   super( solr_document, current_ability, request )
    #   ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
    #                                          Deepblue::LoggingHelper.called_from,
    #                                          Deepblue::LoggingHelper.obj_class( 'class', self ),
    #                                          "@solr_document.class.name = #{@solr_document.class.name}",
    #                                          "@solr_document.doi = #{@solr_document.doi}",
    #                                          "@solr_document.doi_the_correct_one = #{@solr_document.doi_the_correct_one}",
    #                                          "@solr_document.doi_minted? = #{@solr_document.doi_minted?}",
    #                                          "@solr_document.doi_minting_enabled? = #{@solr_document.doi_minting_enabled?}",
    #                                          "@solr_document.doi_pending? = #{@solr_document.doi_pending?}",
    #                                          "" ] if DATA_SET_PRESENTER_DEBUG_VERBOSE
    # end

    # begin box

    def box_enabled?
      ::Deepblue::BoxIntegrationService.box_integration_enabled
    end

    def box_link( only_if_exists_in_box: false )
      return nil unless box_enabled?
      # concern_id = @solr_document.id
      # return ::BoxHelper.box_link( concern_id, only_if_exists_in_box: only_if_exists_in_box )
      nil
    end

    def box_link_display_for_work?( current_user )
      return false unless box_enabled?
      # rv = ::BoxHelper.box_link_display_for_work?( work_id: @solr_document.id,
      #                                              work_file_count: total_file_count,
      #                                              is_admin: current_ability.admin?,
      #                                              user_email: Deepblue::EmailHelper.user_email_from( current_user ) )
      # return rv
      false
    end

    # end box

    # display date range as from_date To to_date
    def date_coverage
      solr_value = @solr_document.date_coverage
      return nil if solr_value.blank?
      return solr_value.sub( "/open", "" ) if solr_value.match "/open" # rubocop:disable Performance/RedundantMatch, Performance/RegexpMatch
      solr_value.sub( "/", " to " )
    end

    # begin display_provenance_log

    def display_provenance_log_enabled?
      true
    end

    def provenance_log_entries?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if DATA_SET_PRESENTER_DEBUG_VERBOSE
      file_path = ::Deepblue::ProvenancePath.path_for_reference( id )
      rv = File.exist?( file_path )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_path=#{file_path}",
                                             "rv=#{rv}",
                                             "" ] if DATA_SET_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    # end display_provenance_log

    # begin globus

    def globus_download_enabled?
      ::Deepblue::GlobusIntegrationService.globus_enabled
    end

    def globus_enabled?
      ::Deepblue::GlobusIntegrationService.globus_enabled
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

    def globus_last_error_msg
      concern_id = @solr_document.id
      ::GlobusJob.error_file_contents concern_id
    end

    # end globus

    def hdl
      # @object_profile[:hdl]
    end

    def human_readable( value )
      ActiveSupport::NumberHelper::NumberToHumanSizeConverter.convert( value, precision: 3 )
    end

    def json_metadata_properties
      ::DataSet.metadata_keys_json
    end

    def label_with_total_file_size( label )
      total = total_file_size
      return label if total.zero?
      count = total_file_count
      files = 1 == count ? 'file' : 'files'
      "#{label} (#{total_file_size_human_readable} in #{count} #{files})"
    end

    # begin tombstone

    def tombstone
      return nil if @solr_document.blank?
      solr_value = @solr_document[Solrizer.solr_name('tombstone', :symbol)]
      return nil if solr_value.blank?
      solr_value.first
    end

    def tombstone_enabled?
      true
    end

    # end tombstone

  end

end
