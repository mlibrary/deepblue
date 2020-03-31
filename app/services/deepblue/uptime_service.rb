# frozen_string_literal: true

module Deepblue

  module UptimeService

    # include ::Deepblue::InitializationConstants

    @@_setup_ran = false
    @@_setup_uptime_timestamp_file_written = false

    @@load_timestamp
    @@program_name
    @@uptime_dir = Rails.application.root.join.join( "data" ).join( "uptime" )

    mattr_accessor :load_timestamp,
                   :program_name,
                   :uptime_dir

    def self.setup
      yield self if @@_setup_ran == false
      setup_at_exit
      @@_setup_ran = true
    end

    def self.setup_at_exit
      return if @@_setup_ran

      at_exit do
        begin
          program_name = @@program_name
          return unless ( program_name == 'rails' || program_name == 'puma' )
          uptime_file_name = uptime_timestamp_file_path_self
          File.delete uptime_file_name  if File.exists? uptime_file_name
        rescue Exception => e # rubocop:disable Lint/RescueException
          # ignore
        end
      end

    end

    def self.uptime
      return nil if load_timestamp.nil?
      uptime_diff( DateTime.now, @@load_timestamp )
    end

    def self.uptime_in_minutes
      uptime * 1.minute
    end

    def self.uptime_human_readable
      # TODO
    end

    def self.uptime_vs_rails
      up = uptime_vs( program_name: "puma" )
      # puts "puma up = #{up}"
      return up unless up.nil?
      uptime_vs( program_name: "rails" )
    end

    def self.uptime_vs( program_name: )
      self_loadtime = @@load_timestamp
      # puts "self_loadtime=#{self_loadtime}"
      return nil if self_loadtime.nil?
      return self_loadtime if program_name == @@program_name
      other_loadtime = uptime_loadtime_of program_name: program_name
      # puts "other_loadtime=#{other_loadtime}"
      return nil if other_loadtime.nil?
      uptime_diff( other_loadtime, self_loadtime )
    end

    def self.uptime_loadtime_of( program_name: )
      file_of = uptime_timestamp_file_path( program_name: program_name )
      return nil unless File.exist? file_of
      file_contents = open( file_of, 'r' ) { |f| file_contents = f.readlines }
      # puts file_contents
      return nil if file_contents.empty?
      line = file_contents.first
      # puts line
      timestamp = DateTime.parse( line )
      # puts "uptime_loadtime_of #{program_name}=#{timestamp}"
      timestamp
    end

    def self.uptime_timestamp_file_write
      return false if @@_setup_uptime_timestamp_file_written
      uptime_file = uptime_timestamp_file_path
      open( uptime_file, 'w' ) { |f| f << load_timestamp.to_s }
      File.exist? uptime_file
    rescue Exception => e # rubocop:disable Lint/RescueException
      false
    end

    def self.uptime_timestamp_file_path_self
      uptime_timestamp_file_path( program_name: @@program_name )
    end

    def self.uptime_timestamp_file_path( program_name: nil )
      program_name = @@program_name if program_name.nil?
      @@uptime_dir.join( "#{program_name}.uptime" )
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
