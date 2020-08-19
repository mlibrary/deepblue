# frozen_string_literal: true

require File.join(Gem::Specification.find_by_name("hyrax").full_gem_path, "app/presenters/hyrax/work_show_presenter.rb")

# monkey patch Hyrax::WorkShowPresenter
module Hyrax

  class WorkShowPresenter

    WORK_SHOW_PRESENTER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.work_show_presenter_debug_verbose

    attr_accessor :single_use_link

    def single_use_link_create_download( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      rv = SingleUseLink.create( itemId: curation_concern.id, path: "/data/download/#{curation_concern.id}" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    def single_use_link_create_zip_download( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      rv = SingleUseLink.create( itemId: curation_concern.id, path: "/data/download/#{curation_concern.id}.zip" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    def single_use_link_download( curation_concern )
      @single_use_link_download ||= single_use_link_create_download( curation_concern )
    end

    def single_use_link_zip_download( curation_concern )
      @single_use_link_download ||= single_use_link_create_zip_download( curation_concern )
    end

    def single_use_links
      @single_use_links ||= single_use_links_init
    end

    def single_use_links_init
      su_links = SingleUseLink.where( itemId: id )
      su_links.each do |su_link|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "su_link=#{su_link}",
                                               "su_link.valid?=#{su_link.valid?}",
                                               "su_link.itemId=#{su_link.itemId}",
                                               "su_link.path=#{su_link.path}",
                                               "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      end
      su_links.map { |link| link_presenter_class.new(link) }
    end

    def single_use_show?
      false
    end

    def can_delete_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "doi_minted?=#{doi_minted?}",
                                             "current_ability.admin?=#{current_ability.admin?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if doi_minted?
      return true if current_ability.admin?
      can_edit_work?
    end

    def can_download_zip_confirm?
      max_work_file_size_to_download = ::DeepBlueDocs::Application.config.max_work_file_size_to_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "max_work_file_size_to_download < total_file_size=#{max_work_file_size_to_download < total_file_size}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      max_work_file_size_to_download >= total_file_size
    end

    def can_download_zip_maybe?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "zip_download_enabled?=#{zip_download_enabled?}",
                                             "current_ability.admin?=#{current_ability.admin?}",
                                             "solr_document.visibility == 'embargo'=#{solr_document.visibility == 'embargo'}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false unless zip_download_enabled?
      return true if current_ability.admin?
      return false if solr_document.visibility == 'embargo'
      true
    end

    def can_edit_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "current_ability.admin?=#{current_ability.admin?}",
                                             "editor?=#{editor?}",
                                             "workflow.state != 'deposited'=#{workflow.state != 'deposited'}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return true if current_ability.admin?
      return true if editor? && workflow.state != 'deposited'
      false
    end

    def can_mint_doi_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false unless doi_minting_enabled?=#{doi_minting_enabled?}",
                                             "true if doi_pending?=#{doi_pending?}",
                                             "true if doi_minted?=#{doi_minted?}",
                                             "current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false unless doi_minting_enabled?
      return false if tombstone.present?
      return false if doi_pending? || doi_minted?
      return true if current_ability.admin?
      current_ability.can?( :edit, id )
    end

    def can_view_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if tombstone.present?=#{tombstone.present?}",
                                             "true if current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "true if current_user.user_approver?( current_user )=#{current_user.user_approver?( current_user )}",
                                             "false if workflow.state != 'deposited'=#{workflow.state != 'deposited'}",
                                             "current_user_can_read?=#{current_user_can_read?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if tombstone.present?
      return true if current_ability.can?( :edit, id )
      return true if current_user.user_approver?( current_user )
      return false if workflow.state != 'deposited'
      current_user_can_read?
    end

    def download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "single_use_show?=#{single_use_show?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return single_use_link_download( curation_concern ).path if single_use_show?
      "/data/download/#{curation_concern.id}" # TODO: fix
    end

    def itemscope_itemtype
      if itemtype == "http://schema.org/Dataset"
        "http://schema.org/CreativeWork"
      else
        "http://schema.org/Dataset"
      end
    end

    def page_title
      part1 = human_readable_type
      part1 = "Data Set" if part1 == "Work"
      "#{part1} | #{title.first} | ID: #{id} | #{I18n.t('hyrax.product_name')}"
    end

    def relative_url_root
      rv = ::DeepBlueDocs::Application.config.relative_url_root
      return rv if rv
      ''
    end

    def tombstone
      solr_value = @solr_document[Solrizer.solr_name('tombstone', :symbol)]
      return nil if solr_value.blank?
      solr_value.first
    end

    def tombstone_enabled?
      true
    end

    private

      def link_presenter_class
        SingleUseLinkPresenter
      end

  end

end
