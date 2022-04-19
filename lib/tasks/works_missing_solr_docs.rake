# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:works_missing_solr_docs
  desc 'List works missing solr docs'
  task :works_missing_solr_docs, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::WorksMissingSolrdocs.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/missing_solr_docs'

  class WorksMissingSolrdocs < MissingSolrdocs

    DEFAULT_REPORT_MISSING_FILES = false unless const_defined? :DEFAULT_REPORT_MISSING_FILES
    DEFAULT_REPORT_MISSING_OTHER = false unless const_defined? :DEFAULT_REPORT_MISSING_OTHER
    DEFAULT_USER_PACIFIER = false unless const_defined? :DEFAULT_USER_PACIFIER

    attr_accessor :report_missing_files, :report_missing_other, :user_pacifier

    attr_reader :collections_missing_solr_docs,
                :files_missing_solr_docs,
                :works_missing_solr_docs,
                :other_missing_solr_docs,
                :pacifier,
                :logger

    def initialize( options: )
      super( options: options )
      @report_missing_files = TaskHelper.task_options_value( @options,
                                                             key: 'report_missing_files',
                                                             default_value: DEFAULT_REPORT_MISSING_FILES )
      @report_missing_other = TaskHelper.task_options_value( @options,
                                                             key: 'report_missing_other',
                                                             default_value: DEFAULT_REPORT_MISSING_OTHER )
      @user_pacifier = TaskHelper.task_options_value( @options,
                                                      key: 'user_pacifier',
                                                      default_value: DEFAULT_USER_PACIFIER )
    end

    def run
      @collections_missing_solr_docs = []
      @files_missing_solr_docs = []
      @works_missing_solr_docs = []
      @other_missing_solr_docs = []
      @pacifier = TaskPacifier.new
      @logger = TaskHelper.logger_new
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
        @logger.info "work? #{work?( uri, id )}" if @verbose
        @logger.info "file_set? #{file_set?( uri, id )}" if @verbose
        if doc.nil?
          if work?( uri, id )
            @works_missing_solr_docs << id
          elsif file_set?( uri, id )
            @files_missing_solr_docs << id
          elsif collection?( uri, id )
            @collections_missing_solr_docs << id
          else
            @other_missing_solr_docs << id
          end
        elsif TaskHelper.hydra_model_work?( hydra_model: hydra_model )
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
