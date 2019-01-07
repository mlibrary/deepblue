# frozen_string_literal: true

require 'tasks/new_content_service'

# Given a configuration hash read from a yaml file,
# diff the contents in the repository.
class DiffContentService < Deepblue::NewContentService

  def self.call( path_to_yaml_file:, mode: nil, ingester: nil, options: )
    cfg_hash = YAML.load_file( path_to_yaml_file )
    base_path = File.dirname( path_to_yaml_file )
    bcs = DiffContentService.new( path_to_yaml_file: path_to_yaml_file,
                                  cfg_hash: cfg_hash,
                                  base_path: base_path,
                                  mode: mode,
                                  ingester: ingester,
                                  options: options )
    bcs.run
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "DiffContentService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
  end

  def initialize( path_to_yaml_file:, cfg_hash:, base_path:, mode:, ingester:, options: )
    initialize_with_msg( options: options,
                         path_to_yaml_file: path_to_yaml_file,
                         cfg_hash: cfg_hash,
                         base_path: base_path,
                         mode: mode,
                         ingester: ingester,
                         msg: "DIFF CONTENT SERVICE AT YOUR ... SERVICE" )
  end

  protected

    def build_repo_contents
      diff_works
      diff_collections
      report_measurements( first_label: 'id' )
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "DiffContentService.diff_repo_contents #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
    end

end
