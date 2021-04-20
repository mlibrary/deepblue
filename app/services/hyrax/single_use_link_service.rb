# frozen_string_literal: true

module Hyrax

  class SingleUseLinkService

    @@single_use_link_service_debug_verbose = false

    @@single_use_link_default_expiration_duration = 365.days

    @@single_use_link_use_detailed_human_readable_time = true

    mattr_accessor :single_use_link_service_debug_verbose,
                   :single_use_link_default_expiration_duration,
                   :single_use_link_use_detailed_human_readable_time

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

  end

end
