# frozen_string_literal: true

# require_relative '../helpers/deepblue/disk_utilities_helper'

class IngestScript

  mattr_accessor :ingest_script_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_script_debug_verbose

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

  def self.append( curation_concern_id:, ingest_script: nil, ingest_script_path: nil, initial_yaml_file_path: )
    IngestScript.new( curation_concern_id: curation_concern_id,
                     ingest_mode: 'append',
                     ingest_script: ingest_script,
                     ingest_script_path: ingest_script_path,
                     initial_yaml_file_path: initial_yaml_file_path )
  end

  def initialize( curation_concern_id:,
                  ingest_mode:,
                  ingest_script: nil,
                  ingest_script_path: nil,
                  initial_yaml_file_path: )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "curation_concern_id=#{curation_concern_id}",
                                           "ingest_mode=#{ingest_mode}",
                                           "ingest_script=#{ingest_script}",
                                           "initial_yaml_file_path=#{initial_yaml_file_path}",
                                           "" ] if ingest_script_debug_verbose
    @curation_concern_id = curation_concern_id
    @initial_yaml_file_path = initial_yaml_file_path
    @initial_yaml_dir = File.dirname( @initial_yaml_file_path )
    @ingest_base_dir = ::Deepblue::IngestIntegrationService.ingest_script_tracking_dir_base
    @ingest_id_dir = ::Deepblue::DiskUtilitiesHelper.expand_id_path( @curation_concern_id, base_dir: @ingest_base_dir )
    # TODO: check @initial_yaml_dir versus @ingest_base_dir and @ingest_id_dir
    @ingest_mode = ingest_mode
    @ingest_script = init_ingest_script( ingest_script: ingest_script )
    @ingest_script_id = init_ingest_script_id
    @ingest_script_path = ingest_script_path
    @ingest_script_path ||= init_ingest_script_path
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@initial_yaml_file_path=#{@initial_yaml_file_path}",
                                           "@ingest_script_id=#{@ingest_script_id}",
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if ingest_script_debug_verbose
    hash_value_init( :initial_yaml_file_path, hash: script_section, value: @initial_yaml_file_path )
    hash_value_init( :ingest_script_id, hash: script_section, value: @ingest_script_id )
    hash_value_init( :ingest_script_path, hash: script_section, value: @ingest_script_path )
    hash_value_init( :data_set_url, hash: script_section ) do
      ::Deepblue::EmailHelper.data_set_url( id: curation_concern_id )
    end
    @file_set_count = works_section[:filenames].size
    hash_value_init( :file_set_count, hash: script_section, value: @file_set_count )
    add_file_sections
    touch
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

  def init_ingest_script( ingest_script: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script=#{ingest_script}",
                                           "" ] if ingest_script_debug_verbose
    return ingest_script unless ingest_script.nil?
    return nil unless File.exist? @initial_yaml_file_path
    rv = YAML.load_file @initial_yaml_file_path
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "ingest_script=#{rv.pretty_inspect}",
                                           "" ] if ingest_script_debug_verbose
    return rv
  end

  def init_ingest_script_id
    # TODO: check @initial_yaml_dir versus @ingest_base_dir and @ingest_id_dir
    "#{Time.now.strftime( "%Y%m%d%H%M%S" )}_#{curation_concern_id}"
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

  def job_id
    script_section[:job_id] = job_id
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

  def key?( key )
    @ingest_script.key? key
  end

  def log=( log )
    script_section[:log] = log
  end

  def log_save( log )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "log=#{log.pretty_inspect}",
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if ingest_script_debug_verbose
    # TODO: add append flag / add log_append
    self.log = log
    touch
    return self
  end

  def move( new_path, save: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "new_path=#{new_path}",
                                           "save=#{save}",
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if ingest_script_debug_verbose
    parent = File.dirname new_path
    FileUtils.mkdir_p( parent ) unless Dir.exist? parent
    FileUtils.mv( @ingest_script_path, new_path )
    script_section[:prior_ingest_script_path] = @ingest_script_path
    @ingest_script_path = new_path
    script_section[:ingest_script_path] = @ingest_script_path
    return touch if save
    return self
  end

  def move_to_finished( save: true )
    finished_script_path = File.join @ingest_id_dir, ingest_script_file_name
    move( finished_script_path, save: save )
  end

  def script_section
    @scripts_section ||= hash_value_init( :script, hash: works_section, value: {} )
  end

  def script_section_key
    :script
  end

  def touch
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if ingest_script_debug_verbose
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