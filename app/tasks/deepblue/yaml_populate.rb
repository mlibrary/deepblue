# frozen_string_literal: true

require 'open-uri'
require_relative '../../../app/helpers/deepblue/metadata_helper'

module Deepblue

  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  class YamlPopulate < AbstractTask

    DEBUG_VERBOSE                    = false                 unless const_defined? :DEBUG_VERBOSE

    DEFAULT_CREATE_ZERO_LENGTH_FILES = true                  unless const_defined? :DEFAULT_CREATE_ZERO_LENGTH_FILES
    DEFAULT_EXPORT_FILES             = true                  unless const_defined? :DEFAULT_EXPORT_FILES
    DEFAULT_EXPORT_FILES_FILTER_DATE = nil                   unless const_defined? :DEFAULT_EXPORT_FILES_FILTER_DATE
    DEFAULT_MODE                     = ::Deepblue::MetadataHelper::MODE_BUILD unless const_defined? :DEFAULT_MODE
    DEFAULT_OVERWRITE_EXPORT_FILES   = true                  unless const_defined? :DEFAULT_OVERWRITE_EXPORT_FILES
    DEFAULT_TARGET_DIR               = "#{::Deepblue::GlobusIntegrationService.globus_upload_dir}" unless const_defined? :DEFAULT_TARGET_DIR
    DEFAULT_VALIDATE_FILE_CHECKSUMS  = false                 unless const_defined? :DEFAULT_VALIDATE_FILE_CHECKSUMS

    attr_accessor :populate_ids
    attr_accessor :populate_stats
    attr_accessor :populate_type

    # options
    attr_accessor :debug_verbose
    attr_accessor :create_zero_length_files
    attr_accessor :export_files
    attr_accessor :export_files_newer_than_date
    attr_accessor :mode
    attr_accessor :overwrite_export_files
    attr_accessor :target_dir
    attr_accessor :validate_file_checksums

    attr_accessor :collect_exported_file_set_files
    attr_accessor :export_includes_callback

    def initialize( msg_handler: nil, populate_type:, options: )
      super( msg_handler: msg_handler, options: options )
      @populate_type = populate_type
      # options
      @debug_verbose            = task_options_value( key: 'debug_verbose',            default_value: DEBUG_VERBOSE )
      @collect_exported_file_set_files = task_options_value( key: 'collect_exported_file_set_files', default_value: false )
      @create_zero_length_files = task_options_value( key: 'create_zero_length_files', default_value: DEFAULT_CREATE_ZERO_LENGTH_FILES )
      @export_files             = task_options_value( key: 'export_files',             default_value: DEFAULT_EXPORT_FILES )
      @export_files_newer_than_date = task_options_value( key: 'export_files_newer_than_date', default_value: DEFAULT_EXPORT_FILES_FILTER_DATE )
      @export_includes_callback = task_options_value( key: 'export_includes_callback', default_value: nil )
      @mode                     = task_options_value( key: 'mode',                     default_value: DEFAULT_MODE )
      @overwrite_export_files   = task_options_value( key: 'overwrite_export_files',   default_value: DEFAULT_OVERWRITE_EXPORT_FILES )
      @target_dir               = task_options_value( key: 'target_dir',               default_value: DEFAULT_TARGET_DIR )
      @validate_file_checksums  = task_options_value( key: 'validate_file_checksums',  default_value: DEFAULT_VALIDATE_FILE_CHECKSUMS )
      @populate_ids = []
      @populate_stats = []
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "@collect_exported_file_set_files=#{@collect_exported_file_set_files}",
                               "@create_zero_length_files=#{@create_zero_length_files}",
                               "@export_files=#{@export_files}",
                               "@export_files_newer_than_date=#{@export_files_newer_than_date}",
                               "@export_includes_callback=#{@export_includes_callback}",
                               "@mode=#{@mode}",
                               "@overwrite_export_files=#{@overwrite_export_files}",
                               "@target_dir=#{@target_dir}",
                               "@validate_file_checksums=#{@validate_file_checksums}",
                             ] if @debug_verbose
      raise UnknownMode.new( "mode: '#{@mode}'" ) unless ::Deepblue::MetadataHelper::VALID_MODES.include? @mode
    end

    def report_collection( first_id:, measurements:, total: nil )
      TaskHelper.benchmark_report( label: 'coll id',
                                   first_id: first_id,
                                   measurements: measurements,
                                   total: total,
                                   msg_handler: msg_handler )
    end

    def report_users( first_id:, measurements:, total: nil )
      TaskHelper.benchmark_report( label: 'users',
                                   first_id: first_id,
                                   measurements: measurements,
                                   total: total,
                                   msg_handler: msg_handler )
    end

    def report_stats
      return
      report_puts
      if @populate_ids.empty?
        report_puts "users: #{populate_stats[0][:total_users_exported]}"
        return
      end
      index = 0
      total_collections = 0
      total_works = 0
      total_file_sets = 0
      total_file_sets_size = 0
      populate_stats.each do |stats|
        collections = stats[:total_collections_exported]
        works = stats[:total_works_exported]
        file_sets = stats[:total_file_sets_exported]
        size_readable = stats[:total_file_sets_size_readable_exported]
        file_sets_size = stats[:total_file_sets_size_exported]
        id = @populate_ids[index]
        report_puts "#{id} collections: #{collections} works: #{works} file_sets: #{file_sets} size: #{size_readable}"
        total_collections += collections
        total_works += works
        total_file_sets = file_sets
        total_file_sets_size = file_sets_size
        index += 1
      end
      if @populate_ids.size > 1
        report_puts "totals collections: #{total_collections} works: #{total_works} file_sets: #{total_file_sets} size: #{TaskHelper.human_readable_size( total_file_sets_size )}"
      end
      report_puts
    end

    def report_work( first_id:, measurements:, total: nil )
      TaskHelper.benchmark_report( label: 'work id',
                                   first_id: first_id,
                                   measurements: measurements,
                                   total: total,
                                   msg_handler: msg_handler )
    end

    def run_all
      total = nil
      measurements = []
      curation_concerns = if 'work' == @populate_type
                            TaskHelper.all_works
                          else
                            Collection.all
                          end
      curation_concerns.each do |cc|
        @ids << cc.id
        subtotal = run_one_curation_concern( curation_concern: cc )
        measurements << subtotal
        if total.nil?
          total = subtotal
        else
          total += subtotal
        end
      end
      return measurements, total
    end

    def run_multiple( ids: )
      total = nil
      measurements = []
      ids.each do |id|
        subtotal = run_one( id: id )
        measurements << subtotal
        if total.nil?
          total = subtotal
        else
          total += subtotal
        end
      end
      return measurements, total
    end

    def run_one( id: )
      measurement = Benchmark.measure( id ) do
        if 'work' == @populate_type
          yaml_populate_work( id: id )
        else
          yaml_populate_collection( id: id )
        end
      end
      return measurement
    end

    def run_one_curation_concern( curation_concern: )
      measurement = Benchmark.measure( curation_concern.id ) do
        if 'work' == @populate_type
          yaml_populate_work( id: curation_concern.id, work: curation_concern )
        else
          yaml_populate_collection( id: curation_concern.id, collection: curation_concern )
        end
      end
      return measurement
    end

    def yaml_bag_work( id:, work: nil )
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "id=#{id}",
                               "work=#{work}",
                             ] if debug_verbose
      work ||= PersistHelper.find id
      sz = DeepblueHelper.human_readable_size( work.total_file_size )
      msg = "  Bagging work #{id} (#{sz}) to '#{@target_dir}'"
      report_puts msg
      log_filename = "w_#{id}.export.log"
      @mode = ::Deepblue::MetadataHelper::MODE_BAG
      service = YamlPopulateService.new( mode:                            @mode,
                                         msg_handler:                     @msg_handler,
                                         collect_exported_file_set_files: @collect_exported_file_set_files,
                                         create_zero_length_files:        @create_zero_length_files,
                                         overwrite_export_files:          @overwrite_export_files,
                                         validate_file_checksums:         @validate_file_checksums,
                                         export_includes_callback:        @export_includes_callback,
                                         debug_verbose:                   @debug_verbose )
      service.yaml_populate_work( curation_concern:         work,
                                  dir:                      @target_dir,
                                  export_files:             @export_files,
                                  export_files_newer_than_date: @export_files_newer_than_date,
                                  log_filename:             log_filename )
      @populate_ids << id
      @populate_stats << service.yaml_populate_stats
      return service
    end

    def yaml_populate_collection( id:, collection: nil )
      report_puts "Exporting collection #{id} to '#{@target_dir}' with export files flag set to #{@export_files} and mode #{@mode}"
      service = YamlPopulateService.new( mode:                     @mode,
                                         collect_exported_file_set_files: @collect_exported_file_set_files,
                                         create_zero_length_files: @create_zero_length_files,
                                         overwrite_export_files:   @overwrite_export_files,
                                         validate_file_checksums:  @validate_file_checksums )
      if collection.nil?
        service.yaml_populate_collection( collection: id, dir: @target_dir, export_files: @export_files )
      else
        service.yaml_populate_collection( collection: collection, dir: @target_dir, export_files: @export_files )
      end
      @populate_ids << id
      @populate_stats << service.yaml_populate_stats
      return service
    end

    def yaml_populate_work( id:, work: nil )
      report_puts "Exporting work #{id} to '#{@target_dir}' with export files flag set to #{@export_files} and mode #{@mode}"
      service = YamlPopulateService.new( mode:                     @mode,
                                         collect_exported_file_set_files: @collect_exported_file_set_files,
                                         create_zero_length_files: @create_zero_length_files,
                                         overwrite_export_files:   @overwrite_export_files,
                                         validate_file_checksums:  @validate_file_checksums )
      if work.nil?
        service.yaml_populate_work( curation_concern: id, dir: @target_dir, export_files: @export_files )
      else
        service.yaml_populate_work( curation_concern: work, dir: @target_dir, export_files: @export_files )
      end
      @populate_ids << id
      @populate_stats << service.yaml_populate_stats
      return service
    end

  end

end
