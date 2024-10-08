# frozen_string_literal: true
# Added: hyrax4
# monkey - copied up from blacklight gem because the blacklight helpers were not being found

module Blacklight
  # These are methods that are used at both the view helper and controller layers
  # They are only dependent on `blacklight_config` and `@response`
  #
  module Facet
    # extend Deprecation
    # delegate :facet_configuration_for_field, :facet_field_names, to: :blacklight_config

    def facet_configuration_for_field(field)
      # puts "facet_configuration_for_field #{field}"
      blacklight_config.facet_configuration_for_field(field)
    end

    def facet_field_names(groupname)
      # puts "facet_field_names #{groupname}"
      blacklight_config.facet_field_names(groupname)
    end

    # @     deprecated
    # @param [Blacklight::Configuration::Facet] field_config
    # @param [Object] response_data
    # @return [Blacklight::FacetPaginator]
    def facet_paginator(field_config, response_data)
      blacklight_config.facet_paginator_class.new(
        response_data.items,
        sort: response_data.sort,
        offset: response_data.offset,
        prefix: response_data.prefix,
        # limit: Deprecation.silence(Blacklight::Catalog) { facet_limit_for(field_config.key) }
        limit: facet_limit_for(field_config.key)
      )
    end
    # deprecation_deprecate facet_paginator: 'Use Blacklight::FacetFieldPresenter#paginator instead'

    def facet_paginator2(field_config, response_data)
      blacklight_config.facet_paginator_class.new(
        response_data.items,
        sort: response_data.sort,
        offset: response_data.offset,
        prefix: response_data.prefix,
        # limit: Deprecation.silence(Blacklight::Catalog) { facet_limit_for(field_config.key) }
        limit: facet_limit_for(field_config.key)
      )
    end

    # @param fields [Array<String>] a list of facet field names
    # @return [Array<Solr::Response::Facets::FacetField>]
    # @    deprecated
    def facets_from_request(fields = facet_field_names(nil), response = nil)
      # puts "facets_from_request"
      unless response
        # Deprecation.warn(self, 'Calling facets_from_request without passing the ' \
        #   'second argument (response) is deprecated and will be removed in Blacklight ' \
        #   '8.0.0')
        response = @response
      end

      begin # Deprecation.silence(Blacklight::Facet) do
        # puts "fields.map"
        fields.map { |field| facet_by_field_name(field, response) }.compact
      end
    end
    # deprecation_deprecate facets_from_request: 'Removed without replacement'

    def facets_from_request2(fields = facet_field_names(nil), response = nil)
      # puts "facets_from_request2"
      unless response
        # Deprecation.warn(self, 'Calling facets_from_request without passing the ' \
        #   'second argument (response) is deprecated and will be removed in Blacklight ' \
        #   '8.0.0')
        response = @response
      end

      begin # Deprecation.silence(Blacklight::Facet) do
        # puts "fields.map"
        fields.map do |field|
          # puts "field: #{field}"
          facet_by_field_name2(field, response)
        end.compact
      end
    end

    #delegate :facet_group_names, to: :blacklight_config
    # deprecation_deprecate facet_group_names: 'Use blacklight_config.facet_group_names instead'

    def facet_group_names
      blacklight_config.facet_group_names
    end

    # Get a FacetField object from the @response
    # @   deprecated
    # @private
    # @return [Blacklight::Solr::Response::Facets::FacetField]
    def facet_by_field_name(field_or_field_name, response = nil)
      unless response
        # Deprecation.warn(self, 'Calling facet_by_field_name without passing the ' \
        #   'second argument (response) is deprecated and will be removed in Blacklight ' \
        #   '8.0.0')
        response = @response
      end
      case field_or_field_name
      when String, Symbol
        facet_field = facet_configuration_for_field(field_or_field_name)
        response.aggregations[facet_field.field]
      when Blacklight::Configuration::FacetField
        response.aggregations[field_or_field_name.field]
      else
        # is this really a useful case?
        field_or_field_name
      end
    end
    # deprecation_deprecate facet_by_field_name: 'Removed without replacement'

    def facet_by_field_name2(field_or_field_name, response = nil)
      # puts "facet_by_field_name2 #{field_or_field_name}"
      # return field_or_field_name
      unless response
        response = @response
      end
      case field_or_field_name
      when String, Symbol
        facet_field = facet_configuration_for_field(field_or_field_name)
        response.aggregations[facet_field.field]
      when Blacklight::Configuration::FacetField
        response.aggregations[field_or_field_name.field]
      else
        # is this really a useful case?
        field_or_field_name
      end
    end

  end

end
