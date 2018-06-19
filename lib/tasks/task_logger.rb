# frozen_string_literal: true

require 'logger'

module Deepblue

  class TaskLogger < Logger

    # TODO: add flags for turning on and off parts of message

    def format_message( _severity, _timestamp, _progname, msg )
      # "#{timestamp.to_formatted_s(:db)} #{severity} User: #{Deepblue::EmailHelper.user_email} #{msg}\n"
      "#{msg}\n"
    end

  end

end
