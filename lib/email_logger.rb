# frozen_string_literal: true

class EmailLogger < Logger

  def format_message( _severity, _timestamp, _progname, msg )
    "#{msg}\n"
  end

end

# don't forget to request log roll-over script to not roll these files over
logfile = File.open( Rails.root.join( 'log', "email_#{Rails.env}.log" ), 'a' ) # create log file
logfile.sync = true # automatically flushes data to file
EMAIL_LOGGER = EmailLogger.new( logfile ) # constant accessible anywhere
