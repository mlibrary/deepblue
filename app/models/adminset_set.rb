# frozen_string_literal: true

class AdminsetSet < ::BlacklightOaiProvider::SolrSet
  def description
    if label && value
      "This set includes works in the #{value.capitalize} Admin Set."
    else
      'No description available.'
    end
  end
end
