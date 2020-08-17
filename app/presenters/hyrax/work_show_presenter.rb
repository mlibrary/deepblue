# frozen_string_literal: true

require File.join(Gem::Specification.find_by_name("hyrax").full_gem_path, "app/presenters/hyrax/work_show_presenter.rb")

# monkey patch Hyrax::WorkShowPresenter
module Hyrax

  class WorkShowPresenter

    def can_delete?
      return false if doi_minted?
      return true if current_ability.admin?
      can_edit?
    end

    def can_edit?
      return true if current_ability.admin?
      return true if editor? && parent.workflow.state != 'deposited'
      false
    end

    def can_mint_doi?
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
