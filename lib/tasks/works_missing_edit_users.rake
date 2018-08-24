# frozen_string_literal: true

namespace :deepblue do

  desc 'List works and their files missing edit users'
  task works_missing_edit_users: :environment do
    WorksMissingEditUsers.new.run
  end

end

module Deepblue

  class WorksMissingEditUsers

    attr_accessor :logger, :pacifier, :report, :report_missing_files, :report_files_missing_edit_users,
                  :report_missing_other, :verbose

    attr_reader :collections_missing_edit_users, :collections_missing_depositor_edit_user,
                :works_missing_edit_users, :works_missing_depositor_edit_user,
                :files_missing_edit_users, :files_missing_depositor_edit_user,
                :work_to_files_missing_edit_users_map

    def initialize
      @collections_missing_edit_users = []
      @collections_missing_depositor_edit_user = []
      @works_missing_edit_users = []
      @works_missing_depositor_edit_user = []
      @files_missing_edit_users = []
      @files_missing_depositor_edit_user = []
      @work_to_files_missing_edit_users_map = {}
      @report_missing_files = false
      @report_missing_other = false
      @report_files_missing_edit_users = true
      @verbose = false
      @report = true
    end

    def run
      @pacifier ||= TaskPacifier.new
      @logger ||= TaskLogger.new(STDOUT).tap { |logger| logger.level = Logger::INFO; Rails.logger = logger } # rubocop:disable Style/Semicolon
      @logger.info
      GenericWork.all.each do |w|
        print "#{w.id} ... " if @verbose
        # @logger.info JSON.pretty_generate doc.as_json
        check_work_edit_users( w )
        # report_work_with_files_missing_edit_users( work_id: w.id )
      end
      Collection.all.each do |w|
        print "#{w.id} ... " if @verbose
        # @logger.info JSON.pretty_generate doc.as_json
        check_collection_edit_user( w )
      end
      return unless @report
      @logger.info "done"
      # report collections missing edit users
      @logger.info "collections_missing_edit_users.count #{@collections_missing_edit_users.count}"
      @logger.info "collections_missing_edit_users=#{@collections_missing_edit_users}"
      @logger.info "collections_missing_depositor_edit_user.count #{@collections_missing_depositor_edit_user.count}"
      @logger.info "collections_missing_depositor_edit_user=#{@collections_missing_depositor_edit_user}"
      # report works missing edit users
      @logger.info "works_missing_edit_users.count #{@works_missing_edit_users.count}"
      @logger.info "works_missing_edit_users=#{@works_missing_edit_users}"
      @logger.info "works_missing_depositor_edit_user.count #{@works_missing_depositor_edit_user.count}"
      @logger.info "works_missing_depositor_edit_user=#{@works_missing_depositor_edit_user}"
      # file ids missing edit users
      @logger.info "files_missing_edit_users.count #{@files_missing_edit_users.count}"
      @logger.info "files_missing_edit_users=#{@files_missing_edit_users}" if @report_missing_files
      @logger.info "files_missing_depositor_edit_user.count #{@files_missing_depositor_edit_user.count}"
      @logger.info "files_missing_depositor_edit_user=#{@files_missing_depositor_edit_user}" if @report_missing_files
      return unless @report_files_missing_edit_users
      @work_to_files_missing_edit_users_map.each do |key, value|
        report_work_with_files_missing_edit_users( work_id: key, files_ids_with_missing_edit_users: value )
      end
    end

    def check_collection_edit_user( c )
      record_collection_edit_users( c.id, c.depositor, c.edit_users )
    end

    def check_work_edit_users( w )
      record_work_edit_users( w.id, w.depositor, w.edit_users )
      w.file_set_ids.each { |fs| check_file_set_edit_users( w, fs ) }
    end

    def check_file_set_edit_users( w, fid )
      fs = FileSet.find fid
      record_file_set_edit_users( w, fs.id, fs.depositor, fs.edit_users )
    end

    def record_collection_edit_users( id, depositor, edit_users )
      if edit_users.nil?
        @collections_missing_edit_users << id
      elsif edit_users.count.zero?
        @collections_missing_edit_users << id
      elsif !edit_users.include? depositor
        @collections_missing_depositor_edit_user << id
      end
    end

    def record_file_set_edit_users( w, id, depositor, edit_users )
      if edit_users.nil?
        @files_missing_edit_users << id
        record_to_files_missing_depositor_edit_user( w.id, id )
      elsif edit_users.count.zero?
        @files_missing_edit_users << id
        record_to_files_missing_depositor_edit_user( w.id, id )
      elsif !edit_users.include? depositor
        @files_missing_depositor_edit_user << id
      end
    end

    def record_to_files_missing_depositor_edit_user( wid, fid )
      @work_to_files_missing_edit_users_map[wid] = [] unless @work_to_files_missing_edit_users_map.key? wid
      @work_to_files_missing_edit_users_map[wid] << fid
    end

    def record_work_edit_users( id, depositor, edit_users )
      if edit_users.nil?
        @works_missing_edit_users << id
      elsif edit_users.count.zero?
        @works_missing_edit_users << id
      elsif !edit_users.include? depositor
        @works_missing_depositor_edit_user << id
      end
    end

    def report_work_with_files_missing_edit_users( work_id: nil, files_ids_with_missing_edit_users: [] )
      w = GenericWork.find work_id
      @logger.info "work: #{work_id} #{w.title.join( ',' )}"
      @logger.info "work: #{work_id} #{w.visibility}"
      @logger.info "work: #{work_id} #{w.depositor}"
      @logger.info "work: #{work_id} has #{files_ids_with_missing_edit_users.count} files without edit_users"
      @logger.info "work: #{work_id} file ids: #{files_ids_with_missing_edit_users}" if @verbose
    end

  end

end
