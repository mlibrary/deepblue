# frozen_string_literal: true
# Reviewed: heliotrope

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters

  mattr_accessor :search_builder_debug_verbose, default: false

  def initialize(*options)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if search_builder_debug_verbose
    super
  end

  ## BEGIN: v4 upgrade - copied from heliotrope ##
  def sort
    sort_field = if blacklight_params[:sort].blank?
                   # no sort param provided, use default
                   default_sort_field
                 else
                   # check for sort field key
                   blacklight_config.sort_fields[blacklight_params[:sort]]
                 end

    field = if sort_field.present?
              sort_field.sort
            else
              # just pass the key through
              blacklight_params[:sort]
            end

    field.presence
  end

  def default_sort_field # rubocop:disable Rails/Delegate
    blacklight_config.default_sort_field
  end
  ## END: v4 upgrade - copied from heliotrope ##

end
