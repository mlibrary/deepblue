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

    def self.setup_status
      puts "@@_setup_ran=#{@@_setup_ran}"
      puts "@@_setup_failed=#{@@_setup_failed}"
    end

    mattr_accessor :aptrust_integration_debug_verbose, default: false

    mattr_accessor :allow_deposit,             default: true
    mattr_accessor :automatic_set_deleted_status, default: true
    #mattr_accessor :deposit_context,           default: 'localhost-'
    mattr_accessor :deposit_context,           default: ''
    mattr_accessor :repository,                default: 'umich.edu'
    mattr_accessor :local_repository,          default: 'deepbluedata'

    mattr_accessor :aptrust_info_txt_template, default: ''

    mattr_accessor :bag_checksum_algorithm,    default: 'md5'
    mattr_accessor :bag_delete_manifest_sha1,  default: true
    mattr_accessor :bag_max_file_size,         default: 1.terabytes - 200.megabytes # max less a bit of buffer
    mattr_accessor :bag_max_total_file_size,   default: 1.terabytes - 100.megabytes # max less a bit of buffer

    mattr_accessor :cleanup_after_deposit,     default: true
    mattr_accessor :cleanup_bag,               default: false
    mattr_accessor :cleanup_bag_data,          default: true
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
    mattr_accessor :dbd_validate_file_checksums, default: true

    mattr_accessor :download_dir,              default: './data/aptrust_download/'
    mattr_accessor :export_dir,                default: './data/aptrust_export/'
    mattr_accessor :working_dir,               default: './data/aptrust_work/'
    mattr_accessor :storage_option,            default: 'Glacier-Deep-OR'

    # use these values from the DataSetContoller when launching an AptrustUploadWorkJob
    mattr_accessor :from_controller_cleanup_after_deposit,        default: true
    mattr_accessor :from_controller_cleanup_before_deposit,       default: true
    mattr_accessor :from_controller_cleanup_bag,                  default: false
    mattr_accessor :from_controller_cleanup_bag_data,             default: true
    mattr_accessor :from_controller_clear_status,                 default: true
    mattr_accessor :from_controller_debug_assume_upload_succeeds, default: false
    mattr_accessor :from_controller_debug_verbose,                default: false

    def self.dump_mattrs
      return [ "::Aptrust::AptrustIntegrationService.allow_deposit=#{::Aptrust::AptrustIntegrationService.allow_deposit}",
       "::Aptrust::AptrustIntegrationService.deposit_context=#{::Aptrust::AptrustIntegrationService.deposit_context}",
       "::Aptrust::AptrustIntegrationService.repository=#{::Aptrust::AptrustIntegrationService.repository}",
       "::Aptrust::AptrustIntegrationService.local_repository=#{::Aptrust::AptrustIntegrationService.local_repository}",

       "::Aptrust::AptrustIntegrationService.aptrust_info_txt_template=#{::Aptrust::AptrustIntegrationService.aptrust_info_txt_template}",

       "::Aptrust::AptrustIntegrationService.bag_checksum_algorithm=#{::Aptrust::AptrustIntegrationService.bag_checksum_algorithm}",
       "::Aptrust::AptrustIntegrationService.bag_delete_manifest_sha1=#{::Aptrust::AptrustIntegrationService.bag_delete_manifest_sha1}",
       "::Aptrust::AptrustIntegrationService.bag_max_file_size=#{::Aptrust::AptrustIntegrationService.bag_max_file_size}",
       "::Aptrust::AptrustIntegrationService.bag_max_total_file_size=#{::Aptrust::AptrustIntegrationService.bag_max_total_file_size}",

       "::Aptrust::AptrustIntegrationService.cleanup_after_deposit=#{::Aptrust::AptrustIntegrationService.cleanup_after_deposit}",
       "::Aptrust::AptrustIntegrationService.cleanup_bag=#{::Aptrust::AptrustIntegrationService.cleanup_bag}",
       "::Aptrust::AptrustIntegrationService.cleanup_bag_data=#{::Aptrust::AptrustIntegrationService.cleanup_bag_data}",
       "::Aptrust::AptrustIntegrationService.clear_status=#{::Aptrust::AptrustIntegrationService.clear_status}",

       "::Aptrust::AptrustIntegrationService.default_access=#{::Aptrust::AptrustIntegrationService.default_access}",
       "::Aptrust::AptrustIntegrationService.default_creator=#{::Aptrust::AptrustIntegrationService.default_creator}",
       "::Aptrust::AptrustIntegrationService.default_description=#{::Aptrust::AptrustIntegrationService.default_description}",
       "::Aptrust::AptrustIntegrationService.default_item_description=#{::Aptrust::AptrustIntegrationService.default_item_description}",
       "::Aptrust::AptrustIntegrationService.default_storage_option=#{::Aptrust::AptrustIntegrationService.default_storage_option}",
       "::Aptrust::AptrustIntegrationService.default_title=#{::Aptrust::AptrustIntegrationService.default_title}",

       "::Aptrust::AptrustIntegrationService.dbd_creator=#{::Aptrust::AptrustIntegrationService.dbd_creator}",
       "::Aptrust::AptrustIntegrationService.dbd_bag_description=#{::Aptrust::AptrustIntegrationService.dbd_bag_description}",
       "::Aptrust::AptrustIntegrationService.dbd_work_description=#{::Aptrust::AptrustIntegrationService.dbd_work_description}",
       "::Aptrust::AptrustIntegrationService.dbd_validate_file_checksums=#{::Aptrust::AptrustIntegrationService.dbd_validate_file_checksums}",

       "::Aptrust::AptrustIntegrationService.download_dir=#{::Aptrust::AptrustIntegrationService.download_dir}",
       "::Aptrust::AptrustIntegrationService.export_dir=#{::Aptrust::AptrustIntegrationService.export_dir}",
       "::Aptrust::AptrustIntegrationService.working_dir=#{::Aptrust::AptrustIntegrationService.working_dir}",
       "::Aptrust::AptrustIntegrationService.storage_option=#{::Aptrust::AptrustIntegrationService.storage_option}" ]
    end

  end

end
