# frozen_string_literal: true

# An AV class that streams the file to an already-running
# clamav daemon

require 'abstract_virus_scanner'
require 'null_virus_scanner'
require 'clamav/client'

class UMichClamAVDaemonScanner < AbstractVirusScanner

  # standard umich clamav configuration (from /etc/clamav/clamav.conf)

  CONNECTION_TYPE = :tcp
  PORT            = 3310
  MACHINE         = '127.0.0.1'

  CHUNKSIZE = 4096

  class CannotConnectClient < NullVirusScanner

    def initialize( file )
      super( file )
    end

  end

  attr_accessor :client

  def initialize( filename )
    super
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
                               "UMichClamAVDaemonScanner.infected? File '#{file}' exists? #{File.exist? file}" ]
    unless alive?
      warning "Cannot connect to virus scanner. Skipping file #{file}"
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

    scan( file_io )
  end

  # Do the scan by streaming to the daemon
  # @param [#read] io The IO stream (probably an open file) to read from
  # @return A ClamAV::*Response object
  def scan(io)
    cmd = UMInstreamScanner.new(io, CHUNKSIZE)
    client.execute(cmd)
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


# Stream a file to the AV scanner in chucks to avoid
# reading it all into memory. Internal to how
# ClamAV::Client works
class UMInstreamScanner < ClamAV::Commands::InstreamCommand

  def call(conn)
    conn.write_request("INSTREAM")
    while (packet = @io.read(@max_chunk_size))
      scan_packet(conn, packet)
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
