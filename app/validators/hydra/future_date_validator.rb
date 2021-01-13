# this monkey overrides Hydra::FutureDateValidator in the gem hydra-access-controls

module Hydra

  class FutureDateValidator < ActiveModel::EachValidator

    def validate_each(record, attribute, value)
      if value.present?
        # Deepblue::LoggingHelper.bold_puts [ Deepblue::LoggingHelper.here,
        #                                      Deepblue::LoggingHelper.called_from,
        #                                      "record=#{record}",
        #                                      "record.class.name=#{record.class.name}",
        #                                      "attribute=#{attribute}",
        #                                      "value=#{value}",
        #                                      "" ]
        begin
          if date = value.to_date
            # return if it's a FileSet
            return if record.is_a? FileSet # The parent dataset will have already validated this date
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
