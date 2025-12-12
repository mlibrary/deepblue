# frozen_string_literal: true
# Reviewed: heliotrope
# Reviewed: hyrax4

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/presenters/hyrax/presents_attributes.rb" )

module Hyrax

  # monkey patch Presenters::Hyrax::PresentsAttributes
  module PresentsAttributes

    mattr_accessor :presents_attribute_debug_verbose, default: false

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
    def attribute_to_html(field, options = {}) # monkey override
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "field=#{field}",
                                             "options=#{options}",
                                             "" ] if presents_attribute_debug_verbose
      unless respond_to?(field)
        Rails.logger.warn("#{self.class} attempted to render #{field}, but no method exists with that name.")
        return
      end

      return if options[:anonymous_hide]

      value = send(field)
      renderer = renderer_for(field, options).new(field, value, options)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "field=#{field}",
                                             "value=#{value}",
                                             "renderer.class.name=#{renderer.class.name}",
                                             "" ] if presents_attribute_debug_verbose
      if options[:html_dt]
        renderer.render_dt_row
      elsif options[:html_dl]
        renderer.render_dl_row
      else
        renderer.render
      end
    end

    def find_renderer_class(name) # monkey
      renderer = nil
      ['Renderer', 'AttributeRenderer'].each do |suffix|
        const_name = "#{name.to_s.camelize}#{suffix}".to_sym
        renderer = begin
                     Renderers.const_get(const_name)
                   rescue NameError
                     nil
                   end
        break unless renderer.nil?
      end
      raise NameError, "unknown renderer type `#{name}`" if renderer.nil?
      renderer
    end

    # monkey
    def permission_badge
      solr_doc = solr_document
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_doc.class.name=#{solr_doc.class.name}",
                                             "solr_doc.visibility=#{solr_doc.visibility}",
                                             "" ] if presents_attribute_debug_verbose
      vis = solr_doc.visibility
      permission_badge_class.new(vis).render
    end

    def permission_badge_class
      PermissionBadge
    end

    def renderer_for(_field, options) # monkey override
      if options[:render_as]
        find_renderer_class(options[:render_as])
      else
        Renderers::AttributeRenderer
      end
    end

    # # monkey
    # def present_authors
    #   author = attribute_to_html(:creator, render_as: :faceted, label: I18n.t('show.labels.creator') )
    #   return author if author.blank?
    #   author.gsub!('itemscope itemtype="http://schema.org/Person"', '')
    # end
    #
    # # monkey
    # def present_authors_compact
    #   authors = attribute_to_html(:creator, {render_as: :faceted, label: I18n.t('show.labels.creator')} )
    #   unless authors.blank?
    #     authors&.gsub!('itemscope itemtype="http://schema.org/Person"', '')
    #     authors&.gsub!('<td>', '')
    #     authors&.gsub!('</td>', '')
    #     authors&.gsub!('<tr>', '')
    #     authors&.gsub!('</tr>', '')
    #     authors&.gsub!(/<th.*?>(.+?)<\/th>/, '')
    #     authors&.gsub!(/<ul.*?>(.+?)<\/ul>/, '\1')
    #     authors&.gsub!(/<li.*?>(.+?)<\/li>/, '\1|  ')
    #     authors&.gsub!(/<span.*?>(.+?)<\/span>/, '\1')
    #     authors = authors.reverse.sub('|', '').sub('|', ' dna ').reverse.gsub!('|', ';')
    #   end
    #   "<span class=\"moreauthor\">#{authors}</span>"
    # end

  end

end
