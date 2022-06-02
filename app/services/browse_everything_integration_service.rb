# frozen_string_literal: true

module BrowseEverythingIntegrationService

  @@_setup_ran = false
  @@_setup_failed = false

  mattr_accessor :browse_everything_browser_debug_verbose,          default: false
  mattr_accessor :browse_everything_controller_debug_verbose,       default: false
  mattr_accessor :browse_everything_controller2_debug_verbose,      default: false
  mattr_accessor :browse_everything_driver_authentication_factory_debug_verbose,  default: false
  mattr_accessor :browse_everything_driver_base_debug_verbose,      default: false
  mattr_accessor :browse_everything_driver_base2_debug_verbose,     default: false
  mattr_accessor :browse_everything_driver_dropbox_debug_verbose,   default: false
  mattr_accessor :browse_everything_driver_dropbox2_debug_verbose,  default: false
  mattr_accessor :browse_everything_views_debug_verbose,            default: false

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
