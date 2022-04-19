# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:works_and_files_missing_edit_users['{"verbose":true}']
  # bundle exec rake deepblue:works_and_files_missing_edit_users['{"verbose":true\,"user_pacifier":false\,"report_missing_files":false\,"report_missing_other":false}']
  desc 'List works and their files missing edit users'
  task :works_and_files_missing_edit_users, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::WorksAndFilesMissingEditUsers.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/missing_solr_docs'

  class WorksAndFilesMissingEditUsers < MissingSolrdocs

    DEFAULT_REPORT_MISSING_FILES = false unless const_defined? :DEFAULT_REPORT_MISSING_FILES
    DEFAULT_REPORT_MISSING_OTHER = false unless const_defined? :DEFAULT_REPORT_MISSING_OTHER
    DEFAULT_USER_PACIFIER = false unless const_defined? :DEFAULT_USER_PACIFIER

    attr_accessor :report_missing_files, :report_missing_other, :user_pacifier

    attr_reader :missing_solr_doc,
                :works_missing_edit_users,
                :works_missing_depositor_edit_user,
                :orphan_file_ids,
                :files_missing_edit_users,
                :files_missing_depositor_edit_user,
                :other_missing_edit_users

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
      @missing_solr_doc = []
      @works_missing_edit_users = []
      @works_missing_depositor_edit_user = []
      @orphan_file_ids = []
      @files_missing_edit_users = []
      @files_missing_depositor_edit_user = []
      @other_missing_edit_users = []
      @errors = []
      descendants = descendant_uris( ActiveFedora.fedora.base_uri, exclude_uri: true )
      puts
      count = 0
      descendants.each do |uri|
        count += 1
        print "#{count}) #{uri} ... " if verbose
        id = uri_to_id( uri )
        puts id.to_s if verbose
        next unless filter_in( uri, id )
        doc = solr_doc( uri, id )
        hydra_model = hydra_model doc
        # puts JSON.pretty_generate doc.as_json
        if verbose
          print "#{id} has hyrdra model '#{hydra_model}'"
          print " ... is a work? #{work?( uri, id )}"
          print " ... is a file_set? #{file_set?( uri, id )}"
          puts
        end
        if doc.nil?
          @missing_solr_doc << id
          check_edit_users( uri, id )
        elsif TaskHelper.hydra_model_work?( hydra_model: hydra_model )
          w = work_or_nil( uri, id )
          puts "work_or_nil(#{id}).nil? = #{w.nil?}" if verbose
          w = work_or_nil( uri, id ) if w.nil?
          if w.nil?
            puts "Error: expected to find work #{id}"
            @errors << [hydra_model, id]
          else
            puts "Processing work #{id}" if verbose
            record_work_edit_users( uri, id, w.depositor, w.edit_users )
          end
        elsif hydra_model == "FileSet"
          fs = file_set_or_nil( uri, id )
          record_file_set_edit_users( uri, id, fs, fs.depositor, fs.edit_users )
        else
          puts "skipped '#{hydra_model}'"
          # skip
        end
      end
      puts "done"
      # report works missing edit users
      puts "works_missing_edit_users.count #{@works_missing_edit_users.count}"
      puts "works_missing_edit_users=#{@works_missing_edit_users}"
      puts "works_missing_depositor_edit_user.count #{@works_missing_depositor_edit_user.count}"
      puts "works_missing_depositor_edit_user=#{@works_missing_depositor_edit_user}"
      # orphans
      puts "@orphan_file_ids.count #{@orphan_file_ids.count}"
      puts "@orphan_file_ids=#{@orphan_file_ids}"
      # file ids missing edit users
      puts "files_missing_edit_users.count #{@files_missing_edit_users.count}"
      puts "files_missing_edit_users=#{@files_missing_edit_users}" if @report_missing_files
      puts "files_missing_depositor_edit_user.count #{@files_missing_depositor_edit_user.count}"
      puts "files_missing_depositor_edit_user=#{@files_missing_depositor_edit_user}" if @report_missing_files
      # # other
      # puts "other_missing_edit_users.count #{@other_missing_edit_users.count}"
      # puts "other_missing_edit_users=#{@other_missing_edit_users.count}" if @report_missing_other
    end

    def check_edit_users( uri, id )
      w = work_or_nil( uri, id )
      unless w.nil?
        record_work_edit_users( uri, id, w.depositor, w.edit_users )
        return
      end
      fs = file_set_or_nil( uri, id )
      return if fs.nil?
      record_file_set_edit_users( uri, id, fs, fs.depositor, fs.edit_users )
    end

    def record_file_set_edit_users( _uri, id, fs, depositor, edit_users )
      if edit_users.nil?
        @files_missing_edit_users << id
      elsif edit_users.count.zero?
        @files_missing_edit_users << id
      elsif !edit_users.include? depositor
        @files_missing_depositor_edit_user << id
      end
      parent = fs.parent
      if parent.nil?
        @orphan_file_ids << id
      elsif parent.id.nil?
        @orphan_file_ids << id
      elsif !work?( nil, parent.id )
        @orphan_file_ids << id
      end
    end

    def record_work_edit_users( _uri, id, depositor, edit_users )
      if edit_users.nil?
        @works_missing_edit_users << id
      elsif edit_users.count.zero?
        @works_missing_edit_users << id
      elsif !edit_users.include? depositor
        @works_missing_depositor_edit_user << id
      end
    end

  end

end
