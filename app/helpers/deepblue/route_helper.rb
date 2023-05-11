# frozen_string_literal: true

module Deepblue

  module RouteHelper

    def self.relative_url( route )
      return route unless Rails.configuration.relative_url_root.present?
      return route if route.start_with?( Rails.configuration.relative_url_root )
      return "#{Rails.configuration.relative_url_root}#{route}"
    end

  end

end
