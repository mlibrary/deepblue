# frozen_string_literal: true

module Deepblue

  module MetadataBehaviorIntegrationService

    @@_setup_ran = false
    @@_setup_failed = false

    mattr_accessor :metadata_behavior_debug_verbose, default: false

    mattr_accessor :metadata_field_sep, default: '; '
    mattr_accessor :metadata_report_default_depth, default: 2
    mattr_accessor :metadata_report_default_filename_post, default: '_metadata_report'
    mattr_accessor :metadata_report_default_filename_ext, default: '.txt'

    def self.setup
      return if @@_setup_ran == true
      @@_setup_ran = true
      begin
        yield self
      rescue Exception => e # rubocop:disable Lint/RescueException
        @@_setup_failed = true
      end
    end

  end

end
