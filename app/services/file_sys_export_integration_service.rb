# frozen_string_literal: true

module FileSysExportIntegrationService

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

  def self.setup_status
    puts "@@_setup_ran=#{@@_setup_ran}"
    puts "@@_setup_failed=#{@@_setup_failed}"
  end

  mattr_accessor :file_sys_export_integration_debug_verbose, default: false

  mattr_accessor :default_export_type,            default: "data_den"

  mattr_accessor :data_den_export_type,           default: "data_den"

  # mattr_accessor :data_den_base_path,             default: './data/data_den/'
  # mattr_accessor :data_den_base_path_published,   default: './data/data_den/published/'
  # mattr_accessor :data_den_base_path_unpublished, default: './data/data_den/unpublished/'

  mattr_accessor :data_den_base_path,             default: '/Users/fritx/DataDen/'
  mattr_accessor :data_den_base_path_published,   default: '/Users/fritx/DataDen/published/'
  mattr_accessor :data_den_base_path_unpublished, default: '/Users/fritx/DataDen/unpublished/'
  mattr_accessor :data_den_link_path_to_globus,   default: '/Users/fritx/Globus/'

  mattr_accessor :globus_delete_link_to_target,   default: true

end
