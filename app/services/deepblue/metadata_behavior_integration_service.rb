# frozen_string_literal: true

module Deepblue

  module MetadataBehaviorIntegrationService

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

    mattr_accessor :metadata_behavior_debug_verbose, default: false

    mattr_accessor :metadata_field_sep, default: '; '
    mattr_accessor :metadata_report_default_depth, default: 2
    mattr_accessor :metadata_report_default_filename_post, default: '_metadata_report'
    mattr_accessor :metadata_report_default_filename_ext, default: '.txt'

  end

end
