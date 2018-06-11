# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/renderers/hyrax/renderers/attribute_renderer.rb" )

module Hyrax
  module Renderers

    # monkey patch Hyrax::Renderers::AttributeRenderer
    class AttributeRenderer
      # TODO: add support for multiple work_types in options
    end

  end
end
