# frozen_string_literal: true

module Hyrax

  class AnonymousLinkService

    mattr_accessor :enable_anonymous_links, default: true

    mattr_accessor :anonymous_link_controller_behavior_debug_verbose, default: false
    mattr_accessor :anonymous_link_service_debug_verbose, default: false
    mattr_accessor :anonymous_links_controller_debug_verbose, default: false
    mattr_accessor :anonymous_links_viewer_controller_debug_verbose, default: false

    # mattr_accessor :anonymous_link_but_not_really, default: false
    mattr_accessor :anonymous_link_show_delete_button, default: false

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

  end

end
