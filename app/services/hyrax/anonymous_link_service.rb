# frozen_string_literal: true

module Hyrax

  class AnonymousLinkService

    @@anonymous_link_service_debug_verbose = false

    @@anonymous_link_default_expiration_duration = 365.days

    @@anonymous_link_use_detailed_human_readable_time = true

    mattr_accessor :anonymous_link_service_debug_verbose,
                   :anonymous_link_default_expiration_duration,
                   :anonymous_link_use_detailed_human_readable_time

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

  end

end
