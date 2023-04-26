# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module JsonFieldHelper
      def participant_to_string(type, arr)
        return "-" if arr.blank?

        arr
          .first
          .then { |s| JSON.parse(s) }
          .each_with_object([]) { |h, s| s << h["#{type}_name"] }
          .join(", ")
      end
    end
  end
end
