# frozen_string_literal: true

module Deepblue

  module BoxIntegrationService

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

    @@box_enabled = false

    @@box_access_and_refresh_token_file
    @@box_access_and_refresh_token_file_init
    @@box_always_report_not_logged_in_errors = true
    @@box_create_dirs_for_empty_works = true
    @@box_developer_token
    @@box_dlib_dbd_box_user_id
    @@box_ulib_dbd_box_id
    @@box_verbose = true

    @@box_integration_enabled = false

    mattr_accessor :box_enabled,
                   :box_access_and_refresh_token_file,
                   :box_access_and_refresh_token_file_init,
                   :box_always_report_not_logged_in_errors,
                   :box_create_dirs_for_empty_works,
                   :box_developer_token,
                   :box_dlib_dbd_box_user_id,
                   :box_integration_enabled,
                   :box_ulib_dbd_box_id,
                   :box_verbose

  end

end
