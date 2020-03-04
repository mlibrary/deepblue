require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/presenters/hyrax/presents_attributes.rb" )

module Hyrax

  # monkey patch Presenters::Hyrax::PresentsAttributes
  module PresentsAttributes

    ##
    # Present the attribute as an HTML table row or dl row.
    #
    # @param [Hash] options
    # @option options [Symbol] :render_as use an alternate renderer
    #   (e.g., :linked or :linked_attribute to use LinkedAttributeRenderer)
    # @option options [String] :search_field If the method_name of the attribute is different than
    #   how the attribute name should appear on the search URL,
    #   you can explicitly set the URL's search field name
    # @option options [String] :label The default label for the field if no translation is found
    # @option options [TrueClass, FalseClass] :include_empty should we display a row if there are no values?
    # @option options [String] :work_type name of work type class (e.g., "GenericWork")
    def attribute_to_html(field, options = {})
      unless respond_to?(field)
        Rails.logger.warn("#{self.class} attempted to render #{field}, but no method exists with that name.")
        return
      end

      if options[:html_dt]
        renderer_for(field, options).new(field, send(field), options).render_dt_row
      elsif options[:html_dl]
        renderer_for(field, options).new(field, send(field), options).render_dl_row
      else
        renderer_for(field, options).new(field, send(field), options).render
      end
    end

  end

end
