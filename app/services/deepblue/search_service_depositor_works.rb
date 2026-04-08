
require_relative '../../search_builders/hyrax/depositor_works_search_builder'

module Deepblue
    module SearchServiceDepositorWorks

      mattr_accessor :search_service_managed_works_debug_verbose, default: false

      def self.depositor_works_count(scope:)
        if scope.nil?
          # report error?
          return 0
        end
        if scope.repository.nil?
          # report error?
          return 0
        end
        query_builder = ::Hyrax::DepositorWorksSearchBuilder.new(scope).rows(0)
        scope.repository.search(query_builder.query).response["numFound"]
      end

      def self.depositor_works_list(scope:)
        if scope.nil?
          # report error?
          return []
        end
        if scope.repository.nil?
          # report error?
          return []
        end
        query_builder = ::Hyrax::DepositorWorksSearchBuilder.new(scope).rows(100)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "query_builder=#{query_builder}",
                                               "" ] if search_service_managed_works_debug_verbose
        if query_builder.nil?
          # report error?
          return []
        end
        # scope.repository.search(query_builder.query).documents
        rv = scope.repository.search(query_builder.query)
        if rv.nil?
          # report error?
          return []
        end
        rv.documents
      end

    end

end
