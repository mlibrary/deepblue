# frozen_string_literal: true

namespace :deepblue do

  desc 'List works and their files missing solr docs'
  task works_and_files_missing_solr_docs: :environment do
    Deepblue::WorksAndFilesMissingSolrdocs.new.run
  end

end

module Deepblue

  require 'tasks/missing_solr_docs'
  require 'tasks/task_logger'
  require 'tasks/task_pacifier'

  class WorksAndFilesMissingSolrdocs < MissingSolrdocs

    ## TODO
    def run
      @collections_missing_solr_docs = []
      @works_missing_solr_docs = []
      @work_id_to_missing_files_map = {}
      @orphan_file_ids = {}
      @works_missing_file_ids = {}
      @files_missing_solr_docs = []
      @other_missing_solr_docs = []
      @report_missing_files = false
      @report_missing_other = false
      @user_pacifier = false
      @verbose = false
      count = 0
      @pacifier = TaskPacifier.new
      @logger = TaskLogger.new(STDOUT).tap { |logger| logger.level = Logger::INFO; Rails.logger = logger } # rubocop:disable Style/Semicolon
      descendants = descendant_uris( ActiveFedora.fedora.base_uri,
                                     exclude_uri: true,
                                     pacifier: @pacifier,
                                     logger: @logger )
      @logger.info
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
            missing_files = find_missing_files_for_work( uri, id )
            @work_id_to_missing_files_map[id] = missing_files unless missing_files.empty?
            missing_files.each { |fid| @works_missing_file_ids[fid] = true }
          elsif file_set?( uri, id )
            @files_missing_solr_docs << id
            @orphan_file_ids[id] = true
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
      @works_missing_file_ids.keys.each { |fid| @orphan_file_ids.remove fid }
      @logger.info "done"
      @logger.info "count=#{count}"
      # report missing collections
      @logger.info "collections_missing_solr_docs.count #{@collections_missing_solr_docs.count}"
      @logger.info "collections_missing_solr_docs=#{@collections_missing_solr_docs}"
      # report missing works
      @logger.info "works_missing_solr_docs.count #{@works_missing_solr_docs.count}"
      @logger.info "works_missing_solr_docs=#{@works_missing_solr_docs}"
      # report missing files
      @logger.info "@work_id_to_missing_files_map.count #{@work_id_to_missing_files_map.count}"
      @logger.info "@work_id_to_missing_files_map=#{@work_id_to_missing_files_map.keys}"
      @work_id_to_missing_files_map.each_pair do |key, value|
        @logger.info "work: #{key.id} has #{value.count} missing files"
        @logger.info "work: #{key.id} file ids: #{value}"
      end
      # orphans
      @logger.info "@orphan_file_ids.count #{@orphan_file_ids.count}"
      @logger.info "@orphan_file_ids=#{@orphan_file_ids.keys}"
      # file ids missing solr docs
      @logger.info "files_missing_solr_docs.count #{@files_missing_solr_docs.count}"
      @logger.info "files_missing_solr_docs=#{@files_missing_solr_docs}" if @report_missing_files
      # other
      @logger.info "other_missing_solr_docs.count #{@other_missing_solr_docs.count}"
      @logger.info "other_missing_solr_docs=#{@other_missing_solr_docs.count}" if @report_missing_other
    end

  end

end
