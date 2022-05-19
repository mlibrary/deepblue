# frozen_string_literal: true

class AssetsLogger < Logger

  def format_message( _severity, _timestamp, _progname, msg )
    "#{msg}\n"
  end

end

logfile = File.open( Rails.root.join( 'log', "assets_#{Rails.env}.log" ), 'a' ) # create log file
logfile.sync = true # automatically flushes data to file
ASSETS_LOGGER = AssetsLogger.new( logfile ) # constant accessible anywhere
