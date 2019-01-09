# frozen_string_literal: true

require 'tasks/new_content_service'

class UpdateUsersService < Deepblue::NewContentService

  def self.call( path_to_yaml_file:, ingester: nil, options: )
    cfg_hash = Deepblue::NewContentService.load_yaml_file( path_to_yaml_file )
    return if cfg_hash.nil?
    base_path = File.dirname( path_to_yaml_file )
    bcs = UpdateUsersService.new( path_to_yaml_file: path_to_yaml_file,
                                  cfg_hash: cfg_hash,
                                  base_path: base_path,
                                  ingester: ingester,
                                  options: options )
    bcs.run
  rescue Exception => e # rubocop:disable Lint/RescueException
    puts "UpdateUsersService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
    Rails.logger.error "UpdateUsersService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
  end

  def initialize( path_to_yaml_file:, cfg_hash:, base_path:, ingester:, options: )
    initialize_with_msg( options: options,
                         path_to_yaml_file: path_to_yaml_file,
                         cfg_hash: cfg_hash,
                         base_path: base_path,
                         mode: Deepblue::NewContentService::MODE_UPDATE,
                         ingester: ingester,
                         msg: "UPDATE USER SERVICE AT YOUR ... SERVICE" )
  end

  protected

    def build_repo_contents
      update_users
      report_measurements( first_label: 'users' )
    rescue Exception => e # rubocop:disable Lint/RescueException
      puts "UpdateUsersService.build_repo_contents #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
      Rails.logger.error "UpdateUsersService.build_repo_contents #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
    end

end
