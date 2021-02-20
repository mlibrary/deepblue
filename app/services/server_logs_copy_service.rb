# frozen_string_literal: true

class ServerLogsCopyService

  attr_accessor :filter, :root_dir, :target_dir, :target_root_dir

  def initialize( filter: nil, root_dir: "./log", target_root_dir: "/deepbluedata-prep/logs/" )
    @filter = filter
    @root_dir = root_dir
    @target_root_dir = target_root_dir
  end

  def copy_logs
    # TODO use paths
    # TODO create target dir
    # TODO use date for target dir
    # TODO throw errors
    # TODO filters
    date_mod = "date_todo"
    server_mod = "server_todo"
    @target_dir = "#{target_root_dir}/#{server_mod}/#{date_mod}/"
  end

end
