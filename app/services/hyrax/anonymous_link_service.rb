# frozen_string_literal: true

module Hyrax

  class AnonymousLinkService

    INVALID_ANONYMOUS_LINK = ''.freeze

    mattr_accessor :enable_anonymous_links, default: true

    mattr_accessor :anonymous_link_controller_behavior_debug_verbose, default: false
    mattr_accessor :anonymous_link_service_debug_verbose, default: false
    mattr_accessor :anonymous_links_controller_debug_verbose, default: false
    mattr_accessor :anonymous_links_viewer_controller_debug_verbose, default: false

    mattr_accessor :anonymous_link_show_delete_button, default: false
    mattr_accessor :anonymous_link_destroy_if_published, default: true
    mattr_accessor :anonymous_link_destroy_if_tombstoned, default: true

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end
    # NOTE: only destroy anonymous links to published, tombstoned, deleted works
    def self.anonymous_link_destroy!( anon_link )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link=#{anon_link}",
                                             # "::Hyrax::AnonymousLinkService.anonymous_link_but_not_really=#{::Hyrax::AnonymousLinkService.config.anonymous_link_but_not_really}",
                                             "" ] if anonymous_link_service_debug_verbose
      # return if ::Hyrax::AnonymousLinkService.anonymous_link_but_not_really
      return unless anon_link.is_a? AnonymousLink
      rv = anon_link.destroy!
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv = anon_link.destroy!=#{rv}",
                                             "" ] if anonymous_link_service_debug_verbose
      return rv
    end

    def self.anonymous_link_valid?( anon_link, item_id: nil, path: nil, destroy_if_not_valid: false )
      return false unless anon_link.is_a? AnonymousLink
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "anon_link.valid?=#{anon_link.valid?}",
                                             "anon_link.itemId=#{anon_link.itemId}",
                                             "anon_link.path=#{anon_link.path}",
                                             "item_id=#{item_id}",
                                             "path=#{path}",
                                             "destroy_if_not_valid=#{destroy_if_not_valid}",
                                             "" ] if anonymous_link_service_debug_verbose
      return destroy_if_necessary_and_return_rv( destroy_flag: destroy_if_not_valid,
                                                 rv: false,
                                                 anon_link: anon_link ) unless anon_link.valid?
      if item_id.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "item_id=#{item_id}",
                                               "anon_link.itemId=#{anon_link.itemId}",
                                               "destroy unless?=#{anon_link.itemId == item_id}",
                                               "" ] if anonymous_link_service_debug_verbose
        return destroy_if_necessary_and_return_rv( destroy_flag: destroy_if_not_valid,
                                                   rv: false,
                                                   anon_link: anon_link ) unless anon_link.itemId == item_id
      end
      if path.present?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "path=#{path}",
                                               "anon_link.path=#{anon_link.path}",
                                               "destroy unless?=#{anon_link.path_eq? path}",
                                               "" ] if anonymous_link_service_debug_verbose
        return destroy_if_necessary_and_return_rv( destroy_flag: destroy_if_not_valid,
                                                   rv: false,
                                                   anon_link: anon_link ) unless anon_link.path_eq? path
      end
      return true
    end

    def self.destroy_if_necessary_and_return_rv( destroy_flag:, rv:, anon_link: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "rv=#{rv}",
                                             "destroy_flag=#{destroy_flag}",
                                             "" ] if anonymous_link_service_debug_verbose
      anonymous_link_destroy! anon_link if destroy_flag
      return rv
    end

    def self.find_anonymous_link_obj( link_id: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "link_id=#{link_id}",
                                             "" ] if anonymous_link_service_debug_verbose
      return INVALID_ANONYMOUS_LINK if link_id.blank?
      anon_link = AnonymousLink.find_by_downloadKey!( link_id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "link_id=#{link_id}",
                                             "anon_link=#{anon_link}",
                                             "anon_link.itemId=#{anon_link.itemId}",
                                             "anon_link.path=#{anon_link.path}",
                                             "" ] if anonymous_link_service_debug_verbose
      return anon_link
    rescue ActiveRecord::RecordNotFound => _ignore
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "ActiveRecord::RecordNotFound",
                                             "return invalid anonymous link",
                                             "" ] if anonymous_link_service_debug_verbose
      return INVALID_ANONYMOUS_LINK # blank, so we only try looking it up once
    end

  end

end
