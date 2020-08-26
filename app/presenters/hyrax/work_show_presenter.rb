# frozen_string_literal: true

require File.join(Gem::Specification.find_by_name("hyrax").full_gem_path, "app/presenters/hyrax/work_show_presenter.rb")

# monkey patch Hyrax::WorkShowPresenter
module Hyrax

  class WorkShowPresenter

    WORK_SHOW_PRESENTER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.work_show_presenter_debug_verbose

    attr_accessor :cc_single_use_link

    def zip_download_link( curation_concern = solr_document )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return "id is nil" if id.nil?
      curation_concern = ActiveFedora::Base.find( id ) if curation_concern.nil?
      # return "curation_concern.nil?=#{curation_concern.nil?}"
      url = zip_download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "url=#{url}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return url
    end

    def single_use_link_create_download( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      rv = SingleUseLink.create( itemId: curation_concern.id,
                                 path: "/data/concern/data_sets/#{id}/single_use_link_zip_download" )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return rv
    end

    def single_use_link_download( curation_concern )
      @single_use_link_download ||= single_use_link_create_download( curation_concern )
    end

    def zip_download_path_link( curation_concern )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "single_use_show?=#{single_use_show?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return curation_concern.for_zip_download_route unless single_use_show?
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
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      rv = "/data/single_use_link/download/#{su_link.downloadKey}" # TODO: fix
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      # return "/data/downloads/#{curation_concern.id}/single_use_link/#{su_link.downloadKey}" # TODO: fix
      return rv
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
      cc_single_use_link.present?
    end

    def can_delete_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "return false if single_use_show?=#{single_use_show?}",
                                             "doi_minted?=#{doi_minted?}",
                                             "current_ability.admin?=#{current_ability.admin?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
      return false if doi_minted?
      return true if current_ability.admin?
      can_edit_work?
    end

    def can_display_provenance_log?
      return false unless display_provenance_log_enabled?
      return false if single_use_show?
      current_ability.admin?
    end

    def can_download_using_globus?
      return false unless globus_enabled?
      return false if single_use_show?
      return true if current_ability.admin?
      return false if solr_document.visibility == "embargo"
      true
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
                                             "false if zip_download_enabled?=#{zip_download_enabled?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "false if solr_document.visibility == 'embargo'=#{solr_document.visibility == 'embargo'}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false unless zip_download_enabled?
      return true if current_ability.admin?
      return false if solr_document.visibility == 'embargo'
      true
    end

    def can_edit_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if single_use_show?=#{single_use_show?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "true if editor?=#{editor?}",
                                             "and workflow.state != 'deposited'=#{workflow.state != 'deposited'}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if single_use_show?
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
                                             "false if single_use_show?=#{single_use_show?}",
                                             "true if current_ability.admin?=#{current_ability.admin?}",
                                             "current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false unless doi_minting_enabled?
      return false if tombstone.present?
      return false if doi_pending? || doi_minted?
      return false if single_use_show?
      return true if current_ability.admin?
      current_ability.can?( :edit, id )
    end

    def can_perform_workflow_actions?
      return true if current_ability.admin?
      return false unless current_ability.current_user.present?
      return true if depositor == current_ability.current_user.email
      return true if current_ability.current_user.user_approver?( current_ability.current_user )
      return false
    end

    def can_view_work?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false if tombstone.present?=#{tombstone.present?}",
                                             "true if single_use_show?=#{single_use_show?}",
                                             "true if current_ability.can?( :edit, id )=#{current_ability.can?( :edit, id )}",
                                             "true if current_user.present? && current_user.user_approver?( current_user )=#{current_user.present? && current_user.user_approver?( current_user )}",
                                             "false if workflow.state != 'deposited'=#{workflow.state != 'deposited'}",
                                             "current_user_can_read?=#{current_user_can_read?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false if tombstone.present?
      return true if single_use_show?
      return true if current_ability.can?( :edit, id )
      return true if current_user.present? && current_user.user_approver?( current_user )
      return false if workflow.state != 'deposited'
      current_user_can_read?
    end

    def itemscope_itemtype
      if itemtype == "http://schema.org/Dataset"
        "http://schema.org/CreativeWork"
      else
        "http://schema.org/Dataset"
      end
    end

    def member_presenters( ids = member_presenter_factory.ordered_ids,
                           presenter_class = member_presenter_factory.composite_presenter_class )
      @work_show_member_presenters ||= member_presenters_init( ids, presenter_class )
    end

    def member_presenters_init( ids = member_presenter_factory.ordered_ids,
                                presenter_class = member_presenter_factory.composite_presenter_class )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "cc_single_use_link=#{cc_single_use_link}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      presenters = member_presenter_factory.member_presenters( ids, presenter_class )
      return presenters if cc_single_use_link.blank?
      presenters.each do |member_presenter|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "member_presenter.class.name=#{member_presenter.class.name}",
                                               "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
        if member_presenter.respond_to? :cc_parent_single_use_link
          member_presenter.cc_parent_single_use_link = cc_single_use_link
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "member_presenter.cc_parent_single_use_link=#{member_presenter.cc_parent_single_use_link}",
                                                 "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
        end
      end
      presenters
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
