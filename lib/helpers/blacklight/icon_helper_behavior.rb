# frozen_string_literal: true
# Added: hyrax4
# monkey - copied up from blacklight gem because the blacklight helpers were not being found


##
# Module to help generate icon helpers for SVG images
module Blacklight::IconHelperBehavior
  ##
  # Returns the raw SVG (String) for a Blacklight Icon located in
  # app/assets/images/blacklight/*.svg. Caches them so we don't have to look up
  # the svg everytime.
  # @param [String, Symbol] icon_name
  # @return [String]
  def blacklight_icon(icon_name, **kwargs)
    render "Blacklight::Icons::#{icon_name.to_s.camelize}Component".constantize.new(**kwargs)
  rescue NameError
    Rails.cache.fetch([:blacklight_icons, icon_name, kwargs]) do
      icon = Blacklight::Icon.new(icon_name, **kwargs)
      tag.span(icon.svg.html_safe, **icon.options)
    end
  end
end
