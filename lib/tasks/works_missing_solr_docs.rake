# frozen_string_literal: true

namespace :deepblue do

  desc 'List works missing solr docs'
  task works_missing_solr_docs: :environment do
    Deepblue::WorksMissingSolrdocs.new.run
  end

end

module Deepblue

  require 'tasks/missing_solr_docs'

  class WorksMissingSolrdocs < MissingSolrdocs

    def run
      @collections_missing_solr_docs = []
      @files_missing_solr_docs = []
      @works_missing_solr_docs = []
      @other_missing_solr_docs = []
      @report_missing_files = false
      @report_missing_other = false
      @user_pacifier = false
      @verbose = false
      @pacifier = TaskPacifier.new
      @logger = TaskLogger.new(STDOUT).tap { |logger| logger.level = Logger::INFO; Rails.logger = logger } # rubocop:disable Style/Semicolon
      count = 0
      descendants = descendant_uris( ActiveFedora.fedora.base_uri,
                                     exclude_uri: true,
                                     pacifier: @pacifier,
                                     logger: @logger )
      puts
      descendants.each do |uri|
        @logger.info "#{uri} ... " if @verbose
        id = uri_to_id( uri )
        @logger.info id.to_s if @verbose
        next unless filter_in( uri, id )
        doc = solr_doc( uri, id )
        hydra_model = hydra_model doc
        # @logger.info "'#{hydra_model}'"
        # @logger.info JSON.pretty_generate doc.as_json
        @logger.info "generic_work? #{generic_work?( uri, id )}" if @verbose
        @logger.info "file_set? #{file_set?( uri, id )}" if @verbose
        if doc.nil?
          if generic_work?( uri, id )
            @works_missing_solr_docs << id
          elsif file_set?( uri, id )
            @files_missing_solr_docs << id
          elsif collection?( uri, id )
            @collections_missing_solr_docs << id
          else
            @other_missing_solr_docs << id
          end
        elsif hydra_model == "GenericWork"
          count += 1
          @logger.info "#{id}...good work" if @verbose
        elsif hydra_model == "FileSet"
          # skip
        elsif hydra_model == "Collection"
          @logger.info "#{id}...good collection" if @verbose
        else
          @logger.info "skipped '#{hydra_model}'"
          # skip
        end
      end
      @logger.info "done"
      @logger.info "count=#{count}"
      @logger.info "collections_missing_solr_docs.count #{@collections_missing_solr_docs.count}"
      @logger.info "collections_missing_solr_docs=#{@collections_missing_solr_docs}"
      @logger.info "works_missing_solr_docs.count #{@works_missing_solr_docs.count}"
      @logger.info "works_missing_solr_docs=#{@works_missing_solr_docs}"
      @logger.info "files_missing_solr_docs.count #{@files_missing_solr_docs.count}"
      @logger.info "files_missing_solr_docs=#{@files_missing_solr_docs}" if @report_missing_files
      @logger.info "other_missing_solr_docs.count #{@other_missing_solr_docs.count}"
      @logger.info "other_missing_solr_docs=#{@other_missing_solr_docs.count}" if @report_missing_other
    end

  end

end
