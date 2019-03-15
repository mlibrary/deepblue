module Hyrax
  class Pageview
    extend ::Legato::Model

    metrics :pageviews
    dimensions :date, :pagePath
    filter :for_path, &->(path) { contains(:pagePath, path) }
  end
end
