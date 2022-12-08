# frozen_string_literal: true

# require_relative '../helpers/deepblue/disk_utilities_helper'

class IngestScript

  mattr_accessor :ingest_script_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.ingest_script_debug_verbose

  attr_accessor :base_path
  attr_accessor :curation_concern_id
  attr_accessor :ingest_mode
  attr_accessor :ingest_script
  attr_accessor :ingest_script_id
  attr_accessor :ingest_script_path
  attr_accessor :path_to_yaml_file

  def initialize( curation_concern_id:, ingest_mode:, ingest_script: nil, path_to_yaml_file: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "curation_concern_id=#{curation_concern_id}",
                                           "ingest_mode=#{ingest_mode}",
                                           "ingest_script=#{ingest_script}",
                                           "path_to_yaml_file=#{path_to_yaml_file}",
                                           "" ] if ingest_script_debug_verbose
    @curation_concern_id = curation_concern_id
    @path_to_yaml_file = path_to_yaml_file
    @base_path = File.dirname( path_to_yaml_file )
    @ingest_mode = ingest_mode
    @ingest_script = init_ingest_script( ingest_script: ingest_script )
    @ingest_script_id = init_ingest_script_id
    @ingest_script_path = init_ingest_script_path
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@base_path=#{@base_path}",
                                           "@ingest_script_id=#{@ingest_script_id}",
                                           "@ingest_script_path=#{@ingest_script_path}",
                                           "" ] if ingest_script_debug_verbose
    hash_value_init( :path_to_yaml_file, hash: script_section, value: @path_to_yaml_file )
    hash_value_init( :ingest_script_id, hash: script_section, value: @ingest_script_id )
    hash_value_init( :ingest_script_path, hash: script_section, value: @ingest_script_path )
    hash_value_init( :data_set_url, hash: script_section ) do
      ::Deepblue::EmailHelper.data_set_url( id: curation_concern_id )
    end
    add_file_sections
    save_yaml
  end

  def add_file_sections
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script=#{@ingest_script.pretty_inspect}",
                                           "" ] if ingest_script_debug_verbose
    works = @ingest_script[:user][:works]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "works=#{works.pretty_inspect}",
                                           "" ] if ingest_script_debug_verbose
    hash_value_init( :file_count, hash: script_section, value: works[:filenames].size )
    works[:filenames].each_with_index do |filename,index|
      key = file_key index
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "filename=#{filename}",
                                             "index=#{index}",
                                             "key=#{key}",
                                             "" ] if ingest_script_debug_verbose
      hash_value_init( key, hash: files_section, value:  { filename: filename } )
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "files_section=#{files_section.pretty_inspect}",
                                           "" ] if ingest_script_debug_verbose
    works[:files].each_with_index do |file,index|
      hash = file_section index
      hash_value_init( :parent_id, hash: hash, value: @curation_concern_id )
      hash_value_init( :path, hash: hash, value: file )
      hash_value_init( :size, hash: hash ) { File.size file }
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

  def files_section
    @files_section ||= hash_value_init( :files, hash: script_section, value: {} )
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

  def init_ingest_script( ingest_script: )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@ingest_script=#{ingest_script}",
                                           "" ] if ingest_script_debug_verbose
    return ingest_script unless ingest_script.nil?
    return nil unless File.exist? @path_to_yaml_file
    rv = YAML.load_file @path_to_yaml_file
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "ingest_script=#{rv.pretty_inspect}",
                                           "" ] if ingest_script_debug_verbose
    return rv
  end

  def init_ingest_script_id
    "#{Time.now.strftime( "%Y%m%d%H%M%S" )}_#{curation_concern_id}"
  end

  def init_ingest_script_path
    base_path = ::Deepblue::IngestIntegrationService.ingest_script_tracking_dir_base
    expand = ::Deepblue::IngestIntegrationService.ingest_script_tracking_dir_expand_id
    base_path = ::Deepblue::DiskUtilitiesHelper.expand_id_path( @curation_concern_id, base_dir: base_path ) if expand
    ::Deepblue::DiskUtilitiesHelper.mkdirs base_path
    script_file_name = "#{@ingest_script_id}_append.yml"
    File.join( base_path, script_file_name )
  end

  def ingest_script_present?
    return false if @ingest_script.nil?
    return false if @ingest_script.empty?
    return true
  end

  def key?( key )
    @ingest_script.key? key
  end

  def log=( log )
    script_section[:log] = log
  end

  def script_section_key
    :script
  end

  def script_section
    @scripts_section ||= hash_value_init( :script, hash: works_section, value: {} )
  end

  def save_yaml
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