# frozen_string_literal: true
# Added: hyrax4
# monkey - copied up from blacklight gem because the blacklight helpers were not being found

module Blacklight::Base
  extend ActiveSupport::Concern

  include Blacklight::Configurable
  include Blacklight::SearchContext

  def self.included(mod)
    Deprecation.warn(Blacklight::Base, "Blacklight::Base is deprecated and will be removed in Blacklight 8.0.0.
	Include Blacklight::Configurable and Blacklight::SearchContext as needed (included in #{mod}).")
  end
end
