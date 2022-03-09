# frozen_string_literal: true

require './lib/irus_logger'
require_relative './logging_helper'

module Deepblue::IrusHelper

  extend ::Deepblue::JsonLoggerHelper
  extend ::Deepblue::JsonLoggerHelper::ClassMethods

  mattr_accessor :irus_log_echo_to_rails_logger,
                 default: Rails.configuration.irus_log_echo_to_rails_logger

  def self.log( class_name: 'UnknownClass',
                event: 'unknown',
                event_note: '',
                id: 'unknown_id',
                request:,
                timestamp: timestamp_now,
                echo_to_rails_logger: irus_log_echo_to_rails_logger,
                **log_key_values )

    log_key_values = log_key_values.merge( remote_addr: request.env['REMOTE_ADDR'],
                                           request_uri: request.env['REQUEST_URI'],
                                           http_user_agent: request.env['HTTP_USER_AGENT'],
                                           referrer_ip: request.env['action_dispatch.remote_ip'].to_s )
    msg = msg_to_log( class_name: class_name,
                      event: event,
                      event_note: event_note,
                      id: id,
                      timestamp: timestamp,
                      time_zone: ::Deepblue::LoggingHelper.timestamp_zone,
                      **log_key_values )
    log_raw msg
    Rails.logger.info msg if echo_to_rails_logger
  end

  def self.log_raw( msg )
    ::Deepblue::IRUS_LOGGER.info( msg )
  end

end
