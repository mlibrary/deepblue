# this monkey overrides Hydra::FutureDateValidator in the gem hydra-access-controls

module Hydra

  class FutureDateValidator < ActiveModel::EachValidator

    def validate_each(record, attribute, value)
      if value.present?
        begin
          if date = value.to_date
            if attribute.to_s == "embargo_release_date"
              return unless DeepBlueDocs::Application.config.embargo_enforce_future_release_date
            end
            if date <= Date.today
              # Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
              #                                      Deepblue::LoggingHelper.called_from,
              #                                      "date=#{date}",
              #                                      "attribute=#{attribute}" ] # + caller_locations(1, 40)
              record.errors[attribute] << "FutureDateValidator says Must be a future date"
            end
          else
            record.errors[attribute] << "Invalid Date Format"
          end
        rescue ArgumentError, NoMethodError
          record.errors[attribute] << "Invalid Date Format"
        end
      end
    end

  end

end
