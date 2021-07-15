# frozen_string_literal: true

module Hyrax

  class AnonymousLinkService

    mattr_accessor :enable_anonymous_links, default: true
    mattr_accessor :anonymous_link_but_not_really, default: false

    mattr_accessor :anonymous_link_service_debug_verbose, default: false
    mattr_accessor :anonymous_link_default_expiration_duration, default: 365.days
    mattr_accessor :anonymous_link_use_detailed_human_readable_time, default: true

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

  end

end
