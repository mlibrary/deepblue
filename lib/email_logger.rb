# frozen_string_literal: true

class EmailLogger < Logger

  mattr_accessor :log_file, default: Rails.root.join( 'log', "email_#{Rails.env}.log" )

  def format_message( _severity, _timestamp, _progname, msg )
    "#{msg}\n"
  end

end

logfile = File.open( Rails.root.join( 'log', EmailLogger.log_file ), 'a' ) # create log file
logfile.sync = true # automatically flushes data to file
EMAIL_LOGGER = EmailLogger.new( logfile ) # constant accessible anywhere
