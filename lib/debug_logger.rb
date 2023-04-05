# frozen_string_literal: true

class DebugLogger < Logger

  mattr_accessor :log_file, default: Rails.root.join( 'log', "debug_#{Rails.env}.log" )

  def format_message( _severity, _timestamp, _progname, msg )
    "#{msg}\n"
  end

end

logfile = File.open( Rails.root.join( 'log', DebugLogger.log_file ), 'a' ) # create log file
logfile.sync = true # automatically flushes data to file
DEBUG_LOGGER = DebugLogger.new( logfile ) # constant accessible anywhere
