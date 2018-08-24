# frozen_string_literal: true

namespace :deepblue do

  desc 'List works and their files missing file0'
  task works_missing_edit_users: :environment do
    Deepblue::WorksWithFilesMissingFile0.new.run
  end

end

module Deepblue

  class WorksWithFilesMissingFile0

    # TODO

    def run
      @collections_missing_edit_users = []
      @collections_missing_depositor_edit_user = []
      @works_missing_edit_users = []
      @works_missing_depositor_edit_user = []
      @files_missing_edit_users = []
      @files_missing_depositor_edit_user = []
      @work_to_files_missing_edit_users_map = {}
      @report_missing_files = false
      @report_missing_other = false
      @user_pacifier = false
      @verbose = false
      puts
      GenericWork.all.each do |w|
        print "#{w.id} ... " if @verbose
        # puts JSON.pretty_generate doc.as_json
        check_work_edit_users( w )
        # report_work_with_files_missing_edit_users( work_id: w.id )
      end
      Collection.all.each do |w|
        print "#{w.id} ... " if @verbose
        # puts JSON.pretty_generate doc.as_json
        check_collection_edit_user( w )
      end
      puts "done"
      # report collections missing edit users
      puts "collections_missing_edit_users.count #{@collections_missing_edit_users.count}"
      puts "collections_missing_edit_users=#{@collections_missing_edit_users}"
      puts "collections_missing_depositor_edit_user.count #{@collections_missing_depositor_edit_user.count}"
      puts "collections_missing_depositor_edit_user=#{@collections_missing_depositor_edit_user}"
      # report works missing edit users
      puts "works_missing_edit_users.count #{@works_missing_edit_users.count}"
      puts "works_missing_edit_users=#{@works_missing_edit_users}"
      puts "works_missing_depositor_edit_user.count #{@works_missing_depositor_edit_user.count}"
      puts "works_missing_depositor_edit_user=#{@works_missing_depositor_edit_user}"
      # file ids missing edit users
      puts "files_missing_edit_users.count #{@files_missing_edit_users.count}"
      puts "files_missing_edit_users=#{@files_missing_edit_users}" if @report_missing_files
      puts "files_missing_depositor_edit_user.count #{@files_missing_depositor_edit_user.count}"
      puts "files_missing_depositor_edit_user=#{@files_missing_depositor_edit_user}" if @report_missing_files
      # @files_missing_depositor_edit_user
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
      puts "work: #{work_id} #{w.title.join( ',' )}"
      puts "work: #{work_id} #{w.visibility}"
      puts "work: #{work_id} #{w.depositor}"
      puts "work: #{work_id} has #{files_ids_with_missing_edit_users.count} files without edit_users"
      puts "work: #{work_id} file ids: #{files_ids_with_missing_edit_users}" if @verbose
    end

  end

end
