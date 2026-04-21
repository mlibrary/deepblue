# frozen_string_literal: true
# Reviewed: hyrax4
# monkey override definition
module Hyrax
  module Dashboard
    ## Shows a list of all works to the admins
    class WorksController < Hyrax::My::WorksController
      before_action :_debug_verbose
      def _debug_verbose()
        #::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from, "" ]
      end
      # Define collection specific filter facets.
      configure_blacklight do |config|
        config.search_builder_class = Hyrax::Dashboard::WorksSearchBuilder
      end

      private

      def search_action_url(*args)
        hyrax.dashboard_works_url(*args)
      end

      # The url of the "more" link for additional facet values
      def search_facet_path(args = {})
        hyrax.dashboard_works_facet_path(args[:id])
      end
    end
  end
end
