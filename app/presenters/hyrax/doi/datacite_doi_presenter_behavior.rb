# frozen_string_literal: true
module Hyrax
  module Doi
    module DataCiteDoiPresenterBehavior
      extend ActiveSupport::Concern

      delegate :doi_status_when_public, to: :solr_document

      # Should this make a request to DataCite?
      # Or maybe DataCite could supply badges?
      def doi_status
        if doi_status_when_public == 'findable' && !solr_document.public?
          'registered'
        else
          doi_status_when_public
        end
      end
    end
  end
end
