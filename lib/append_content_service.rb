# frozen_string_literal: true

require 'tasks/new_content_service'

# Given a configuration hash read from a yaml file, build the contents in the repository.
class AppendContentService < Deepblue::NewContentService

  def self.call( path_to_yaml_file:, args: )
    cfg_hash = YAML.load_file( path_to_yaml_file )
    base_path = File.dirname( path_to_yaml_file )
    bcs = AppendContentService.new( args: args,
                                    path_to_yaml_file: path_to_yaml_file,
                                    cfg_hash: cfg_hash,
                                    base_path: base_path )
    bcs.run
  rescue Exception => e
    Rails.logger.error "AppendContentService.call(#{path_to_yaml_file}) #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
  end

  def initialize( args:, path_to_yaml_file:, cfg_hash:, base_path: )
    initialize_with_msg( args: args,
                         path_to_yaml_file: path_to_yaml_file,
                         cfg_hash: cfg_hash,
                         base_path: base_path,
                         msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE" )
  end

  protected

    def build_repo_contents
      # user = find_or_create_user
      find_works_and_add_files
      # build_collections
    end

end
