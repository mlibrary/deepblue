# frozen_string_literal: true

module Deepblue

  require 'tasks/active_fedora_indexing_descendent_fetcher2'
  require 'tasks/task_logger'

  class MissingSolrdocs

    def descendant_uris( uri, exclude_uri: false, pacifier: nil, logger: nil )
      ActiveFedora::Indexing::DescendantFetcher2.new( uri,
                                                      exclude_self: exclude_uri,
                                                      pacifier: pacifier,
                                                      logger: logger ).descendant_and_self_uris
    end

    def collection?( _uri, id )
      rv = false
      begin
        c = Collection.find id
        rv = true unless c.nil?
      rescue Exception => ignore # rubocop:disable Lint/RescueException, Lint/HandleExceptions, Lint/UselessAssignment
      end
      return rv
    end

    def collection_or_nil( _uri, id )
      rv = nil
      begin
        rv = Collection.find id
      rescue Exception => ignore # rubocop:disable Lint/RescueException, Lint/HandleExceptions, Lint/UselessAssignment
      end
      return rv
    end

    def filter_in( _uri, id )
      return false if id.include? '-'
      return false if id.include? '/'
      return false if id.include? 'admin_set'
      return true
    end

    def file_set?( _uri, id )
      rv = false
      begin
        fs = FileSet.find id
        rv = true unless fs.nil?
      rescue Exception => ignore # rubocop:disable Lint/RescueException, Lint/HandleExceptions, Lint/UselessAssignment
      end
      return rv
    end

    def file_set_or_nil( _uri, id )
      rv = nil
      begin
        rv = FileSet.find id
      rescue Exception => ignore # rubocop:disable Lint/RescueException, Lint/HandleExceptions, Lint/UselessAssignment
      end
      return rv
    end

    def find_missing_files_for_work( _uri, id )
      missing_files = []
      w = GenericWork.find id
      w.file_set_ids.each do |fs|
        doc = solr_doc_from_id( fs.id )
        missing_files << fs.id if doc.nil?
      end
      return missing_files
    end

    def generic_work?( _uri, id )
      rv = false
      begin
        w = GenericWork.find id
        rv = true unless w.nil?
      rescue Exception => ignore # rubocop:disable Lint/RescueException, Lint/HandleExceptions, Lint/UselessAssignment
      end
      return rv
    end

    def generic_work_or_nil( _uri, id )
      rv = nil
      begin
        rv = GenericWork.find id
      rescue Exception => ignore # rubocop:disable Lint/RescueException, Lint/HandleExceptions, Lint/UselessAssignment
      end
      return rv
    end

    def hydra_model( doc )
      return '' if doc.nil?
      return doc.hydra_model.to_s
    end

    def logger
      @logger ||= logger_initialize
    end

    def logger_initialize
      # TODO: add some flags to the input yml file for log level and Rails logging integration
      Umrdr::TaskLogger.new(STDOUT).tap { |logger| logger.level = Logger::INFO; Rails.logger = logger } # rubocop:disable Style/Semicolon
    end

    def solr_doc( _uri, id )
      return solr_doc_from_id( id )
    end

    def solr_doc_from_id( id )
      doc = nil
      begin
        doc = SolrDocument.find id
      rescue Blacklight::Exceptions::RecordNotFound => e2 # rubocop:disable Lint/HandleExceptions, Lint/UselessAssignment
        # puts "e2 #{e2.class}: #{e2.message}"
      rescue Exception => e # rubocop:disable Lint/RescueException
        puts "e #{e.class}: #{e.message} at #{e.backtrace[0]}" # rubocop:disable Rails/Output
      end
      return doc
    end

    def solr_doc_from_uri( uri )
      id = uri_to_id( uri )
      return solr_doc_from_id( id )
    end

    def uri_to_id( uri )
      ActiveFedora::Base.uri_to_id(uri)
    end

  end

end
