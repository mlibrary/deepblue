# frozen_string_literal: true
# hyrax-orcid

# In an attempt to try and organise Bolognese methods a little, i'm trying this
module Bolognese
  module Helpers
    module Dates
      extend ActiveSupport::Concern

      # Returns an array of hashes, with namespaced keys:
      # [{"date_published_year"=>2019, "date_published_month"=>9, "date_published_day"=>27}]
      def date_published
        publication_date = collect_date("Issued") || publication_year

        hash_from_date("date_published", Array(date_from_string(publication_date)))
      end

      # Date values are formatted without number padding in the form
      def date_from_string(date_string)
        return if date_string.blank?

        Date.edtf(date_string)
      end

      # Return a an array containing a date hash formatted as the work forms require
      def hash_from_date(field, dates)
        dates.map do |date|
          {
            "#{field}_year" => date.year,
            "#{field}_month" => date.month,
            "#{field}_day" => date.day
          }
        end
      end

      # `dates` is an array of hashes containing a string date and named dateType
      def collect_date(type)
        dates.find { |hash| hash["dateType"] == type }&.dig("date")
      end
    end
  end
end
