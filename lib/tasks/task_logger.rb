require 'logger'

module Umrdr

  class TaskLogger < Logger

    # TODO: add flags for turning on and off parts of message

    def format_message( severity, timestamp, progname, msg )
      #"#{timestamp.to_formatted_s(:db)} #{severity} User: #{EmailHelper.user_email} #{msg}\n"
      "#{msg}\n"
    end

  end

end
