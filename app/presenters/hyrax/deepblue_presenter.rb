# frozen_string_literal: true

module Hyrax

  class DeepbluePresenter < Hyrax::WorkShowPresenter

    include Deepblue::DeepbluePresenterBehavior

    # include Rails.application.routes.url_helpers
    # include ActionDispatch::Routing::PolymorphicRoutes

    DEEP_BLUE_PRESENTER_DEBUG_VERBOSE = Rails.configuration.deep_blue_presenter_debug_verbose

    def box_enabled?
      false
    end

    def display_provenance_log_enabled?
      false
    end

    def doi_minting_enabled?
      false
    end

    def globus_download_enabled?
      false
    end

    def human_readable_type
      "Work"
    end

    def ld_json_creator
      if respond_to? :parent
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "parent.class.name=#{parent.class.name}",
                                               "" ] if DEEP_BLUE_PRESENTER_DEBUG_VERBOSE
        authors = parent.creator
      else
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "class.name=#{self.class.name}",
                                               "" ] if DEEP_BLUE_PRESENTER_DEBUG_VERBOSE
        authors = creator
      end
      rv = []
      authors.each do |author|
        rv << "{ \"@type\": \"Person\", \"name\": \"#{author}\" }"
      end
      return rv.join(',')
    end

    def ld_json_description
      rv = description.join(";")
      len = rv.size
      # description should be between 50 and 5000 characters in length
      rv = rv.substring( 0, 4999 ) if len > 4999
      rv = rv + " - This data set has been deposited in Deepblue Data." if len < 50
      return rv
    end

    def ld_json_identifier
      rv = ''
      rv = doi if respond_to?( :doi ) && doi.present?
      return rv
    end

    def ld_json_license
      rv = "{ \"@type\": \"CreativeWork\",\"name\": \"#{ld_json_license_name}\",\"license\": \"#{ld_json_license_url}\" }"
      return rv
    end

    def ld_json_license_name
      if respond_to? :parent
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "parent.class.name=#{parent.class.name}",
                                               "" ] if DEEP_BLUE_PRESENTER_DEBUG_VERBOSE
        license = parent.rights_license
        license_other = parent.rights_license_other
      else
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "class.name=#{self.class.name}",
                                               "" ] if DEEP_BLUE_PRESENTER_DEBUG_VERBOSE
        license = rights_license
        license_other = rights_license_other
      end
      if license == 'http://creativecommons.org/publicdomain/zero/1.0/'
        rv = 'CC0 1.0 Universal (CC0 1.0) Public Domain Dedication'
      elsif license == 'http://creativecommons.org/licenses/by/4.0/'
        rv = 'Attribution 4.0 International (CC BY 4.0)'
      elsif license == 'http://creativecommons.org/licenses/by-nc/4.0/'
        rv = 'Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)'
      elsif license.blank?
        rv = ''
      elsif 'Other' == license && license_other.present?
        rv = license_other
      else
        rv = license
      end
      return rv
    end

    def ld_json_license_url
      if respond_to? :parent
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "parent.class.name=#{parent.class.name}",
                                               "" ] if DEEP_BLUE_PRESENTER_DEBUG_VERBOSE
        license = parent.rights_license
        license_other = parent.rights_license_other
      else
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "class.name=#{self.class.name}",
                                               "" ] if DEEP_BLUE_PRESENTER_DEBUG_VERBOSE
        license = rights_license
        license_other = rights_license_other
      end
      if license.blank?
        rv = ''
      elsif 'Other' == license && license_other.present?
        rv = license_other
      else
        rv = license
      end
      return rv
    end

    def ld_json_type
      'Dataset' # TODO - this is dependent on the class
    end

    def ld_json_url
      'https://deepblue.lib.umich.edu/data/'
    end

    def member_presenter_factory
      MemberPresenterFactory.new( solr_document, current_ability, request )
    end

    def tombstone_permissions_hack?
      false
    end

  end

end
