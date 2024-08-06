# frozen_string_literal: true
# Reviewed: hyrax4

module Hyrax
  class Pageview
    extend ::Legato::Model

    metrics :pageviews
    dimensions :date
    filter :for_path, &->(path) { contains(:pagePath, path) }
  end
end
