# frozen_string_literal: true

class ProvenanceLogger < Logger
  def format_message( _severity, _timestamp, _progname, msg )
    "#{msg}\n"
  end
end

# logfile = File.open("#{Rails.root}/log/custom.log", 'a')  # create log file
logfile = File.open( Rails.root.join( 'log', "provenance_#{Rails.env}.log" ), 'a' ) # create log file
logfile.sync = true # automatically flushes data to file
PROV_LOGGER = ProvenanceLogger.new( logfile ) # constant accessible anywhere
