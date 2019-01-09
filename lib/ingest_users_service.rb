# frozen_string_literal: true

require 'tasks/new_content_service'

class IngestUsersService < Deepblue::NewContentService

  def self.call( path_to_yaml_file:, mode: nil, ingester: nil, options: )
    cfg_hash = Deepblue::NewContentService.load_yaml_file( path_to_yaml_file )
    return if cfg_hash.nil?
    base_path = File.dirname( path_to_yaml_file )
    bcs = IngestUsersService.new( path_to_yaml_file: path_to_yaml_file,
                                  cfg_hash: cfg_hash,
                                  base_path: base_path,
                                  mode: mode,
                                  ingester: ingester,
                                  options: options )
    bcs.run
  rescue Exception => e # rubocop:disable Lint/RescueException
    puts "IngestUsersService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
    Rails.logger.error "IngestUsersService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
  end

  def initialize( path_to_yaml_file:, cfg_hash:, base_path:, mode:, ingester:, options: )
    initialize_with_msg( options: options,
                         path_to_yaml_file: path_to_yaml_file,
                         cfg_hash: cfg_hash,
                         base_path: base_path,
                         mode: mode,
                         ingester: ingester,
                         msg: "INGEST USER SERVICE AT YOUR ... SERVICE" )
  end

  protected

    def build_repo_contents
      build_users
      report_measurements( first_label: 'users' )
    rescue Exception => e # rubocop:disable Lint/RescueException
      puts "IngestUsersService.build_repo_contents #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
      Rails.logger.error "IngestUsersService.build_repo_contents #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
    end

end
