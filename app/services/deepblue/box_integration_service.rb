# frozen_string_literal: true

module Deepblue

  module BoxIntegrationService

    @@_setup_ran = false
    @@_setup_failed = false

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
