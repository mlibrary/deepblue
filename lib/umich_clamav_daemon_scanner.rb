# frozen_string_literal: true

# An AV class that streams the file to an already-running
# clamav daemon

require 'abstract_virus_scanner'
require 'null_virus_scanner'
require 'clamav/client'

class UMichClamAVDaemonScanner < AbstractVirusScanner

  mattr_accessor :umich_clamav_daemon_scanner_debug_verbose,
                 default: ::Deepblue::VirusScanService.umich_clamav_daemon_scanner_debug_verbose

  # standard umich clamav configuration (from /etc/clamav/clamav.conf)

  CONNECTION_TYPE = :tcp        unless const_defined? :CONNECTION_TYPE
  PORT            = 3310        unless const_defined? :PORT
  MACHINE         = '127.0.0.1' unless const_defined? :MACHINE
  CHUNKSIZE       = 4096        unless const_defined? :CHUNKSIZE

  class CannotConnectClient < NullVirusScanner

    def initialize( file )
      super( file )
    end

  end

  attr_accessor :client
  attr_accessor :total_scanned_bytes

  def self.infected?(path)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "path=#{path}",
                                           "" ] if umich_clamav_daemon_scanner_debug_verbose
    rv = new(path).infected?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "path=#{path}",
                                           "rv=#{rv}",
                                           "" ] if umich_clamav_daemon_scanner_debug_verbose
    return rv
  end

  def initialize( filename )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "filename=#{filename}",
                                           "" ] if umich_clamav_daemon_scanner_debug_verbose
    super
    @total_scanned_bytes = 0
    @client = begin
      connection = ClamAV::Connection.new( socket:  ::TCPSocket.new('127.0.0.1', 3310),
                                           wrapper: ::ClamAV::Wrappers::NewLineWrapper.new )
      ClamAV::Client.new(connection)
    rescue Errno::ECONNREFUSED => e # rubocop:disable Lint/UselessAssignment
      CannotConnectClient.new( filename )
    end
  end

  # Check to see if we can connect to the configured
  # ClamAV daemon
  def alive?
    case client
    when CannotConnectClient
      false
    else
      client.execute( ClamAV::Commands::PingCommand.new )
    end
  end

  def infected?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "file=#{file}",
                                           "file exists?=#{File.exist? file}",
                                           "" ] if umich_clamav_daemon_scanner_debug_verbose
    unless alive?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file=#{file}",
                                             "file exists?=#{File.exist? file}",
                                             "" ] if umich_clamav_daemon_scanner_debug_verbose
                                             #"Call stack:" ] + caller_locations(0..30) if umich_clamav_daemon_scanner_debug_verbose
      warning "Cannot connect to virus scanner. Skipping file #{file}" unless Rails.env.test?
      return ::Deepblue::VirusScanService::VIRUS_SCAN_SKIPPED_SERVICE_UNAVAILABLE
    end
    resp = scan_response
    rv = case resp
         when ClamAV::SuccessResponse
           info "Clean virus check for '#{file}'"
           ::Deepblue::VirusScanService::VIRUS_SCAN_NOT_VIRUS
         when ClamAV::VirusResponse
           warn "Virus #{resp.virus_name} found in file '#{file}'"
           ::Deepblue::VirusScanService::VIRUS_SCAN_VIRUS
         when ClamAV::ErrorResponse
           warn "ClamAV error: #{resp.error_str} for file #{file}. File not scanned!"
           ::Deepblue::VirusScanService::VIRUS_SCAN_ERROR # err on the side of trust? Need to think about this
         else
           warn "ClamAV response unknown type '#{resp.class}': #{resp}. File not scanned!"
           ::Deepblue::VirusScanService::VIRUS_SCAN_UNKNOWN
         end
    return rv
  end

  def scan_response
    begin
      file_io = File.open( file, 'rb' )
    rescue => e
      msg = "Can't open file #{file} for scanning: #{e}"
      error msg
      raise msg
    end
    rv = scan( file_io ) { |cmd| @total_scanned_bytes += cmd.total_bytes_scanned }
    return rv
  end

  # Do the scan by streaming to the daemon
  # @param [#read] io The IO stream (probably an open file) to read from
  # @return A ClamAV::*Response object
  def scan(io)
    cmd = UMInstreamScanner.new(io, CHUNKSIZE)
    rv = client.execute(cmd)
    yield cmd if block_given?
    return rv
  end


  private

    # Set up logging for the clamav daemon scanner

    def debug( msg )
      Hyrax.logger&.debug( msg )
    end

    def error( msg )
      Hyrax.logger&.error( msg )
    end

    def info( msg )
      Hyrax.logger&.info( msg )
    end

    def warning( msg )
      Hyrax.logger&.warn( msg )
    end

end


# Stream a file to the AV scanner in chunks to avoid
# reading it all into memory. Internal to how
# ClamAV::Client works
class UMInstreamScanner < ClamAV::Commands::InstreamCommand

  attr_accessor :total_bytes_scanned

  def initialize(io, max_chunk_size = nil)
    super
    @total_bytes_scanned = 0
  end

  def call(conn)
    conn.write_request("INSTREAM")
    while (packet = @io.read(@max_chunk_size))
      scan_packet(conn, packet)
      @total_bytes_scanned += packet.size
    end
    send_end_of_file(conn)
    av_return_status(conn)
  rescue => e
    ClamAV::ErrorResponse.new( "Error sending data to ClamAV Daemon: #{e}" )
  end

  def av_return_status(conn)
    get_status_from_response(conn.read_response)
  end

  def send_end_of_file(conn)
    conn.raw_write("\x00\x00\x00\x00")
  end

  def scan_packet(conn, packet)
    packet_size = [packet.size].pack("N")
    conn.raw_write("#{packet_size}#{packet}")
  end

end

# To use a virus checker other than ClamAV:
#   class MyScanner < Hydra::Works::VirusScanner
#     def infected?
#       my_result = Scanner.check_for_viruses(file)
#       [return true or false]
#     end
#   end
