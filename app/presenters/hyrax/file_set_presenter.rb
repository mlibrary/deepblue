require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/presenters/hyrax/file_set_presenters.rb" )

module Hyrax
  class FileSetPresenter

    # Metadata Methods
    delegate :isReferencedBy, to: :solr_document

    def audit_status
      audit_service.logged_audit_status
    end

    def audit_service
      @audit_service ||= Hyrax::FileSetAuditService.new(id)
    end

    def file_name( parent_presenter, link_to )
      if parent_presenter.tombstone.present?
        rv = link_name
      elsif file_size_too_large_to_download?
        rv = link_name
      else
        rv = link_to
      end
      return rv
    end

    def file_size_too_large_to_download?
      solr_document.file_size >= DeepBlueDocs::Application.config.max_work_file_size_to_download
    end

    def rights
      return if solr_document.rights.nil?
      solr_document.rights.first
    end

    def tweeter
      user = ::User.find_by_user_key(depositor)
      if user.try(:twitter_handle).present?
        "@#{user.twitter_handle}"
      else
        I18n.translate('hyrax.product_twitter_handle')
      end
    end

  end
end
