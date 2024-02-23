# frozen_string_literal: true

module Aptrust

  module AptrustIntegrationService

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

    mattr_accessor :aptrust_integration_debug_verbose, default: false

    mattr_accessor :allow_deposit,             default: true
    mattr_accessor :deposit_context,           default: ''
    mattr_accessor :deposit_local_repository,  default: ''

    mattr_accessor :aptrust_info_txt_template, default: ''

    mattr_accessor :clean_up_after_deposit,    default: true
    mattr_accessor :clean_up_bag,              default: false
    mattr_accessor :clean_up_bag_data,         default: true
    mattr_accessor :clear_status,              default: true

    mattr_accessor :default_access,            default: 'Institution'
    mattr_accessor :default_creator,           default: ''
    mattr_accessor :default_description,       default: 'No description.'
    mattr_accessor :default_item_description,  default: 'No item description.'
    mattr_accessor :default_storage_option,    default: 'Standard'
    mattr_accessor :default_title,             default: 'No Title'

    mattr_accessor :dbd_creator,               default: 'Deepblue Data'
    mattr_accessor :dbd_bag_description,       default: 'Deepblue Data Bag Description'
    mattr_accessor :dbd_work_description,      default: 'DBD Work Description'

  end

end
