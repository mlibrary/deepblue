# frozen_string_literal: true

module BrowseEverythingIntegrationService

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

  mattr_accessor :browse_everything_browser_debug_verbose,          default: false
  mattr_accessor :browse_everything_controller_debug_verbose,       default: false
  mattr_accessor :browse_everything_controller2_debug_verbose,      default: false
  mattr_accessor :browse_everything_driver_authentication_factory_debug_verbose,  default: false
  mattr_accessor :browse_everything_driver_base_debug_verbose,      default: false
  mattr_accessor :browse_everything_driver_base2_debug_verbose,     default: false
  mattr_accessor :browse_everything_driver_dropbox_debug_verbose,   default: false
  mattr_accessor :browse_everything_driver_dropbox2_debug_verbose,  default: false
  mattr_accessor :browse_everything_views_debug_verbose,            default: false

end
