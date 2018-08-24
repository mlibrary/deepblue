# frozen_string_literal: true

namespace :deepblue do

  desc 'List works and their files with mismatching solr documents'
  task works_with_mismatching_solr_docs: :environment do
    WorksWithMismatchingSolrDocs.new.run
  end

end

module Deepblue

  class WorksWithMismatchingSolrDocs

    attr_accessor :logger, :keys_to_skip, :pacifier, :report, :report_missing_files, :report_files_mismatching_solr_docs,
                  :report_mismatching_files,
                  :report_missing_other, :test_work_files_for_mismatching_solr_docs, :verbose

    attr_reader :collections_mismatching_solr_docs,
                :works_mismatching_solr_docs,
                :files_mismatching_solr_docs,
                :to_solr_failed,
                :work_to_files_mismatching_solr_docs_map

    def initialize
      @keys_to_skip = { "file_format_tesim" => true,
                        "system_modified_dtsi" => true }

      @collections_mismatching_solr_docs = []
      @works_mismatching_solr_docs = []
      @files_mismatching_solr_docs = []
      @to_solr_failed = []
      @work_to_files_mismatching_solr_docs_map = {}
      @test_work_files_for_mismatching_solr_docs = true
      @report_mismatching_files = false
      @verbose = false
      @report = true
    end

    def run
      @pacifier ||= TaskPacifier.new
      @logger ||= TaskLogger.new(STDOUT).tap { |logger| logger.level = Logger::INFO; Rails.logger = logger } # rubocop:disable Style/Semicolon
      @logger.info
      GenericWork.all.each do |w|
        print "#{w.id} ... " if @verbose
        check_work_solr_docs( w )
        # report_work_with_files_mismatching_solr_docs( work_id: w.id )
      end
      # Collection.all.each do |w|
      #   print "#{w.id} ... " if @verbose
      #   #@logger.info JSON.pretty_generate doc.as_json
      #   check_collection_solr_doc( w )
      # end
      return unless @report
      @logger.info "done"
      # report collections missing edit users
      # @logger.info "collections_mismatching_solr_docs.count #{@collections_mismatching_solr_docs.count}"
      # @logger.info "collections_mismatching_solr_docs=#{@collections_mismatching_solr_docs}"
      # report works missing edit users
      @logger.info "works_mismatching_solr_docs.count #{@works_mismatching_solr_docs.count}"
      @logger.info "works_mismatching_solr_docs=#{@works_mismatching_solr_docs}"
      # file ids missing edit users
      @logger.info "files_mismatching_solr_docs.count #{@files_mismatching_solr_docs.count}"
      @logger.info "files_mismatching_solr_docs=#{@files_mismatching_solr_docs}" if @report_mismatching_files
      # file ids missing edit users
      @logger.info "to_solr_failed.count #{@to_solr_failed.count}"
      @logger.info "to_solr_failed=#{@to_solr_failed}"
      return unless @report_files_mismatching_solr_docs
      @work_to_files_mismatching_solr_docs_map.each do |key, value|
        report_work_with_files_mismatching_solr_docs( work_id: key, files_ids_with_mismatching_solr_docs: value )
      end
    end

    def check_collection_solr_doc( c )
      record_collection_solr_docs( c.id, c.depositor, c.edit_users )
    end

    def check_work_solr_docs( w )
      record_work_solr_docs( w )
      return unless @test_work_files_for_mismatching_solr_docs
      w.file_set_ids.each { |fid| check_file_set_solr_docs( w, fid ) }
    end

    def check_file_set_solr_docs( w, fid )
      fs = FileSet.find fid
      record_file_set_solr_docs( w, fs )
    end

    def compare_solr_for_mismatch( o )
      to_solr_hash = nil
      begin
        to_solr_hash = o.to_solr
      rescue Exception => e # rubocop:disable Lint/RescueException, Lint/UselessAssignment
        @to_solr_failed << o.id
        return true
      end
      solr_doc = SolrDocument.find o.id
      solr_hash = solr_doc._source
      # compare hashes, ignore mis-matching keys
      keys_processed = {}
      mismatch_count = compare_hashes( to_solr_hash, solr_hash, keys_processed )
      # mismatch_count += compare_hashes( solr_hash, to_solr_hash, keys_processed )
      mismatch_count.positive?
    end

    def compare_hashes( hash1, hash2, keys_processed )
      mismatch_count = 0
      hash1.each do |key, value|
        if keys_processed.key? key
          # skip processed key
        elsif @keys_to_skip.key? key
          puts "skipping #{key}" if @verbose
        elsif hash2.key? key
          value2 = hash2[key]
          if value2 == value
            puts "matching key #{key} : '#{value}' == '#{value2}'" if @verbose
          elsif compare_retry( key, value, value2 )
            puts "retry matching key #{key} : '#{value}' == '#{value2}'" if @verbose
          else
            puts "mismatch key #{key} : '#{value}' != '#{value2}'" if @verbose
            mismatch_count += 1
          end
          # elsif !value.nil?
          # puts "mismatch non-nil key #{key} missing on other side" #if @verbose
          # mismatch_count += 1
        elsif @verbose
          puts "skipping key #{key} : '#{value}'"
          # puts "skipping key #{key} with nil value"
        end
        keys_processed[key] = true
      end
      return mismatch_count
    end

    def compare_retry( key, value, value2 )
      puts "retry #{key} : '#{value}' == '#{value2}'" if @verbose
      puts "retry #{key} : '#{value.class}' == '#{value2.class}'" if @verbose
      if "ActiveTriples::Relation" == value.class.to_s && 1 == value.count
        value = value.first
      end
      if "ActiveTriples::Relation" == value2.class.to_s && 1 == value2.count
        value2 = value2.first
      end
      if value.class == value2.class && "Array" == value.class.to_s
        return false unless value.count == value2.count
        return value.sort == value2.sort
      end
      if "Array" != value.class.to_s && "Array" == value2.class.to_s && 1 == value2.count
        rv = value.to_s == value2[0].to_s
        return rv
      end
      if "Array" != value2.class.to_s && "Array" == value.class.to_s && 1 == value.count
        rv = value[0].to_s == value2.to_s
        return rv
      end
      if "String" == value.class.to_s && "String" != value2.class.to_s
        rv = value == value2.to_s
        return rv
      end
      if "String" == value2.class.to_s && "String" != value.class.to_s
        rv = value.to_s == value2
        return rv
      end
      return false
    end

    def record_collection_solr_docs( w )
      @collections_mismatching_solr_docs << id if compare_solr_for_mismatch w
    end

    def record_file_set_solr_docs( w, fs )
      return unless compare_solr_for_mismatch fs
      @files_mismatching_solr_docs << fs.id
      record_to_files_mismatching_solr_docs( w.id, fs.id )
    end

    def record_to_files_mismatching_solr_docs( wid, fid )
      @work_to_files_mismatching_solr_docs_map[wid] = [] unless @work_to_files_mismatching_solr_docs_map.key? wid
      @work_to_files_mismatching_solr_docs_map[wid] << fid
    end

    def record_work_solr_docs( w )
      @works_mismatching_solr_docs << w.id if compare_solr_for_mismatch w
    end

    def report_work_with_files_mismatching_solr_docs( work_id: nil, files_ids_with_mismatching_solr_docs: [] )
      w = GenericWork.find work_id
      @logger.info "work: #{work_id} #{w.title.join( ',' )}"
      @logger.info "work: #{work_id} #{w.visibility}"
      @logger.info "work: #{work_id} #{w.depositor}"
      @logger.info "work: #{work_id} has #{files_ids_with_mismatching_solr_docs.count} files with mismatching solr docs"
      @logger.info "work: #{work_id} file ids: #{files_ids_with_mismatching_solr_docs}" if @verbose
    end

  end

end
