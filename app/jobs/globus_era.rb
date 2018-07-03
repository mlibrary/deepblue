# frozen_string_literal: true

require 'thread'
require 'singleton'

module Deepblue

  class GlobusEra
    # include Singleton

    @@mutex = Thread::Mutex.new
    @@c_era_initialized = false

    attr_reader :era_file, :era_begin_timestamp, :era_file_base, :era_verbose, :previous_era_begin_timestamp

    def self.initialize_class_vars
      @@mutex.synchronize do
        unless @@c_era_initialized
          @@c_era_initialized = true
          @@c_era_verbose = true
          @@c_era_begin_timestamp = Time.now.to_s
          @@c_era_file_base = ".globus_era.#{Socket.gethostname}"
          # log "hostname=#{Socket.gethostname}" if @@c_era_verbose
          if DeepBlueDocs::Application.config.globus_enabled
            log "GlobusEra initializing at #{@@c_era_begin_timestamp}" if @@c_era_verbose
            # @era_file = Tempfile.new( 'globus_era_', DeepBlueDocs::Application.config.globus_prep_dir )
            @@c_era_file = DeepBlueDocs::Application.config.globus_prep_dir.join @@c_era_file_base
            log "GlobusEra era file: #{@@c_era_file} -- #{@@c_era_file.class}" if @@c_era_verbose
            read_previous_era_file
            File.open( @@c_era_file, "w" ) { |out| out << @@c_era_begin_timestamp << "\n" }
            at_exit { File.delete @@c_era_file if File.exist? @@c_era_file }
            log "GlobusEra initialized." if @@c_era_verbose
          else
            @@c_era_file = nil
          end
        end
      end
    end

    def initialize
      GlobusEra.initialize_class_vars
      @era_verbose = @@c_era_verbose
      @era_begin_timestamp = @@c_era_begin_timestamp
      @era_file_base = @@c_era_file_base
      @era_file = @@c_era_file
    end

    def self.log( msg )
      if Rails.logger.nil?
        puts msg # rubocop:disable Rails/Output
      else
        Rails.logger.info msg
      end
    end

    def previous_era?
      !@previous_era_begin_timestamp.nil?
    end

    def self.read_previous_era_file
      # TODO: look for previous era file and store it in:
      @@c_previous_era_begin_timestamp = nil
      return unless File.exist? @@c_era_file
      timestamp = nil
      open( lock_file, 'r' ) { |f| timestamp = f.read.chomp! }
      @@c_previous_era_begin_timestamp = timestamp
      puts "GlobusEra found previous GlobusEra #{@@c_previous_era_begin_timestamp}" # rubocop:disable Rails/Output
    end

    def read_token
      token = nil
      open( @era_file, 'r' ) { |f| token = f.read.chomp! }
      return token
    end

    def read_token_time
      timestamp = read_token
      Time.parse( timestamp )
    end

  end

end
