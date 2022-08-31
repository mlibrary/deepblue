# frozen_string_literal: true

class ServerLogsCopyService

  mattr_accessor :server_logs_copy_service_debug_verbose, default: false

  attr_accessor :filter, :msg_handler, :src_dir, :target_dir, :target_root_dir, :verbose

  def self.server_part
    # TODO: move this to a helper
    server_part = case Rails.configuration.hostname
                  when ::Deepblue::InitializationConstants::HOSTNAME_PROD
                    ::Deepblue::InitializationConstants::PRODUCTION
                  when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
                    ::Deepblue::InitializationConstants::TESTING
                  when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
                    ::Deepblue::InitializationConstants::STAGING
                  when ::Deepblue::InitializationConstants::HOSTNAME_TEST
                    ::Deepblue::InitializationConstants::TEST
                  when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
                    ::Deepblue::InitializationConstants::LOCAL
                  else
                    ::Deepblue::InitializationConstants::UNKNOWN
                  end
    return server_part
  end

  def initialize( filter: nil,
                  src_dir: "./log",
                  target_root_dir: "/deepbluedata-prep/logs/",
                  msg_handler: nil,
                  verbose: false )

    @filter = filter
    @msg_handler = msg_handler
    @src_dir = src_dir
    @target_root_dir = target_root_dir
    @verbose = verbose
  end

  def run
    # TODO messages and verbose
    # TODO throw errors
    # TODO filters
    msg_handler.msg( "Started: #{Time.now}" )
    server_part = ServerLogsCopyService.server_part
    target_dir_path = Time.now.strftime( "%Y%m%d%H%M%S" )
    target_dir_path = "#{@target_root_dir}#{server_part}/#{target_dir_path}"
    FileUtils.mkdir_p target_dir_path unless Dir.exist? target_dir_path
    log_path = File.realpath @src_dir
    rv = `cp #{log_path}/* #{target_dir_path}`
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "rv=#{rv}",
                                           "" ] if server_logs_copy_service_debug_verbose
    msg_handler.msg( rv )
    msg_handler.msg( "Finished: #{Time.now}" )
  end

end
