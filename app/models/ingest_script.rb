# frozen_string_literal: true

# require_relative '../helpers/deepblue/disk_utilities_helper'

class IngestScript

  mattr_accessor :ingest_script_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_script_debug_verbose

  mattr_accessor :ingest_script_log_debug_verbose, default: false
  mattr_accessor :ingest_script_move_debug_verbose, default: false
  mattr_accessor :ingest_script_touch_debug_verbose, default: false

  attr_accessor :base_path
  attr_accessor :curation_concern_id
  attr_accessor :file_set_count
  attr_accessor :ingest_base_dir
  attr_accessor :ingest_mode
  attr_accessor :ingest_id_dir
  attr_accessor :ingest_script
  attr_accessor :ingest_script_file_name
  attr_accessor :ingest_script_id
  attr_accessor :ingest_script_path
  attr_accessor :initial_yaml_dir
  attr_accessor :initial_yaml_file_path
  attr_accessor :max_appends
  attr_accessor :run_count

  class IngestScriptLoadError < RuntimeError

  end

  def self.ingest_append_script_files( id:, active_only: false )
    paths = []
    dirs = ingest_script_dirs( id: id, active_only: active_only )
    dirs.each do |dir|
      Dir.glob( "*#{id}_append.yml", base: dir ).sort.each { |p| paths << [dir,p] }
    end
    return paths
  end

  def self.ingest_script_dirs( id: nil, active_only: false )
    path = ::Deepblue::IngestIntegrationService.ingest_script_tracking_dir_base
    return [ path ] if id.blank? || active_only
    return [ path, ::Deepblue::DiskUtilitiesHelper.expand_id_path( id, base_dir: path ) ]
  end

  def self.ingest_script_file_name( script_id: )
    "#{script_id}_append.yml"
  end

  def self.ingest_script_path_is( expand_id: false, id: nil )
    path = ::Deepblue::IngestIntegrationService.ingest_script_tracking_dir_base
    path = ::Deepblue::DiskUtilitiesHelper.expand_id_path( id, base_dir: path ) if expand_id
    return path
  end

  def self.append( curation_concern_id:,
                   ingest_script: nil,
                   ingest_script_path: nil,
                   initial_yaml_file_path:,
                   max_appends: -1,
                   run_count: 0 )

    IngestScript.new( curation_concern_id: curation_concern_id,
                      ingest_mode: 'append',
                      ingest_script: ingest_script,
                      ingest_script_path: ingest_script_path,
                      initial_yaml_file_path: initial_yaml_file_path,
                      max_appends: max_appends,
                      run_count: run_count )
  end

  def self.append_load( ingest_script_path:, max_appends: -1, run_count: )
    IngestScript.new( ingest_script_path: ingest_script_path,
                      load: true,
                      max_appends: max_appends,
                      run_count: run_count )
  end

  def self.load( ingest_script_path: )
    IngestScript.new( ingest_script_path: ingest_script_path, load: true )
  end

  def self.reload( ingest_script:, max_appends: -1, run_count: 0)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "ingest_script=#{ingest_script}",
                                           "ingest_script.ingest_script_path=#{ingest_script&.ingest_script_path}",
                                           "max_appends=#{max_appends}",
                                           "run_count=#{run_count}",
                                           "" ] if ingest_script_debug_verbose
    rv = IngestScript.new( ingest_script_path: ingest_script.ingest_script_path,
                           load: true,
                           max_appends: max_appends,
                           run_count: run_count )
    return rv
  end

  def initialize( curation_concern_id: nil,
                  ingest_mode: nil,
                  ingest_script: nil,
                  ingest_script_path: nil,
                  initial_yaml_file_path: nil,
                  load: false,
                  max_appends: -1,
                  run_count: 0 )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "curation_concern_id=#{curation_concern_id}",
                                           "ingest_mode=#{ingest_mode}",
                                           "ingest_script=#{ingest_script}",
                                           "ingest_script_path=#{ingest_script_path}",
                                           "initial_yaml_file_path=#{initial_yaml_file_path}",
                                           "load=#{load}",
                                           "max_appends=#{max_appends}",
                                           "run_count=#{run_count}",
                                           "" ] if ingest_script_debug_verbose
    @load = load
    self.ingest_script_path = ingest_script_path
    @ingest_script = ingest_script
    if load
      raise IngestScriptLoadError "Expected ingest_script_path '#{@ingest_script_path}' to exist." unless
                                                                                    File.exist? @ingest_script_path
      @ingest_script ||= init_ingest_script
      @curation_concern_id = works_section[:id]
      @max_appends = script_section[:max_appends]
      if @max_appends.blank?
        @max_appends = max_appends
        script_section[:max_appends] = max_appends
      end
      @run_count = script_section[:run_count]
      if @run_count.blank? || run_count > @run_count
        @run_count = run_count
        script_section[:run_count] = run_count
      end
      @initial_yaml_file_path = script_section[:initial_yaml_file_path]
    else
      @max_appends = max_appends
      @run_count = run_count
      @curation_concern_id = curation_concern_id
      @initial_yaml_file_path = initial_yaml_file_path
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@initial_yaml_file_path=#{@initial_yaml_file_path}",
                                           "@load=#{@load}",
                                           "" ] if ingest_script_debug_verbose
    @initial_yaml_dir = File.dirname( @initial_yaml_file_path )
    @ingest_base_dir = ::Deepblue::IngestIntegrationService.ingest_script_tracking_dir_base
    @ingest_id_dir = ::Deepblue::DiskUtilitiesHelper.expand_id_path( @curation_concern_id, base_dir: @ingest_base_dir )
    if load
      @ingest_mode = user_section[:mode]
      @ingest_script_id = script_section[:ingest_script_id]
    else
      @ingest_mode = ingest_mode
      @ingest_script_id = init_ingest_script_id
      @ingest_script ||= init_ingest_script
      self.ingest_script_path = init_ingest_script_path if @ingest_script_path.blank?
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@curation_concern_id=#{@curation_concern_id}",
                                           "@ingest_mode=#{@ingest_mode}",
                                           "@ingest_script=#{@ingest_script}",
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "@initial_yaml_file_path=#{@initial_yaml_file_path}",
                                           "@load=#{@load}",
                                           "" ] if ingest_script_debug_verbose
    unless load
      hash_value_init( :max_appends, hash: script_section, value: @max_appends )
      hash_value_init( :run_count, hash: script_section, value: @run_count )
      hash_value_init( :initial_yaml_file_path, hash: script_section, value: @initial_yaml_file_path )
      hash_value_init( :ingest_script_id, hash: script_section, value: @ingest_script_id )
      hash_value_init( :ingest_script_path, hash: script_section, value: @ingest_script_path )
      hash_value_init( :ingest_script_dir, hash: script_section, value: @ingest_script_dir )
      hash_value_init( :data_set_url, hash: script_section ) do
        ::Deepblue::EmailHelper.data_set_url( id: curation_concern_id )
      end
      @file_set_count = works_section[:filenames].size
      hash_value_init( :file_set_count, hash: script_section, value: @file_set_count )
      add_file_sections
      touch
    end
  end

  def active?
    @ingest_base_dir == @ingest_script_dir
  end

  def add_file_sections
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script=#{@ingest_script.pretty_inspect}",
                                           "" ] if ingest_script_debug_verbose
    max = @file_set_count - 1
    for index in 0..max do
      key = file_key index
      hash_value_init( key, hash: files_section ) { { filename: works_section[:filenames][index] } }
      hash = file_section index
      file_path = works_section[:files][index]
      hash_value_init( :parent_id, hash: hash, value: @curation_concern_id )
      hash_value_init( :path, hash: hash, value: file_path )
      hash_value_init( :size, hash: hash ) { File.size file_path }
      hash_value_init( :size_human_readable, hash: hash ) do
        DeepblueHelper.human_readable_size( hash[:size] )
      end
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "files_section=#{files_section.pretty_inspect}",
                                           "" ] if ingest_script_debug_verbose
  end

  def array_from( key:, hash: @ingest_script )
    [hash[key]]
  rescue Exception => e
    ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] + e.backtrace[0..20]
    raise
  end

  def failed?
    !active? && !finished?
  end

  def file_key( index )
    "f_#{index}".to_sym
  end

  def file_section( index )
    key = file_key( index )
    files_section[key]
  end

  def file_section_first
    file_section 0
  end

  def file_section_last
    file_section( @file_set_count - 1 )
  end

  def file_set_count
    @file_set_count ||= script_section[:file_set_count]
  end

  def files_section
    @files_section ||= hash_value_init( :files, hash: script_section, value: {} )
  end

  def finished=( flag )
    script_section[:finished] = flag
  end

  def finished?
    true == script_section[:finished]
  end

  def hash_value( key, hash: @ingest_script, default_value: nil )
    return hash[key] if hash.has_key? key
    default_value
  end

  def hash_value_init( key, hash: @ingest_script, value: nil )
    if block_given?
      hash[key] = yield unless hash.has_key? key
    else
      hash[key] = value unless hash.has_key? key
    end
    hash[key]
  end

  def ingest_script_path=( path )
    @ingest_script_path = path
    @ingest_script_dir = File.dirname( path ) unless path.blank?
  end

  def ingest_script_path_full( expand_id: false )
    path = ingest_script_path_is( expand_id: expand_id )
    ::Deepblue::DiskUtilitiesHelper.mkdirs path
    script_file_name = ingest_script_file_name
    File.join( path, script_file_name )
  end

  def ingest_script_file_name
    @ingest_script_file_name ||= "#{@ingest_script_id}_append.yml"
  end

  def ingest_script_path_is( expand_id: false )
    IngestScript::ingest_script_path_is( expand_id: expand_id, id: @curation_concern_id )
  end

  def ingest_script_dirs
    IngestScript.ingest_script_dirs( id: @curation_concern_id )
  end

  def ingest_script_present?
    return false if @ingest_script.nil?
    return false if @ingest_script.empty?
    return true
  end

  def init_ingest_script
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script=#{@ingest_script}",
                                           "@initial_yaml_file_path=#{@initial_yaml_file_path}",
                                           "" ] if ingest_script_debug_verbose
    return @ingest_script unless @ingest_script.blank?
    path = @load ? @ingest_script_path : @initial_yaml_file_path
    return nil unless File.exist? path
    rv = YAML.load_file path
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "ingest_script=#{rv.pretty_inspect}",
                                           "" ] if ingest_script_debug_verbose
    return rv
  end

  def init_ingest_script_id
    # TODO: check @initial_yaml_dir versus @ingest_base_dir and @ingest_id_dir
    "#{Time.now.strftime( "%Y%m%d%H%M%S" )}_#{@curation_concern_id}"
  end

  def init_ingest_script_path
    path = ingest_script_path_is( expand_id: false )
    ::Deepblue::DiskUtilitiesHelper.mkdirs path
    script_file_name = ingest_script_file_name
    File.join( path, script_file_name )
  end

  def job_begin_timestamp
    script_section[:job_begin_timestamp]
  end

  def job_begin_timestamp=( job_begin_timestamp )
    script_section[:job_begin_timestamp] = job_begin_timestamp
  end

  def job_end_timestamp
    script_section[:job_end_timestamp]
  end

  def job_end_timestamp=( job_end_timestamp )
    script_section[:job_end_timestamp] = job_end_timestamp
  end

  def job_file_sets_processed_count
    script_section[:job_file_sets_processed_count]
  end

  def job_file_sets_processed_count=( job_file_sets_processed_count )
    script_section[:job_file_sets_processed_count] = job_file_sets_processed_count
  end

  def job_file_sets_processed_count_add( add = 1 )
    count = job_file_sets_processed_count
    count ||= 0
    self.job_file_sets_processed_count = (count + add)
  end

  def job_id
    script_section[:job_id]
  end

  def job_id=( job_id )
    # TODO: if this value already exists, push current value to new section
    script_section[:job_id] = job_id
  end

  def job_json
    script_section[:job_json]
  end

  def job_json=( job_json )
    script_section[:job_json] = job_json
  end

  def job_max_appends
    script_section[:job_max_appends]
  end

  def job_max_appends=( job_max_appends )
    script_section[:job_max_appends] = job_max_appends
  end

  def job_run_count
    script_section[:job_run_count]
  end

  def job_run_count=( job_run_count )
    script_section[:job_run_count] = job_run_count
  end

  def job_run_count_add( add = 1 )
    count = job_run_count
    count ||= 0
    self.job_run_count = (count + add)
  end

  def job_running?
    jid = job_id
    return false if jid.blank?
    return ::Deepblue::JobsHelper.job_running? jid
  end

  def key?( key )
    @ingest_script.key? key
  end

  def log
    script_section[:log]
  end

  def log=( log )
    script_section[:log] = log
  end

  def log_backup( run_count: )
    debug_verbose = ingest_script_log_debug_verbose || ingest_script_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "run_count=#{run_count}",
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if debug_verbose
    log_id = log_key(run_count - 1)
    script_section[log_id] = self.log
    self.log = []
    touch
    return self
  end

  def log_key( index )
    "log_#{index}".to_sym
  end

  def log_indexed( index )
    key = log_key( index )
    script_section[key]
  end

  def log_indexed_save( log_array, index: @run_count )
    debug_verbose = ingest_script_log_debug_verbose || ingest_script_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "index=#{index}",
                                           "log_array=#{log_array.pretty_inspect}",
                                           "key=#{log_key(index)}",
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if debug_verbose
    key = log_key( index )
    script_section[key] = log_array
    touch
    return self
  end

  def log_save( log )
    debug_verbose = ingest_script_log_debug_verbose || ingest_script_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "log=#{log.pretty_inspect}",
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if debug_verbose
    # TODO: add append flag / add log_append
    self.log = log
    touch
    return self
  end

  def move( new_path, save: false )
    debug_verbose = ingest_script_move_debug_verbose || ingest_script_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "new_path=#{new_path}",
                                           "save=#{save}",
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if debug_verbose
    parent = File.dirname new_path
    FileUtils.mkdir_p( parent ) unless Dir.exist? parent
    FileUtils.mv( @ingest_script_path, new_path )
    script_section[:prior_ingest_script_path] = @ingest_script_path
    ingest_script_path = new_path
    script_section[:ingest_script_path] = @ingest_script_path
    script_section[:ingest_script_dir] = @ingest_script_dir
    return touch if save
    return self
  end

  def move_to_finished( save: true )
    debug_verbose = ingest_script_move_debug_verbose || ingest_script_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "save=#{save}",
                                           "" ] if debug_verbose
    finished_script_path = File.join @ingest_id_dir, ingest_script_file_name
    move( finished_script_path, save: save )
  end

  def running?
    !finished? && @ingest_base_dir == @ingest_script_dir
  end

  def script_section
    @scripts_section ||= hash_value_init( :script, hash: works_section, value: {} )
  end

  def script_section_key
    :script
  end

  def touch
    debug_verbose = ingest_script_touch_debug_verbose || ingest_script_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if debug_verbose
    File.open( @ingest_script_path, "w" ) do |out|
      out.puts @ingest_script.to_yaml
    end
    return self
  end

  def user_section
    @users_section ||= @ingest_script[:user]
  end

  def works_section
    @works_section ||= user_section[:works]
  end

  def file_set_id_for( title: )
    # TODO
  end

  def file_set_ids
    # TODO: return an iterator over file_set ids
  end

  def file_set_titles
    # TODO: return an iterator over file_set titles
  end

  def log_from( msg_handler: )
    # TODO
  end

  def update_cc_id( cc_id: )
    # TODO
    return self
  end

end