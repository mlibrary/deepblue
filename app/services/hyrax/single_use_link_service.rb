# frozen_string_literal: true

module Hyrax

  class SingleUseLinkService

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :enable_single_use_links, default: false

    mattr_accessor :single_use_link_controller_behavior_debug_verbose, default: false
    mattr_accessor :single_use_link_service_debug_verbose, default: false
    mattr_accessor :single_use_links_controller_debug_verbose, default: false
    mattr_accessor :single_use_links_viewer_controller_debug_verbose, default: false

    mattr_accessor :single_use_link_but_not_really, default: false
    mattr_accessor :single_use_link_default_expiration_duration, default: 365.days
    mattr_accessor :single_use_link_use_detailed_human_readable_time, default: true

  end

end
