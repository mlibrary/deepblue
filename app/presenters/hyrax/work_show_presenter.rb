# frozen_string_literal: true

require File.join(Gem::Specification.find_by_name("hyrax").full_gem_path, "app/presenters/hyrax/work_show_presenter.rb")

# monkey patch Hyrax::WorkShowPresenter
module Hyrax

  class WorkShowPresenter

    WORK_SHOW_PRESENTER_DEBUG_VERBOSE = true || ::DeepBlueDocs::Application.config.work_show_presenter_debug_verbose

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
                                             "current_ability.admin?=#{current_ability.admin?}",
                                             "doi_minting_enabled?=#{doi_minting_enabled?}",
                                             "doi_pending?=#{doi_pending?}",
                                             "doi_minted?=#{doi_minted?}",
                                             "" ] if WORK_SHOW_PRESENTER_DEBUG_VERBOSE
      return false unless current_ability.admin?
      return false unless doi_minting_enabled?
      return false if doi_pending? || doi_minted?
      true
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

  end

end
