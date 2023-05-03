# frozen_string_literal: true
# hyrax-orcid

module Hyrax
  module Orcid
    module HelperBehavior
      include Hyrax::Orcid::UrlHelper
      include Hyrax::Orcid::OrcidHelper
      include Hyrax::Orcid::WorkHelper
      #include Hyrax::Orcid::RouteHelper
      include Hyrax::Orcid::JsonFieldHelper
    end
  end
end
