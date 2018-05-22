# frozen_string_literal: true

require 'tasks/new_content_service'

# Given a configuration hash read from a yaml file,
# build the contents in the repository.
class BuildContentService < NewContentService

  def self.call( path_to_config )
    config = YAML.load_file(path_to_config)
    base_path = File.dirname(path_to_config)
    bcs = BuildContentService.new( config, base_path )
    bcs.run
  end

  def initialize( config, base_path )
    initialize_with_msg( config, base_path, msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE" )
  end

  protected

  def build_repo_contents
    user = find_or_create_user
    build_works
    build_collections
  rescue Exception => e
    Rails.logger.error "BuildContentService.build_repo_contents #{e.class}: #{e.message} at\n#{e.backtrace.join("\n")}"
  end

end

