# frozen_string_literal: true

class EmailLogger < Logger

  def format_message( _severity, _timestamp, _progname, msg )
    "#{msg}\n"
  end

end

logfile = File.open( Rails.root.join( 'log', "email_#{Rails.env}.log" ), 'a' ) # create log file
logfile.sync = true # automatically flushes data to file
EMAIL_LOGGER = EmailLogger.new( logfile ) # constant accessible anywhere
