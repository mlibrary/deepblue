# frozen_string_literal: true

module ProvenanceHelper

  def self.system_as_current_user
    "Deepblue"
  end

  def self.log( class_name: 'UnknownClass',
                event: 'unknown',
                event_note: '',
                id: 'unknown_id',
                timestamp: Time.now.to_formatted_s(:db),
                echo_to_rails_logger_info: DeepBlueDocs::Application.config.provenance_log_default_echo_to_rails_logger_info,
                **prov_key_values )

    if event_note.blank?
      key_values = { event: event, timestamp: timestamp, class_name: class_name, id: id }
      event += '/'
    else
      key_values = { event: event, event_note: event_note, timestamp: timestamp, class_name: class_name, id: id }
      event = "#{event}/#{event_note}"
    end
    key_values.merge! prov_key_values
    json = ActiveSupport::JSON.encode key_values
    msg = "#{timestamp} #{event}/#{class_name}/#{id} #{json}"
    raw_log msg
    Rails.logger.info msg if echo_to_rails_logger_info
  end

  def self.raw_log( msg )
    PROV_LOGGER.info( msg )
  end

end
