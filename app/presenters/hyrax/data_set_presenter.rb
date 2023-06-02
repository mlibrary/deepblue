# frozen_string_literal: true

module Hyrax

  class DataSetPresenter < DeepbluePresenter

    mattr_accessor :data_set_presenter_debug_verbose, default: Rails.configuration.data_set_presenter_debug_verbose

    delegate  :authoremail,
              :creator_orcid,
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
              :ticket,
              :subject_discipline,
              :total_file_size,
              :access_deepblue,
              to: :solr_document

    attr_accessor :controller

    delegate :analytics_subscribed?,
             :active_ingest_append_script,
             :can_display_provenance_log?,
             :can_display_read_me?,
             :can_subscribe_to_analytics_reports?,
             :current_user,
             :current_user_can_edit?,
             :current_user_can_read?,
             :edit_groups,
             :edit_users,
             :ingest_allowed_base_directories,
             :enable_analytics_works_reports_can_subscribe?,
             :ingest_append_script,
             :ingest_append_script_can_delete_script?,
             :ingest_append_script_can_restart_script?,
             :ingest_append_script_can_run_a_new_script?,
             :ingest_append_script_deletable?,
             :ingest_append_script_delete_path,
             :ingest_append_script_failed?,
             :ingest_append_script_files,
             :ingest_append_script_finished?,
             :ingest_append_script_is_running?,
             :ingest_append_script_modifier?,
             :ingest_append_script_path,
             :ingest_append_script_prep_path,
             :ingest_append_script_restart_path,
             :ingest_append_script_restartable?,
             :ingest_append_script_show_modifiers,
             :ingest_append_script_view_title,
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
             :ingest_prep_tab_active,
             :ingest_script,
             :ingest_script_messages,
             :ingest_script_title,
             :ingest_use_defaults,
             :is_tabbed?,
             :params,
             :read_groups,
             :read_users,
             :read_me_text_is_html?,
             :read_me_text,
             :read_me_text_html,
             :read_me_text_simple_format,
             :tombstone_permissions_hack?,
             :work_url,
             :zip_download_enabled?, to: :controller

    # def initialize( solr_document, current_ability, request = nil )
    #   ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
    #                                          Deepblue::LoggingHelper.called_from,
    #                                          Deepblue::LoggingHelper.obj_class( 'class', self ),
    #                                          "solr_document = #{solr_document}",
    #                                          "solr_document.class.name = #{solr_document.class.name}",
    #                                          "current_ability = #{current_ability}",
    #                                          "request = #{request}",
    #                                          "" ] if data_set_presenter_debug_verbose
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
    #                                          "" ] if data_set_presenter_debug_verbose
    # end

    def controller_class
      controller.class
    end

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
                                             "" ] if data_set_presenter_debug_verbose
      file_path = ::Deepblue::ProvenancePath.path_for_reference( id )
      rv = File.exist?( file_path )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_path=#{file_path}",
                                             "rv=#{rv}",
                                             "" ] if data_set_presenter_debug_verbose
      return rv
    end

    # end display_provenance_log

    # begin globus

    def globus_bounce_external_link_off_server?
      ::Deepblue::GlobusIntegrationService.globus_bounce_external_link_off_server
    end

    def globus_download_enabled?
      ::Deepblue::GlobusIntegrationService.globus_enabled
    end

    def globus_enabled?
      ::Deepblue::GlobusIntegrationService.globus_enabled
    end

    def globus_external_url
      concern_id = @solr_document.id
      ::Deepblue::GlobusService.globus_external_url concern_id
    end

    def globus_files_available?
      concern_id = @solr_document.id
      ::Deepblue::GlobusService.globus_files_available? concern_id
    end

    def globus_files_prepping?
      concern_id = @solr_document.id
      ::Deepblue::GlobusService.globus_files_prepping? concern_id
    end

    def globus_last_error_msg
      concern_id = @solr_document.id
      ::Deepblue::GlobusService.globus_error_file_contents concern_id
    end

    def globus_error_file_exists?
      concern_id = @solr_document.id
      ::Deepblue::GlobusService.globus_error_file_exists? concern_id
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

    def ld_json_type
      "Dataset"
    end

    def ld_json_url
      "https://deepblue.lib.umich.edu/data/concern/data_sets/#{id}"
    end

    # begin tombstone

    def schema_presenter?
      return false unless self.respond_to? :title
      return false unless self.respond_to? :doi
      return false if self.respond_to? :checksum_value
      return true
    end

    def tombstone
      return nil if @solr_document.blank?
      solr_value = @solr_document['tombstone_ssim']
      return nil if solr_value.blank?
      solr_value.first
    end

    def tombstone_enabled?
      true
    end

  end

end
