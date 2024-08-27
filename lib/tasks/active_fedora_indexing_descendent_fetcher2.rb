# frozen_string_literal: true

# see: https://gist.github.com/cjcolvar/8f0485e3cf88307228447726b6b55dd3

# rubocop:disable Style/SafeNavigation Style/Semicolon
ActiveFedora::Fedora.class_eval do

  def request_options
    @config[:request]
  end

  def ntriples_connection
    authorized_connection.tap { |conn| conn.headers['Accept'] = 'application/n-triples' }
  end

  def build_ntriples_connection
    ActiveFedora::InitializingConnection.new(ActiveFedora::CachingConnection.new(ntriples_connection, omit_ldpr_interaction_model: true), root_resource_path)
  end

  def authorized_connection2
    STDOUT.puts "authorized_connection"; STDOUT.flush # rubocop:disable Style/Semicolon
    options = {}
    options[:ssl] = ssl_options if ssl_options
    options[:request] = request_options if request_options
    Faraday.new(host, options) do |conn|
      conn.response :encoding # use Faraday::Encoding middleware
      conn.adapter Faraday.default_adapter # net/http
      # conn.basic_auth(user, password)
      if Gem::Version.new(Faraday::VERSION) < Gem::Version.new('2')
        conn.request :basic_auth, user, password
      else
        conn.request :authorization, :basic, user, password
      end
    end
  end

end

module ActiveFedora
  module Indexing
    # Finds all descendent URIs of a given repo URI (usually the base URI).
    #
    # This is a slow and non-performant thing to do, we need to fetch every single
    # object from the repo.
    #
    # The DescendantFetcher is also capable of partitioning the URIs into "priority" URIs
    # that will be first in the returned list. These prioritized URIs belong to objects
    # with certain hasModel models. This feature is used in some hydra apps that need to
    # index 'permissions' objects before other objects to have the solr indexing work right.
    # And so by default, the prioritized class names are the ones form Hydra::AccessControls,
    # but you can alter the prioritized model name list, or set it to the empty array.
    #
    #     DescendantFetcher.new(ActiveFedora.fedora.base_uri).descendent_and_self_uris
    #     #=> array including self uri and descendent uris with "prioritized" (by default)
    #         Hydra::AccessControls permissions) objects FIRST.
    #
    # Change the default prioritized hasModel names:
    #
    #     ActiveFedora::Indexing::DescendantFetcher.default_priority_models = []
    class DescendantFetcher2
      HAS_MODEL_PREDICATE = ActiveFedora::RDF::Fcrepo::Model.hasModel

      class_attribute :default_priority_models, instance_accessor: false
      self.default_priority_models = %w[Hydra::AccessControl Hydra::AccessControl::Permissions].freeze

      attr_reader :uri, :priority_models

      attr_accessor :debug_verbose, :job_msg_queue, :logger, :pacifier

      def initialize(uri,
                     priority_models: self.class.default_priority_models,
                     exclude_self: false,
                     pacifier: nil,
                     logger: nil,
                     job_msg_queue: nil,
                     depth: 0,
                     debug_verbose: false )

        @debug_verbose = debug_verbose
        @uri = uri
        @priority_models = priority_models
        @exclude_self = exclude_self
        @pacifier = pacifier
        @pacifier_verbose = nil # set this to @pacifier for a more verbose pacifier
        @depth = depth
        @logger = logger
        @job_msg_queue = job_msg_queue
      end

      def descendant_and_self_uris
        partitioned = descendant_and_self_uris_partitioned
        pacify_verbose "[#{partitioned[:priority].count},#{partitioned[:other].count}]"
        partitioned[:priority] + partitioned[:other]
      end

      # returns a hash where key :priority is an array of all prioritized
      # type objects, key :other is an array of the rest.
      def descendant_and_self_uris_partitioned
        pacify '.' if 1 >= @depth
        pacify_verbose '('
        resource = Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
        # GET could be slow if it's a big resource, we're using HEAD to avoid this problem,
        # but this causes more requests to Fedora.

        ### begin update
        is_rdf_source = false
        begin
          is_rdf_source = resource.head.rdf_source?
        rescue Exception => e # rubocop:disable Lint/RescueException
          # TODO: collect and report on these errors
          pacify '!'
          error "#{uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
        end
        return partitioned_uris unless is_rdf_source
        ### end update

        add_self_to_partitioned_uris unless @exclude_self

        immediate_descendant_uris = rdf_graph.query(predicate: ::RDF::Vocab::LDP.contains).map do |descendant|
          descendant.object.to_s
        end
        immediate_descendant_uris.each do |descendant_uri|
          # pacify '.'
          self.class.new(
            descendant_uri,
            priority_models: priority_models,
            pacifier: @pacifier,
            logger: @logger,
            depth: @depth + 1
          ).descendant_and_self_uris_partitioned.tap do |descendant_partitioned|
            pacify_verbose "[#{descendant_partitioned[:priority].count},#{descendant_partitioned[:other].count}]"
            partitioned_uris[:priority].concat descendant_partitioned[:priority]
            partitioned_uris[:other].concat descendant_partitioned[:other]
          end
        end
        @pacifier_verbose.pacify ')' unless @pacifier_verbose.nil?
        partitioned_uris
      end

      protected

        def rdf_resource
          # @rdf_resource ||= Ldp::Resource::RdfSource.new(ActiveFedora.fedora.connection, uri)
          # see: https://gist.github.com/cjcolvar/8f0485e3cf88307228447726b6b55dd3
          @rdf_resource ||= Ldp::Resource::RdfSource.new(ActiveFedora.fedora.build_ntriples_connection, uri)
        end

        def rdf_graph
          @rdf_graph ||= rdf_resource.graph
        end

        def partitioned_uris
          @partitioned_uris ||= {
            priority: [],
            other: []
          }
        end

        def rdf_graph_models
          rdf_graph.query(predicate: HAS_MODEL_PREDICATE).collect(&:object).collect do |rdf_object|
            rdf_object.to_s if rdf_object.literal?
          end.compact
        end

        def prioritized_object?
          priority_models.present? && (rdf_graph_models & priority_models).count.positive?
        end

        def add_self_to_partitioned_uris
          if prioritized_object?
            partitioned_uris[:priority] << rdf_resource.subject
          else
            partitioned_uris[:other] << rdf_resource.subject
          end
        end

        def debug( msg )
          return unless debug_verbose
          @logger.debug msg unless @logger.nil?
          @job_msg_queue << msg unless @job_msg_queue.nil?
        end

        def error( msg )
          @logger.error msg unless @logger.nil?
          @job_msg_queue << msg unless @job_msg_queue.nil?
        end

        def info( msg )
          @logger.info msg unless @logger.nil?
          @job_msg_queue << msg unless @job_msg_queue.nil?
        end

        def pacify( msg )
          return if @pacifier.nil?
          @pacifier.pacify msg
        end

        def pacify_verbose( msg )
          return if @pacifier_verbose.nil?
          @pacifier_verbose.pacify msg
        end

    end
  end
end
# rubocop:enable Style/SafeNavigation Style/Semicolon
