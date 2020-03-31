# frozen_string_literal: true

module Deepblue

  module UptimeService

    # include ::Deepblue::InitializationConstants

    UPDATE_SERVICE_DEBUG_VERBOSE = false

    @@_setup_failed = false
    @@_setup_ran = false
    @@_setup_uptime_timestamp_file_written = false

    @@program_arg1
    @@uptime_dir = Rails.application.root.join( "data", "uptime" )

    mattr_accessor :program_arg1,
                   :uptime_dir

    def self.setup
      return if @@_setup_ran == false
      @@_setup_ran = true
      puts "@@_setup_uptime_timestamp_file_written=#{@@_setup_uptime_timestamp_file_written}" if UPDATE_SERVICE_DEBUG_VERBOSE
      begin
        yield self
      rescue Exception => e # rubocop:disable Lint/RescueException
        @@_setup_failed = true
      end
      at_exit do
        begin
          uptime_file_name = uptime_timestamp_file_path_self
          puts "attempting to delete #{uptime_file_name}" if UPDATE_SERVICE_DEBUG_VERBOSE
          File.delete uptime_file_name if File.exists? uptime_file_name
        rescue Exception => e # rubocop:disable Lint/RescueException
          # ignore
        end
      end
    end

    def self.is_console?
      Rails.const_defined? 'Console'
    end

    def self.is_rails?
      program_name == 'puma' || program_name == 'rails'
    end

    def self.is_rails_console?
      Rails.const_defined? 'Console'
      # program_name == 'rails-console' || ( program_name == 'rails' && program_arg1 == 'console' )
    end

    def self.is_rake?
      program_name == 'rake'
    end

    def self.is_resque_pool?
      program_name == 'resque-pool'
    end

    def self.is_server?
      program_name == 'rails' || program_name == 'puma'
    end

    def self.program_args
      DeepBlueDocs::Application.config.program_args
    end

    def self.program_load_timestamp
      DeepBlueDocs::Application.config.load_timestamp
    end

    def self.program_name
      return 'rails-console' if Rails.const_defined? 'Console'
      DeepBlueDocs::Application.config.program_name
    end

    def self.uptime
      return nil if program_load_timestamp.nil?
      uptime_diff( DateTime.now, program_load_timestamp )
    end

    def self.uptime_in_minutes
      uptime * 1.minute
    end

    def self.uptime_human_readable
      # TODO
    end

    def self.uptime_loadtime_of( program_name: )
      file_of = uptime_timestamp_file_path( program_name: program_name )
      return nil unless File.exist? file_of
      file_contents = open( file_of, 'r' ) { |f| file_contents = f.readlines }
      # puts file_contents if UPDATE_SERVICE_DEBUG_VERBOSE
      return nil if file_contents.empty?
      line = file_contents.first
      # puts line if UPDATE_SERVICE_DEBUG_VERBOSE
      timestamp = DateTime.parse( line )
      # puts "uptime_loadtime_of #{program_name}=#{timestamp}" if UPDATE_SERVICE_DEBUG_VERBOSE
      timestamp
    end

    def self.uptime_rails
      return uptime if is_rails?
      up = uptime_loadtime_of program_name: 'puma'
      return up unless up.nil?
      uptime_loadtime_of program_name: 'rails'
    end

    def self.uptime_timestamp_files
      Dir.glob( @@uptime_dir.join('*').to_s )
    end

    def self.uptime_timestamp_file_write
      return if is_console?
      puts "uptime_timestamp_file_write  @@_setup_uptime_timestamp_file_written=#{@@_setup_uptime_timestamp_file_written}" if UPDATE_SERVICE_DEBUG_VERBOSE
      return false if @@_setup_uptime_timestamp_file_written
      puts "uptime_timestamp_file_write after one entry test" if UPDATE_SERVICE_DEBUG_VERBOSE
      uptime_file = uptime_timestamp_file_path_self
      puts "uptime_timestamp_file_write #{uptime_file}" if UPDATE_SERVICE_DEBUG_VERBOSE
      open( uptime_file, 'w' ) { |f| f << program_load_timestamp.to_s }
      puts "File.exist? uptime_file #{File.exist?(uptime_file)}"
      File.exist? uptime_file
    rescue Exception => e # rubocop:disable Lint/RescueException
      puts "e => #{e} #{e.backtrace.join("\n")}" if UPDATE_SERVICE_DEBUG_VERBOSE
      false
    end

    def self.uptime_timestamp_file_path( program_name: nil )
      program_name = self.program_name if program_name.nil?
      @@uptime_dir.join( "#{program_name}.uptime" )
    end

    def self.uptime_timestamp_file_path_self
      if is_rake?
        # @@uptime_dir.join( "#{program_name}_#{$PID}_#{@@program_arg1}.uptime" )
        @@uptime_dir.join( "#{program_name}_#{$PID}.uptime" )
      elsif is_console?
        @@uptime_dir.join( "#{program_name}_#{$PID}.uptime" )
      else
        @@uptime_dir.join( "#{program_name}.uptime" )
      end
    end

    def self.uptime_timestamp_from_file( file: )
      return nil unless File.exist? file
      file_contents = open( file, 'r' ) { |f| file_contents = f.readlines }
      # puts file_contents if UPDATE_SERVICE_DEBUG_VERBOSE
      return nil if file_contents.empty?
      line = file_contents.first
      # puts line if UPDATE_SERVICE_DEBUG_VERBOSE
      timestamp = DateTime.parse( line )
      # puts "uptime_loadtime_of #{program_name}=#{timestamp}" if UPDATE_SERVICE_DEBUG_VERBOSE
      timestamp
    end

    def self.uptime_vs( program_name: )
      self_loadtime = program_load_timestamp
      # puts "self_loadtime=#{self_loadtime}" if UPDATE_SERVICE_DEBUG_VERBOSE
      return nil if self_loadtime.nil?
      return self_loadtime if program_name == self.program_name
      other_loadtime = uptime_loadtime_of program_name: program_name
      # puts "other_loadtime=#{other_loadtime}" if UPDATE_SERVICE_DEBUG_VERBOSE
      return nil if other_loadtime.nil?
      uptime_diff( other_loadtime, self_loadtime )
    end

    def self.uptime_vs_rails
      up = uptime_vs( program_name: "puma" )
      # puts "puma up = #{up}" if UPDATE_SERVICE_DEBUG_VERBOSE
      return up unless up.nil?
      uptime_vs( program_name: "rails" )
    end

    private

      def self.uptime_diff( time1, time2 )
        return nil if time1.nil?
        return nil if time2.nil?
        return uptime_to_f( time1 ) - uptime_to_f( time2 )
      end

      def self.uptime_readable
        # TODO
      end

      def self.uptime_to_f( time )
        return time.to_f if time.is_a? Numeric
        return 0.to_f if time.nil?
        time.to_time.to_f
      end

  end

end
