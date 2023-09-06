# frozen_string_literal: true

module Deepblue

  module ProvenanceHelper

    extend JsonLoggerHelper
    extend JsonLoggerHelper::ClassMethods

    mattr_accessor :write_to_db, default: Rails.configuration.provenance_log_write_to_db
    mattr_accessor :write_to_file, default: Rails.configuration.provenance_log_write_to_file

    # rubocop:disable Style/ClassVars
    def self.echo_to_rails_logger
      @@echo_to_rails_logger ||= Rails.configuration.provenance_log_echo_to_rails_logger
    end

    def self.echo_to_rails_logger=( echo_to_rails_logger )
      @@echo_to_rails_logger = echo_to_rails_logger
    end
    # rubocop:enable Style/ClassVars

    def self.log( class_name: 'UnknownClass',
                  event: 'unknown',
                  event_note: '',
                  id: 'unknown_id',
                  timestamp: timestamp_now,
                  time_zone: timestamp_zone,
                  echo_to_rails_logger: ProvenanceHelper.echo_to_rails_logger,
                  **log_key_values )

      log_to_db( class_name: class_name,
                 event: event,
                 event_note: event_note,
                 id: id,
                 timestamp: timestamp,
                 **log_key_values ) if write_to_db
      msg = nil
      msg = log_to_file( class_name: class_name,
                         event: event,
                         event_note: event_note,
                         id: id,
                         timestamp: timestamp,
                         time_zone: time_zone,
                         **log_key_values ) if write_to_file
      msg ||= msg_to_log( class_name: class_name,
                          event: event,
                          event_note: event_note,
                          id: id,
                          timestamp: timestamp,
                          time_zone: time_zone,
                          **log_key_values ) if echo_to_rails_logger
      Rails.logger.info msg if echo_to_rails_logger
    end

    def self.log_to_db( class_name:, event:, event_note:, id:, timestamp:, **log_key_values )
      Provenance.new( timestamp: timestamp,
                      event: event,
                      event_note: event_note,
                      class_name: class_name,
                      cc_id: id,
                      key_values: log_key_values
                    ).save
    end

    def self.log_to_file( class_name:, event:, event_note:, id:, timestamp:, time_zone:, **log_key_values )
      msg = msg_to_log( class_name: class_name,
                        event: event,
                        event_note: event_note,
                        id: id,
                        timestamp: timestamp,
                        time_zone: time_zone,
                        **log_key_values )
      log_raw msg
      return msg
    end

    def self.log_raw( msg )
      PROV_LOGGER.info( msg )
    end

  end

end
