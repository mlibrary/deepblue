# frozen_string_literal: true
module Hyrax
  module Doi
    module WorkShowHelper
      def render_doi?(presenter)
        return false unless presenter.class.ancestors.include? Hyrax::Doi::DoiPresenterBehavior
        return presenter.doi_status_when_public.in? [nil, 'registered', 'findable'] if presenter.class.ancestors.include? Hyrax::Doi::DataCiteDoiPresenterBehavior
        true
      end
    end
  end
end
