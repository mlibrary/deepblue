# frozen_string_literal: true

require_relative './active_fedora_indexing_descendent_fetcher2'

# rubocop:disable Style/SafeNavigation Style/Semicolon
module ActiveFedora

  module Indexing
    # extend ActiveSupport::Concern
    # extend ActiveSupport::Autoload

    module ClassMethods

      attr_accessor :debug_verbose, :job_msg_queue, :logger, :pacifier

      # @param [Integer] batch_size - The number of Fedora objects to process for each SolrService.add call. Default 50.
      # @param [Boolean] softCommit - Do we perform a softCommit when we add the to_solr objects to SolrService. Default true.
      # @param [Boolean] progress_bar - If true output progress bar information. Default false.
      # @param [Boolean] final_commit - If true perform a hard commit to the Solr service at the completion of the batch of updates. Default false.
      def reindex_everything2( batch_size: 50,
                               softCommit: true,
                               progress_bar: false,
                               final_commit: false,
                               pacifier: nil,
                               logger: nil,
                               job_msg_queue: nil,
                               debug_verbose: false )

        @debug_verbose = debug_verbose
        @job_msg_queue = job_msg_queue
        @logger = logger
        @pacifier = pacifier

        # skip root url
        descendants = descendant_uris2( ActiveFedora.fedora.base_uri, exclude_uri: true )

        batch = []
        batch_uri = []

        if progress_bar
          progress_bar_controller = ProgressBar.create( total: descendants.count,
                                                        format: "%t: |%B| %p%% %e" )
        end

        descendants.each do |uri|
          logger.debug "Re-index everything ... #{uri}"
          # pacify '.'

          # catch errors
          begin
            id = ::PersistHelper.uri_to_id(uri)
            obj = ::PersistHelper.find(id)
            batch << obj.to_solr
            batch_uri << uri
          rescue Exception => e # rubocop:disable Lint/RescueException
            pacify '<!b>'
            error "#{uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
          end

          if (batch.count % batch_size).zero?
            batch_save2( batch, batch_uri, softCommit, pacifier, logger )
            batch.clear
            batch_uri.clear
          end

          progress_bar_controller.increment if progress_bar_controller
        end

        if batch.present?
          batch_save2( batch, batch_uri, softCommit, pacifier, logger )
          batch.clear
          batch_uri.clear
        end

        if final_commit
          begin
            pacify 'c'
            debug "Solr hard commit..."
            SolrService.commit
          rescue Exception => e # rubocop:disable Lint/RescueException
            pacify '<!c>'
            error "#{e.class}: #{e.message} at #{e.backtrace[0]}"
          end
        end
        logger.info "\nRe-index everything complete." unless logger.nil?
      end

      def descendant_uris2( uri, exclude_uri: false )
        DescendantFetcher2.new( uri,
                                exclude_self: exclude_uri,
                                pacifier: pacifier,
                                logger: logger,
                                job_msg_queue: job_msg_queue,
                                debug_verbose: false ).descendant_and_self_uris
      end

      def batch_save2( batch, batch_uri, soft_commit, pacifier, logger, recurse_on_error: true )
        pacify 's'
        SolrService.add(batch, softCommit: soft_commit)
      rescue Exception => e # rubocop:disable Lint/RescueException
        pacify '<!s>'
        if recurse_on_error
          error "#{e.class}: #{e.message} at #{e.backtrace[0]}"
        else
          error "#{batch_uri[0]} #{e.class}: #{e.message} at #{e.backtrace[0]}"
        end
        if recurse_on_error
          pacify '('
          i = 0
          batch.each do |b|
            batch_save2( [b], [batch_uri[i]], soft_commit, pacifier, logger, recurse_on_error: false )
            i += 1
          end
          pacify ')'
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

    end

  end
end
# rubocop:enable Style/SafeNavigation Style/Semicolon
