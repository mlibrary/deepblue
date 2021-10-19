# frozen_string_literal: true
module Hyrax
  module Doi
    module DoiPresenterBehavior
      extend ActiveSupport::Concern

      def doi
        solr_document.doi.present? ? "https://doi.org/#{solr_document.doi}" : nil
      end
    end
  end
end
