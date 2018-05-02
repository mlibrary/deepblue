require 'tasks/new_content_service'

# Given a configuration hash read from a yaml file, build the contents in the repository.
class AppendContentService < NewContentService

  def self.call( path_to_config )
    config = YAML.load_file(path_to_config)
    base_path = File.dirname(path_to_config)
    bcs = AppendContentService.new( config, base_path)   
    bcs.run
  end

  def initialize( config, base_path )
    initialize_with_msg( config, base_path, msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE" )
  end

  protected

  def build_repo_contents
    user = find_or_create_user
    find_works_and_add_files
    #build_collections
  end

end

