# frozen_string_literal: true

module Deepblue

  require 'csv'
  require_relative '../../app/tasks/deepblue/abstract_task'

  class ExportImportCmdGenerator < AbstractTask

    DEFAULT_CMD_MODE = 'export' unless const_defined? :DEFAULT_CMD_MODE
    DEFAULT_EXPORT_FILES = true unless const_defined? :DEFAULT_EXPORT_FILES
    DEFAULT_IMPORT_OPTIONS = "-w -d -v" unless const_defined? :DEFAULT_IMPORT_OPTIONS
    DEFAULT_INPUT_DIR = "/deepbluedata-prep" unless const_defined? :DEFAULT_INPUT_DIR
    DEFAULT_INPUT_CSV_FILE = "#{DEFAULT_INPUT_DIR}/reports/works_report_works_sorted.csv" unless const_defined? :DEFAULT_INPUT_CSV_FILE
    DEFAULT_INPUT_CSV_FILE_HAS_HEADER = true unless const_defined? :DEFAULT_INPUT_CSV_FILE_HAS_HEADER
    DEFAULT_MAX_ID_COUNT = 20 unless const_defined? :DEFAULT_MAX_ID_COUNT
    DEFAULT_MAX_FILE_COUNT = 400 unless const_defined? :DEFAULT_MAX_FILE_COUNT
    DEFAULT_MAX_FILE_SIZE = 1024 * 1024 * 1024 * 100 unless const_defined? :DEFAULT_MAX_FILE_SIZE # 100 GB
    DEFAULT_MODE = "migrate" unless const_defined? :DEFAULT_MODE
    DEFAULT_NOHUP_ALLOWED = true unless const_defined? :DEFAULT_NOHUP_ALLOWED
    DEFAULT_NOHUP_FILE_COUNT = DEFAULT_MAX_FILE_COUNT / 2 unless const_defined? :DEFAULT_NOHUP_FILE_COUNT
    DEFAULT_NOHUP_FILE_SIZE = DEFAULT_MAX_FILE_SIZE / 2 unless const_defined? :DEFAULT_NOHUP_FILE_SIZE
    DEFAULT_OUTPUT_DIR = "/deepbluedata-prep/tmp" unless const_defined? :DEFAULT_OUTPUT_DIR
    DEFAULT_RAKE_TASK = "yaml_populate_from_multiple_works" unless const_defined? :DEFAULT_RAKE_TASK
    DEFAULT_SHELL_TASK = "migrate" unless const_defined? :DEFAULT_SHELL_TASK
    DEFAULT_TARGET_SCRIPT_DIR = "#{DEFAULT_OUTPUT_DIR}/scripts/" unless const_defined? :DEFAULT_TARGET_SCRIPT_DIR

    DEFAULT_CSV_ROW_INDEX_ID = 0 unless const_defined? :DEFAULT_CSV_ROW_INDEX_ID
    DEFAULT_CSV_ROW_INDEX_FILE_COUNT = 6 unless const_defined? :DEFAULT_CSV_ROW_INDEX_FILE_COUNT
    DEFAULT_CSV_ROW_INDEX_FILE_SIZE = 7 unless const_defined? :DEFAULT_CSV_ROW_INDEX_FILE_SIZE

    attr_accessor :input_dir, :output_dir, :input_csv_file, :input_csv_file_has_header
    attr_accessor :target_script_dir, :rake_task, :shell_task, :tstr
    attr_accessor :target_dir, :mode, :export_files, :export_options, :import_options, :nohup_allowed
    attr_accessor :max_id_count, :max_file_count, :nohup_file_count, :max_file_size, :nohup_file_size
    attr_accessor :csv_row_index_id, :csv_row_index_file_count, :csv_row_index_file_size
    attr_accessor :script_name

    def initialize( cmd_mode:, options: )
      super( options: options )
      @cmd_mode = cmd_mode
      @tstr = Time.now.strftime('%Y%m%d')
      @mode = task_options_value( key: 'mode', default_value: DEFAULT_MODE )
      @export_files = task_options_value( key: 'export_files', default_value: DEFAULT_EXPORT_FILES )
      default_target_dir = "/deepbluedata-tmp/DBDv1-#{tstr}/"
      @target_dir = task_options_value( key: 'target_dir', default_value: default_target_dir )
      @input_dir = task_options_value( key: 'input_dir', default_value: DEFAULT_INPUT_DIR )
      @output_dir = task_options_value( key: 'output_dir', default_value: DEFAULT_OUTPUT_DIR )
      @input_csv_file = task_options_value( key: 'input_csv_file', default_value: DEFAULT_INPUT_CSV_FILE )
      @input_csv_file_has_header = task_options_value( key: 'input_csv_file_has_header', default_value: DEFAULT_INPUT_CSV_FILE_HAS_HEADER )
      @target_script_dir = task_options_value( key: 'target_script_dir', default_value: DEFAULT_TARGET_SCRIPT_DIR )
      @rake_task = task_options_value( key: 'rake_task', default_value: DEFAULT_RAKE_TASK )
      @shell_task = task_options_value( key: 'shell_task', default_value: DEFAULT_SHELL_TASK )
      default_export_options = "'{\"target_dir\":\"#{@target_dir}\"\\,\"export_files\":#{@export_files}\\,\"mode\":\"#{@mode}\"}'"
      @export_options = task_options_value( key: 'export_options', default_value: default_export_options )
      @import_options = task_options_value( key: 'import_options', default_value: DEFAULT_IMPORT_OPTIONS )
      @nohup_allowed = task_options_value( key: 'nohup_allowed', default_value: DEFAULT_NOHUP_ALLOWED )
      @max_id_count = task_options_value( key: 'max_id_count', default_value: DEFAULT_MAX_ID_COUNT ).to_int
      @max_file_count = task_options_value( key: 'max_file_count', default_value: DEFAULT_MAX_FILE_COUNT ).to_int
      @nohup_file_count = task_options_value( key: 'nohup_file_count', default_value: DEFAULT_NOHUP_FILE_COUNT ).to_int
      @max_file_size = task_options_value( key: 'max_file_size', default_value: DEFAULT_MAX_FILE_SIZE ).to_int
      @nohup_file_size = task_options_value( key: 'nohup_file_size', default_value: DEFAULT_NOHUP_FILE_SIZE ).to_int
      @csv_row_index_id = task_options_value( key: 'csv_row_index_id', default_value: DEFAULT_CSV_ROW_INDEX_ID ).to_int
      @csv_row_index_file_count = task_options_value( key: 'csv_row_index_file_count', default_value: DEFAULT_CSV_ROW_INDEX_FILE_COUNT ).to_int
      @csv_row_index_file_size = task_options_value( key: 'csv_row_index_file_size', default_value: DEFAULT_CSV_ROW_INDEX_FILE_SIZE ).to_int
    end

    def print_export_script_line( out, line_count, ids, file_count, file_size )
      nohup = false
      if @nohup_allowed
        nohup = true if file_count > @nohup_file_count
        nohup = true if file_size > @nohup_file_size
      end
      out << "# #{line_count} # id_count=#{ids.size} file_count=#{file_count} file_size=#{TaskHelper.human_readable_size( file_size )}\n"
      ids_str = ids.join( ' ' )
      log_out = "#{@target_dir}/#{@tstr}-#{line_count}.#{@rake_task}.out"
      cmd_and_args = "bundle exec rake deepblue:#{@rake_task}['#{ids_str}',#{@export_options}]"
      if nohup
        out << "nohup #{cmd_and_args} 2>&1 > #{log_out} &\n"
        out << "tail -f #{log_out}\n"
      else
        out << "#{cmd_and_args} 2>&1 | tee #{log_out}\n"
      end
      return true
    end

    def print_import_script_line( out, line_count, ids, file_count, file_size )
      nohup = false
      if @nohup_allowed
        nohup = true if file_count > @nohup_file_count
        nohup = true if file_size > @nohup_file_size
      end
      out << "# #{line_count} # id_count=#{ids.size} file_count=#{file_count} file_size=#{TaskHelper.human_readable_size( file_size )}\n"
      ids_str = ids.join( ' ' )
      log_out = "#{@target_dir}/#{@tstr}-#{line_count}.#{@shell_task}.out"
      cmd_and_args = "./bin/umrdr_new_content.sh #{@import_options} -t umrdr:#{@shell_task} -b #{@target_dir} #{ids_str}"
      if nohup
        out << "nohup #{cmd_and_args} 2>&1 > #{log_out} &\n"
        out << "tail -f #{log_out}\n"
      else
        out << "#{cmd_and_args} 2>&1 | tee #{log_out}\n"
      end
      return true
    end

    def print_script_line( out, line_count, ids, file_count, file_size )
      printed = false
      if ids.size >= @max_id_count || file_count >= @max_file_count || file_size >= @max_file_size
        printed = if 'export' == @cmd_mode
                    print_export_script_line( out, line_count, ids, file_count, file_size )
                  else
                    print_import_script_line( out, line_count, ids, file_count, file_size )
                  end
      end
      return printed
    end

    def print_all_scripts
      @script_name = Pathname.new @target_script_dir
      @script_name = @script_name.join "#{@tstr}.#{@cmd_mode}.sh"
      File.open( script_name, 'w' ) do |out|
        out << "mkdir #{@target_dir}\n" if @cmd_mode == 'export'
        file_count = 0
        file_size = 0
        line_count = 1
        ids = []
        rows_processed = 0
        ids_processed = 0
        header_row = input_csv_file_has_header
        CSV.foreach( @input_csv_file ) do |row|
          if header_row
            header_row = false
            next
          end
          id = row[@csv_row_index_id]
          ids << id
          file_count += row[@csv_row_index_file_count].to_i
          file_size += row[@csv_row_index_file_size].to_f
          if print_script_line( out, line_count, ids, file_count, file_size )
            line_count += 1
            file_count = 0
            file_size = 0
            ids_processed += ids.size
            ids = []
          end
          rows_processed += 1
        end
        out << "#\n# rows_processed=#{rows_processed} ids_processed=#{ids_processed}\n"
      end
    end

  end

end
