# frozen_string_literal: true

require 'tasks/new_content_service'

# Given a configuration hash read from a yaml file, build the contents in the repository.
class UpdateContentService < Deepblue::NewContentService

  def self.call( path_to_yaml_file:, ingester: nil, options: )
    cfg_hash = Deepblue::NewContentService.load_yaml_file( path_to_yaml_file )
    return if cfg_hash.nil?
    base_path = File.dirname( path_to_yaml_file )
    bcs = UpdateContentService.new( options: options,
                                    path_to_yaml_file: path_to_yaml_file,
                                    cfg_hash: cfg_hash,
                                    ingester: ingester,
                                    base_path: base_path )
    bcs.run
  rescue Exception => e # rubocop:disable Lint/RescueException
    puts "UpdateContentService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
    Rails.logger.error "UpdateContentService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
  end

  def initialize( options:, path_to_yaml_file:, cfg_hash:, base_path:, ingester: )
    initialize_with_msg( options: options,
                         path_to_yaml_file: path_to_yaml_file,
                         cfg_hash: cfg_hash,
                         base_path: base_path,
                         ingester: ingester,
                         mode: Deepblue::NewContentService::MODE_UPDATE,
                         msg: "UPDATE CONTENT SERVICE AT YOUR ... SERVICE" )
  end

  protected

    def build_repo_contents
      update_collections
      update_works
      report_measurements( first_label: 'work id' )
    rescue Exception => e # rubocop:disable Lint/RescueException
      puts "UpdateContentService.build_repo_contents #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
      Rails.logger.error "UpdateContentService.build_repo_contents #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
    end

end
