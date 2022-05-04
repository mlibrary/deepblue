
module Hyrax

  module My

    class WorksController < MyController

      mattr_accessor :hyrax_my_works_controller_debug_verbose, default: false

      # Define collection specific filter facets.
      def self.configure_facets
        configure_blacklight do |config|
          config.search_builder_class = Hyrax::My::WorksSearchBuilder
          config.add_facet_field "admin_set_sim", limit: 5
          config.add_facet_field "member_of_collections_ssim", limit: 5
        end
      end
      configure_facets

      class_attribute :create_work_presenter_class
      self.create_work_presenter_class = ::Deepblue::SelectTypeListPresenter

      # # Search builder for a list of works that belong to me
      # # Override of Blacklight::RequestBuilders
      # def search_builder_class
      #   Hyrax::My::WorksSearchBuilder
      # end

      def analytics_subscribe
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if hyrax_my_works_controller_debug_verbose
        ::AnalyticsHelper.monthly_analytics_report_subscribe( user: current_ability.current_user )
        redirect_to hyrax.my_works_path
      end

      def analytics_unsubscribe
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if hyrax_my_works_controller_debug_verbose
        ::AnalyticsHelper.monthly_analytics_report_unsubscribe( user: current_ability.current_user )
        redirect_to hyrax.my_works_path
      end

      def index
        # The user's collections for the "add to collection" form
        @user_collections = collections_service.search_results(:deposit)

        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.works'), hyrax.my_works_path
        managed_works_count
        @create_work_presenter = create_work_presenter_class.new(current_user)
        super
      end

      private

      def collections_service
        Hyrax::CollectionsService.new(self)
      end

      def search_action_url(*args)
        hyrax.my_works_url(*args)
      end

      # The url of the "more" link for additional facet values
      def search_facet_path(args = {})
        hyrax.my_dashboard_works_facet_path(args[:id])
      end

      def managed_works_count
        @managed_works_count = Hyrax::Works::ManagedWorksService.managed_works_count(scope: self)
      end

    end

  end

end
