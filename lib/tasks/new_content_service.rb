# frozen_string_literal: true

require 'hydra/file_characterization'
require_relative './task_helper'
require_relative './task_logger'

Hydra::FileCharacterization::Characterizers::Fits.tool_path = `which fits || which fits.sh`.strip

module Deepblue

  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  class NewContentService

    DEFAULT_DATA_SET_ADMIN_SET_NAME = "DataSet Admin Set"
    DEFAULT_USER_CREATE = true
    DEFAULT_VERBOSE = true
    MODE_APPEND = 'append'
    MODE_BUILD = 'build'
    MODE_MIGRATE = 'migrate'
    MODE_UPDATE = 'update' # TODO
    SOURCE_DBDv1 = 'DBDv1' # rubocop:disable Style/ConstantName
    SOURCE_DBDv2 = 'DBDv2' # rubocop:disable Style/ConstantName
    STOP_NEW_CONTENT_SERVICE_FILE_NAME = 'stop_umrdr_new_content'

    class RestrictedVocabularyError < RuntimeError
    end

    class TaskConfigError < RuntimeError
    end

    class UserNotFoundError < RuntimeError
    end

    class VisibilityError < RuntimeError
    end

    class WorkNotFoundError < RuntimeError
    end

    attr_reader :base_path,
                :cfg_hash,
                :config,
                :ingest_id,
                :ingest_timestamp,
                :ingester,
                :mode,
                :path_to_yaml_file,
                :user,
                :user_create,
                :verbose

    def initialize( path_to_yaml_file:, cfg_hash:, base_path:, options:, args: )
      initialize_with_msg( args: args,
                           options: options,
                           path_to_yaml_file: path_to_yaml_file,
                           cfg_hash: cfg_hash,
                           base_path: base_path )
    end

    def run
      validate_config
      build_repo_contents
    rescue RestrictedVocabularyError => e
      logger.error e.message.to_s
    rescue TaskConfigError => e
      logger.error e.message.to_s
    rescue UserNotFoundError => e
      logger.error e.message.to_s
    rescue VisibilityError => e
      logger.error e.message.to_s
    rescue WorkNotFoundError => e
      logger.error e.message.to_s
    rescue Exception => e # rubocop:disable Lint/RescueException
      logger.error "#{e.class}: #{e.message} at #{e.backtrace[0]}"
    end

    protected

      def comment_work( work_hash: )
        return unless @verbose
        comment = work_hash[:comment]
        log_msg( "#{mode}: #{comment}" ) if comment.present?
        value = work_hash[:total_file_count]
        log_msg( "#{mode}: Total file count: #{value}" ) if value.present?
        value = work_hash[:total_file_size_human_readable]
        log_msg( "#{mode}: Total file size: #{value}" ) if value.present?
      end

      def continue_new_content_service
        return false if @stop_new_content_service
        # puts "continue? check for existence of #{@stop_new_content_service_file}"
        if @stop_new_content_service_file.exist?
          @stop_new_content_service = true
          return false
        end
        # puts "continue? check for existence of #{@stop_new_content_service_ppid_file}"
        if @stop_new_content_service_ppid_file.exist?
          @stop_new_content_service = true
          return false
        end
        return true
      end

      def add_file_set_to_work( work:, file_set: )
        return if file_set.parent.present? && work.id == file_set.parent_id
        work.ordered_members << file_set
        log_provenance_add_child( parent: work, child: file_set )
        work.total_file_size_add_file_set file_set
        work.representative = file_set if work.representative_id.blank?
        work.thumbnail = file_set if work.thumbnail_id.blank?
      end

      def add_file_sets_to_work( work_hash:, work: )
        file_set_ids = work_hash[:file_set_ids]
        return add_file_sets_to_work_from_file_set_ids( work_hash: work_hash, work: work ) if file_set_ids.present?
        return add_file_sets_to_work_from_files( work_hash: work_hash, work: work )
      end

      def add_file_sets_file_size( file_set_hash: nil, path: nil )
        return '' unless @verbose
        if file_set_hash.present?
          size = file_set_hash[:file_size_human_readable]
          return '' if size.blank?
          return " with size #{size}"
        elsif path.present?
          return '' unless File.exist? path
          size = File.new( path ).size
          size = TaskHelper.human_readable_size( size )
          return " with size #{size}"
        end
        return ''
      end

      def add_file_sets_to_work_from_file_set_ids( work_hash:, work: )
        file_set_ids = work_hash[:file_set_ids]
        count = file_set_ids.size
        i = 0
        file_set_ids.each do |file_set_id|
          i += 1
          next unless continue_new_content_service
          file_set_key = "f_#{file_set_id}"
          file_set_hash = work_hash[file_set_key.to_sym]
          file_size = add_file_sets_file_size( file_set_hash: file_set_hash )
          file_set = build_file_set_from_hash( id: file_set_id.to_s,
                                               file_set_hash: file_set_hash,
                                               parent: work,
                                               file_set_of: i,
                                               file_set_count: count,
                                               file_size: file_size )
          add_file_set_to_work( work: work, file_set: file_set )
        end
        work.save!
        work.reload
        return work
      end

      def add_file_sets_to_work_from_files( work_hash:, work: )
        files = work_hash[:files]
        return work if files.blank?
        file_ids = work_hash[:file_ids]
        file_ids = [] if file_ids.nil?
        filenames = work_hash[:filenames]
        filenames = [] if filenames.nil?
        paths_and_names = files.zip( filenames, file_ids )
        count = paths_and_names.size
        i = 0
        paths_and_names.each do |fp|
          i += 1
          next unless continue_new_content_service
          file_size = add_file_sets_file_size( file_set_hash: nil, path: fp[0] )
          fs = build_file_set( id: nil,
                               path: fp[0],
                               work: work,
                               filename: fp[1],
                               file_ids: fp[2],
                               file_set_of: i,
                               file_set_count: count,
                               file_size: file_size )
          add_file_set_to_work( work: work, file_set: fs )
        end
        work.save!
        work.reload
        return work
      end

      def add_measurement( measurement )
        measurements << measurement
      end

      def add_works_to_collection( collection_hash:, collection: )
        # puts "collection_hash=#{collection_hash}"
        work_ids = works_from_hash( hash: collection_hash )
        work_ids[0].each do |work_id|
          next unless continue_new_content_service
          # puts "work_id=#{work_id}"
          work_hash = works_from_id( hash: collection_hash, work_id: work_id.to_s )
          # puts "work_hash=#{work_hash}"
          work = build_or_find_work( work_hash: work_hash, parent: collection )
          next if work.member_of_collection_ids.include? collection.id
          work.member_of_collections << collection
          log_provenance_add_child( parent: collection, child: work )
          work.save!
        end
        collection.save!
        collection.reload
        return collection
      end

      def admin_set_default
        @admin_set_default ||= AdminSet.find( AdminSet::DEFAULT_ID )
        # @admin_set_default ||= AdminSet.find_or_create_default_admin_set_id
      end

      def admin_set_data_set
        @admin_set_data_set ||= AdminSet.all.select { |x| x.title == [DEFAULT_DATA_SET_ADMIN_SET_NAME] }.first
      end

      def admin_set_data_set?( admin_set )
        return false if admin_set.nil?
        admin_set.title == [DEFAULT_DATA_SET_ADMIN_SET_NAME]
      end

      def admin_set_work
        if TaskHelper.dbd_version_1?
          admin_set_default
        else
          admin_set_data_set
        end
      end

      def apply_visibility_and_workflow( work:, work_hash:, admin_set: )
        # puts "work.id=#{work.id} admin_set.id=#{admin_set.id}"
        work.visibility = visibility_from_hash( hash: work_hash )
        work.admin_set = admin_set
        # puts "work.id=#{work.id} admin_set.id=#{admin_set.id} visibility=#{work.visibility}"
        return if TaskHelper.dbd_version_1?
        return unless admin_set_data_set? admin_set
        wf = work.active_workflow
        # puts "wf.name=#{wf.name}"
        wgid = work.to_global_id.to_s
        # user = User.find_by_user_key( work.owner )
        # agent = PowerConverter.convert( user, to: :sipity_agent )
        entity = Sipity::Entity.create!( proxy_for_global_id: wgid, workflow: wf, workflow_state: nil )
        # entity = PowerConverter.convert( work, to: :sipity_entity )
        action_name = if "open" == work.visibility
                        "deposited"
                      else
                        "pending_review"
                      end
        # puts "action_name=#{action_name}"
        action = Sipity::WorkflowAction.find_or_create_by!( workflow: wf, name: action_name )
        action_id = action.id
        wf_state = Sipity::WorkflowState.find_or_create_by!( workflow: wf, name: action_name )
        entity.update!( workflow_state_id: action_id, workflow_state: wf_state )
        log_provenance_workflow( curation_concern: work, workflow: wf, workflow_state: action_name )
      end

      def build_admin_set_work( hash: )
        admin_set_id = hash[:admin_set_id]
        # TODO: admin_set_title = hash[:admin_set_title]
        return admin_set_work if admin_set_id.blank?
        return admin_set_work if AdminSet.default_set? admin_set_id
        begin
          admin_set = AdminSet.find( admin_set_id )
        rescue ActiveFedora::ObjectNotFoundError
          # TODO: Log this
          admin_set = admin_set_work
        end
        admin_set
      end

      def build_collection( id:, collection_hash: )
        return nil unless continue_new_content_service
        if MODE_APPEND == mode && id.present?
          collection = find_collection_using_prior_id( prior_id: id )
          log_msg( "#{mode}: found collection with prior id: #{id} title: #{collection.title.first}" ) if collection.present?
          return collection if collection.present?
        end
        if MODE_MIGRATE == mode && id.present?
          collection = find_collection_using_id( id: id )
          log_msg( "#{mode}: found collection with id: #{id} title: #{collection.title.first}" ) if collection.present?
          return collection if collection.present?
        end
        creator = Array( collection_hash[:creator] )
        curation_notes_admin = Array( collection_hash[:curation_notes_admin] )
        curation_notes_user = Array( collection_hash[:curation_notes_user] )
        date_created = build_date( hash: collection_hash, key: :date_created )
        date_modified = build_date( hash: collection_hash, key: :date_modified )
        date_uploaded = build_date( hash: collection_hash, key: :date_uploaded )
        description = Array( collection_hash[:description] )
        edit_users = Array( collection_hash[:edit_users] )
        keyword = Array( collection_hash[:keyword] )
        language = Array( collection_hash[:language] )
        prior_identifier = build_prior_identifier( hash: collection_hash, id: id )
        referenced_by = build_referenced_by( hash: collection_hash )
        resource_type = Array( collection_hash[:resource_type] || 'Collection' )
        subject_discipline = build_subject_discipline( hash: collection_hash )
        title = Array( collection_hash[:title] )
        # user_create_users( emails: depositor )
        id_new = MODE_MIGRATE == mode ? id : nil
        collection = new_collection( creator: creator,
                                     curation_notes_admin: curation_notes_admin,
                                     curation_notes_user: curation_notes_user,
                                     date_created: date_created,
                                     date_modified: date_modified,
                                     date_uploaded: date_uploaded,
                                     description: description,
                                     id: id_new,
                                     keyword: keyword,
                                     language: language,
                                     prior_identifier: prior_identifier,
                                     referenced_by: referenced_by,
                                     resource_type: resource_type,
                                     subject_discipline: subject_discipline,
                                     title: title )
        collection.collection_type = build_collection_type( hash: collection_hash )
        depositor = build_depositor( hash: collection_hash )
        collection.apply_depositor_metadata( depositor )
        update_edit_users( curation_concern: collection, edit_users: edit_users )
        collection.visibility = visibility_from_hash( hash: collection_hash )
        collection.save!
        collection.reload
        log_provenance_migrate( curation_concern: collection ) if MODE_MIGRATE == mode
        log_provenance_ingest( curation_concern: collection )
        return collection
      end

      def build_collection_type( hash: )
        return Hyrax::CollectionType.find_or_create_default_collection_type if SOURCE_DBDv1 == source
        collection_type = hash[:collection_type]
        collection_type = Hyrax::CollectionType.find_by( machine_id: collection_type ) if collection_type.present?
        return collection_type if collection_type.present?
        collection_type_gid = hash[:collection_type_gid]
        collection_type = Hyrax::CollectionType.find_by_gid( collection_type_gid ) if collection_type_gid.present?
        return collection_type if collection_type.present?
        Hyrax::CollectionType.find_or_create_default_collection_type
      end

      def build_collections
        return unless collections
        user_create_users( emails: user_key )
        collections.each do |collection_hash|
          next unless continue_new_content_service
          collection_id = 'nil'
          collection = nil
          measurement = Benchmark.measure do
            collection = build_or_find_collection( collection_hash: collection_hash )
            collection_id = collection.id if collection.present?
          end
          next if collection.blank?
          measurement.instance_variable_set( :@label, collection_id )
          add_measurement measurement
        end
      end

      def build_date( hash:, key: )
        rv = hash[key]
        return DateTime.now.to_s if rv.blank?
        rv = rv[0] if rv.is_a? Array
        rv = DateTime.parse rv
        return rv.to_s
      rescue ArgumentError
        return build_date2( rv )
      end

      def build_date2( str )
        return DateTime.strptime( str, "%m/%d/%Y" ) if str.match?( /\d\d?\/\d\d?\/\d\d\d\d/ )
        return DateTime.strptime( str, "%m-%d-%Y" ) if str.match?( /\d\d?\-\d\d?\-\d\d\d\d/ )
        return DateTime.strptime( str, "%Y" ) if str.match?( /\d\d\d\d/ )
        return DateTime.now.to_s
      rescue ArgumentError
        log_msg( "Failed to parse data string '#{str}'" )
        return DateTime.now.to_s
      end

      def build_date_coverage( hash: )
        rv = Array( hash[:date_coverage] )
        return nil if rv.empty?
        return rv.first
      end

      def build_depositor( hash: )
        depositor = hash[:depositor]
        user_create_users( emails: depositor ) if depositor.present?
        return depositor if depositor.present?
        depositor = user_key
        return depositor
      end

      def build_file_set( id:, path:, work:, filename: nil, file_ids: nil, file_set_of:, file_set_count:, file_size: '' )
        # puts "id=#{id} path=#{path} filename=#{filename} file_ids=#{file_ids}"
        log_msg( "#{mode}: building file #{file_set_of} of #{file_set_count}#{file_size}" ) if @verbose
        fname = filename || File.basename( path )
        build_file_set_new( id: id, depositor: work.depositor, path: path, original_name: fname )
        file_set.title = Array( fname )
        file_set.label = fname
        now = DateTime.now.new_offset( 0 )
        file_set.date_uploaded = now
        file_set.visibility = work.visibility
        file_set.owner = work.owner
        file_set.depositor = work.depositor
        file_set.prior_identifier = file_ids if file_ids.present?
        file_set.save!
        return build_file_set_ingest( file_set: file_set, path: path, checksum_algorithm: nil, checksum_value: nil )
      end

      def build_file_set_from_hash( id:, file_set_hash:, parent:, file_set_of:, file_set_count:, file_size: '' )
        if MODE_APPEND == mode && id.present?
          file_set = find_file_set_using_prior_id( prior_id: id, parent: parent )
          log_msg( "#{mode}: found file_set with prior id: #{id} title: #{file_set.title.first}" ) if file_set.present?
          return file_set if file_set.present?
        end
        if MODE_MIGRATE == mode && id.present?
          file_set = find_file_set_using_id( id: id )
          log_msg( "#{mode}: found file_set with id: #{id} title: #{file_set.title.first}" ) if file_set.present?
          return file_set if file_set.present?
        end
        log_msg( "#{mode}: building file #{file_set_of} of #{file_set_count}#{file_size}" ) if @verbose
        # puts "id=#{id} path=#{path} filename=#{filename} file_ids=#{file_ids}"
        depositor = build_depositor( hash: file_set_hash )
        path = file_set_hash[:file_path]
        original_name = file_set_hash[:original_name]
        file_set = build_file_set_new( id: id, depositor: depositor, path: path, original_name: original_name )

        curation_notes_admin = Array( file_set_hash[:curation_notes_admin] )
        curation_notes_user = Array( file_set_hash[:curation_notes_user] )
        checksum_algorithm = file_set_hash[:checksum_algorithm]
        checksum_value = file_set_hash[:checksum_value]
        date_created = Array( build_date( hash: file_set_hash, key: :date_created ) )
        date_modified = build_date( hash: file_set_hash, key: :date_modified )
        date_uploaded = build_date( hash: file_set_hash, key: :date_uploaded )
        edit_users = Array( file_set_hash[:edit_users] )
        label = file_set_hash[:label]
        prior_identifier = build_prior_identifier( hash: file_set_hash, id: id )
        title = Array( file_set_hash[:title] )
        visibility = visibility_from_hash( hash: file_set_hash )

        update_cc_attribute( curation_concern: file_set, attribute: :title, value: title )
        update_cc_attribute( curation_concern: file_set, attribute: :curation_notes_admin, value: curation_notes_admin )
        update_cc_attribute( curation_concern: file_set, attribute: :curation_notes_user, value: curation_notes_user )
        file_set.label = label
        file_set.date_uploaded = date_uploaded
        file_set.date_modified = date_modified
        file_set.date_created = date_created
        update_cc_attribute( curation_concern: file_set, attribute: :prior_identifier, value: prior_identifier )
        update_edit_users( curation_concern: file_set, edit_users: edit_users )
        update_visibility( curation_concern: file_set, visibility: visibility )
        file_set.save!

        return build_file_set_ingest( file_set: file_set,
                                      path: path,
                                      checksum_algorithm: checksum_algorithm,
                                      checksum_value: checksum_value )
      end

      def build_file_set_ingest( file_set:, path:, checksum_algorithm:, checksum_value: )
        log_object file_set
        log_provenance_migrate( curation_concern: file_set ) if MODE_MIGRATE == mode
        repository_file_id = nil
        IngestHelper.characterize( file_set,
                                   repository_file_id,
                                   path,
                                   delete_input_file: false,
                                   continue_job_chain: false,
                                   current_user: user,
                                   ingest_id: ingest_id,
                                   ingester: ingester,
                                   ingest_timestamp: ingest_timestamp )
        IngestHelper.create_derivatives( file_set,
                                         repository_file_id,
                                         path,
                                         delete_input_file: false,
                                         current_user: user,
                                         ingest_id: ingest_id,
                                         ingester: ingester,
                                         ingest_timestamp: ingest_timestamp )
        log_provenance_ingest( curation_concern: file_set )
        if checksum_algorithm.present? && checksum_value.present?
          checksum = file_set_checksum( file_set: file_set )
          log_msg( "#{mode}: file checksum is nil" ) if checksum.blank?
          if checksum.present? && checksum.algorithm == checksum_algorithm
            if checksum.value == checksum_value
              log_msg( "#{mode}: checksum succeeded: #{checksum_value}" )
              log_provenance_fixity_check( curation_concern: file_set,
                                           fixity_check_status: 'success',
                                           fixity_check_note: '' )
            else
              msg = "#{checksum.value} vs #{checksum_value}"
              log_msg( "#{mode}: WARNING checksum failed: #{msg}" )
              log_provenance_fixity_check( curation_concern: file_set,
                                           fixity_check_status: 'failed',
                                           fixity_check_note: msg )
            end
          else
            msg = "incompatible checksum algorithms: #{checksum.algorithm} vs #{checksum_algorithm}"
            log_msg( "#{mode}: #{msg}" )
            log_provenance_fixity_check( curation_concern: file_set,
                                         fixity_check_status: 'failed',
                                         fixity_check_note: msg )
          end
        end
        log_msg( "#{mode}: finished: #{path}" )
        return file_set
      end

      def build_file_set_new( id:, depositor:, path:, original_name: )
        log_msg( "#{mode}: processing: #{path}" )
        file = File.open( path )
        # fix so that filename comes from the name of the file and not the hash
        file.define_singleton_method( :original_name ) do
          original_name
        end
        id_new = MODE_MIGRATE == mode ? id : nil
        attempts = 0
        file_set = nil
        loop do
          break if attempts > 3
          file_set = new_file_set( id: id_new )
          file_set.apply_depositor_metadata( depositor )
          success = upload_file_to_file_set( file_set, file )
          break if success
          attempts += 1
          file_set = nil
        end
        return file_set
      end

      def build_fundedby( hash: )
        rv = Array( hash[:fundedby] )
        return rv
      end

      def build_or_find_collection( collection_hash: )
        # puts "build_or_find_collection( collection_hash: #{ActiveSupport::JSON.encode( collection_hash )} )"
        return nil unless continue_new_content_service
        return if collection_hash.blank?
        id = collection_hash[:id].to_s
        mode = collection_hash[:mode]
        mode = MODE_BUILD if id.blank?
        collection = nil
        collection = Collection.find( id ) if MODE_APPEND == mode
        collection = build_collection( id: id, collection_hash: collection_hash ) if collection.nil?
        return nil if collection.nil?
        log_object collection if collection.present?
        add_works_to_collection( collection_hash: collection_hash, collection: collection )
        collection.save!
        return collection
      end

      def build_or_find_user( user_hash:, user_update: true )
        return nil if user_hash.blank?
        email = user_hash[:email]
        log_msg( "build_or_find_user: email: #{email}" ) if verbose
        user = User.find_by_user_key( email )
        if user.present?
          log_object user if verbose
          log_msg( "found user: #{user}" ) if verbose
          update_user( user: user, user_hash: user_hash ) if user_update
          return user
        end
        user = build_user( user_hash: user_hash )
        log_object user if user.present?
        return user
      end

      def build_or_find_work( work_hash:, parent: )
        # puts "build_or_find_work( work_hash: #{work_hash} )"
        return nil unless continue_new_content_service
        return nil if work_hash.blank?
        comment_work( work_hash: work_hash )
        id = work_hash[:id].to_s
        mode = work_hash[:mode]
        mode = MODE_BUILD if id.blank?
        work = nil
        work = GenericWork.find( id ) if MODE_APPEND == mode
        work = build_work( id: id, work_hash: work_hash, parent: parent ) if work.nil?
        return nil if work.nil?
        log_object work if work.present?
        add_file_sets_to_work( work_hash: work_hash, work: work )
        return work
      end

      def build_prior_identifier( hash:, id: )
        if SOURCE_DBDv1 == source
          if MODE_MIGRATE == mode
            []
          else
            Array( id )
          end
        else
          arr = Array( hash[:prior_identifier] )
          return arr if MODE_MIGRATE == mode
          arr << id if id.present?
        end
      end

      def build_referenced_by( hash: )
        if SOURCE_DBDv1 == source
          Array( hash[:isReferencedBy] )
        else
          hash[:referenced_by]
        end
      end

      def build_rights_liscense( hash: )
        rv = if SOURCE_DBDv1 == source
               hash[:rights]
             else
               hash[:rights_license]
             end
        rv = rv[0] if rv.respond_to?( '[]' )
        return rv
      end

      def build_repo_contents
        # override with something interesting
      end

      def build_subject_discipline( hash: )
        if SOURCE_DBDv1 == source
          Array( hash[:subject] )
        else
          Array( hash[:subject_discipline] )
        end
      end

      def build_user( user_hash: )
        attr_names = User.attribute_names
        skip = Deepblue::MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE
        attrs = { password: "password", password_confirmation: "password" }
        attr_names.each do |name|
          next if skip.include?( name )
          next if name == "id"
          value = user_hash[name.to_sym]
          attrs[name] = value if value.present?
        end
        log_msg( "User.create!( #{attrs} )" )
        User.create!( attrs )
      end

      def update_user( user:, user_hash: )
        attr_names = User.attribute_names
        skip = Deepblue::MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE
        attr_names.each do |name|
          next if skip.include?( name )
          next if name == "id"
          value = user_hash[name.to_sym]
          user[name] = value if value.present?
        end
        log_msg( "update_user #{user.email}" )
        user.save
      end

      def build_users
        return unless users
        # user_create_users( emails: user_key )
        measurement = Benchmark.measure do
          users.each do |users_hash|
            user_emails = users_hash[:user_emails]
            next if user_emails.blank?
            log_msg( "users_hash: #{users_hash}" ) if verbose
            user_emails.each do |user_email|
              log_msg( "processing user: #{user_email}" ) if verbose
              user_email_id = "user_#{user_email}".to_sym
              log_msg( "user_email_id: #{user_email_id}" ) if verbose
              user_hash = users_hash[user_email_id]
              log_msg( "user_hash: #{user_hash}" ) if verbose
              user = build_or_find_user( user_hash: user_hash )
              log_object user if user.present?
            end
          end
        end
        return measurement
      end

      def build_work( id:, work_hash:, parent: )
        return nil unless continue_new_content_service
        if MODE_APPEND == mode && id.present?
          work = find_work_using_prior_id( prior_id: id, parent: parent )
          log_msg( "#{mode}: found work with prior id: #{id} title: #{work.title.first}" ) if work.present?
          return work if work.present?
        end
        if MODE_MIGRATE == mode && id.present?
          work = find_work_using_id( id: id )
          log_msg( "#{mode}: found work with id: #{id} title: #{work.title.first}" ) if work.present?
          return work if work.present?
        end
        authoremail = work_hash[:authoremail]
        contributor = Array( work_hash[:contributor] )
        creator = Array( work_hash[:creator] )
        curation_notes_admin = Array( work_hash[:curation_notes_admin] )
        curation_notes_user = Array( work_hash[:curation_notes_user] )
        date_coverage = build_date_coverage( hash: work_hash )
        date_created = build_date( hash: work_hash, key: :date_created )
        date_modified = build_date( hash: work_hash, key: :date_modified )
        date_uploaded = build_date( hash: work_hash, key: :date_uploaded )
        description = Array( work_hash[:description] )
        edit_users = Array( work_hash[:edit_users] )
        fundedby = build_fundedby( hash: work_hash )
        fundedby_other = work_hash[:fundedby_other]
        grantnumber = work_hash[:grantnumber]
        language = Array( work_hash[:language] )
        keyword = Array( work_hash[:keyword] )
        methodology = work_hash[:methodology] || "No Methodology Available"
        prior_identifier = build_prior_identifier( hash: work_hash, id: id )
        referenced_by = build_referenced_by( hash: work_hash )
        resource_type = Array( work_hash[:resource_type] || 'Dataset' )
        rights_license = build_rights_liscense( hash: work_hash )
        rights_license_other = work_hash[:rights_license_other]
        subject_discipline = build_subject_discipline( hash: work_hash )
        title = Array( work_hash[:title] )
        id_new = MODE_MIGRATE == mode ? id : nil
        user_create_users( emails: authoremail )
        work = new_data_set( authoremail: authoremail,
                             contributor: contributor,
                             creator: creator,
                             curation_notes_admin: curation_notes_admin,
                             curation_notes_user: curation_notes_user,
                             date_coverage: date_coverage,
                             date_created: date_created,
                             date_modified: date_modified,
                             date_uploaded: date_uploaded,
                             description: description,
                             fundedby: fundedby,
                             fundedby_other: fundedby_other,
                             grantnumber: grantnumber,
                             id: id_new,
                             keyword: keyword,
                             language: language,
                             methodology: methodology,
                             prior_identifier: prior_identifier,
                             referenced_by: referenced_by,
                             resource_type: resource_type,
                             rights_license: rights_license,
                             rights_license_other: rights_license_other,
                             subject_discipline: subject_discipline,
                             title: title )

        depositor = build_depositor( hash: work_hash )
        work.apply_depositor_metadata( depositor )
        update_edit_users( curation_concern: work, edit_users: edit_users )
        work.owner = depositor
        admin_set = build_admin_set_work( hash: work_hash )
        work.update( admin_set: admin_set )
        apply_visibility_and_workflow( work: work, work_hash: work_hash, admin_set: admin_set )
        work.save!
        work.reload
        log_provenance_migrate( curation_concern: work ) if MODE_MIGRATE == mode
        log_provenance_ingest( curation_concern: work )
        return work
      end

      def build_works
        return unless works
        user_create_users( emails: user_key )
        works.each do |work_hash|
          next unless continue_new_content_service
          work = nil
          work_id = 'nil'
          measurement = Benchmark.measure do
            work = build_or_find_work( work_hash: work_hash, parent: nil )
            work_id = work.id if work.present?
            log_object work if work.present?
          end
          next if work.blank?
          measurement.instance_variable_set( :@label, work_id )
          add_measurement measurement
        end
      end

      def collections
        @collections ||= collections_from_hash( hash: @cfg_hash[:user] )
      end

      def collections_from_hash( hash: )
        [hash[:collections]]
      end

      def cfg_hash_value( base_key: :config, key:, default_value: )
        rv = default_value
        if @cfg_hash.key? base_key
          rv = @cfg_hash[base_key][key] if @cfg_hash[base_key].key? key
        end
        return rv
      end

      def file_from_file_set( file_set: )
        file = nil
        files = file_set.files
        unless files.nil? || files.size.zero?
          file = files[0]
          files.each do |f|
            file = f unless f.original_name.empty?
          end
        end
        return file
      end

      def file_set_checksum( file_set: )
        file = file_from_file_set( file_set: file_set )
        return file.checksum if file.present?
        return nil
      end

      def find_collection_using_id( id: )
        return nil if id.blank?
        Collection.find id
      rescue ActiveFedora::ObjectNotFoundError
        return nil
      end

      def find_collection_using_prior_id( prior_id: )
        return nil if prior_id.blank?
        Collection.all.each do |curation_concern|
          prior_ids = Array( curation_concern.prior_identifier )
          prior_ids.each do |id|
            return curation_concern if id == prior_id
          end
        end
        return nil
      end

      def find_file_set_using_id( id: )
        return nil if id.blank?
        FileSet.find id
      rescue ActiveFedora::ObjectNotFoundError
        return nil
      end

      def find_file_set_using_prior_id( prior_id:, parent: )
        return nil if prior_id.blank?
        return if parent.blank?
        parent.file_sets.each do |fs|
          prior_ids = Array( fs.prior_identifier )
          prior_ids.each do |id|
            return fs if id == prior_id
          end
        end
        FileSet.all.each do |fs|
          if fs.parent.present?
            return fs if fs.parent.present? && fs.parent_id == parent.id
            next
          end
          prior_ids = Array( fs.prior_identifier )
          prior_ids.each do |id|
            return fs if id == prior_id
          end
        end
        return nil
      end

      def find_or_create_user
        user = User.find_by( user_key: user_key ) || create_user( user_key )
        raise UserNotFoundError, "User not found: #{user_key}" if user.nil?
        return user
      end

      def find_work( work_hash: )
        work_id = work_hash[:id].to_s
        id = Array(work_id)
        # owner = Array(work_hash[:owner])
        work = TaskHelper.work_find( id: id[0] )
        raise UserNotFoundError, "Work not found: #{work_id}" if work.nil?
        return work
      end

      def find_works_and_add_files
        return unless works
        works.each do |work_hash|
          next unless continue_new_content_service
          work = find_work( work_hash: work_hash )
          measurement = Benchmark.measure( work.id ) do
            add_file_sets_to_work( work_hash: work_hash, work: work )
            depositor = build_depositor( hash: work_hash )
            work.apply_depositor_metadata( depositor )
            work.owner = depositor
            admin_set = build_admin_set_work( hash: work_hash )
            work.admin_set = admin_set
            apply_visibility_and_workflow( work: work, work_hash: work_hash, admin_set: admin_set )
            work.save!
            log_object work
          end
          add_measurement measurement
        end
      end

      def find_work_using_id( id: )
        return nil if id.blank?
        TaskHelper.work_find( id: id.to_s )
      rescue ActiveFedora::ObjectNotFoundError
        return nil
      end

      def find_work_using_prior_id( prior_id:, parent: )
        return nil if prior_id.blank?
        if parent.present?
          parent.member_objects.each do |obj|
            next unless TaskHelper.work? obj
            prior_ids = Array( obj.prior_identifier )
            prior_ids.each do |id|
              return obj if id == prior_id
            end
          end
        end
        TaskHelper.all_works.each do |curation_concern|
          prior_ids = Array( curation_concern.prior_identifier )
          prior_ids.each do |id|
            return curation_concern if id == prior_id
          end
        end
        return nil
      end

      def ingest_id
        @ingest_id ||= @cfg_hash[:user][:ingester]
      end

      def ingester
        @cfg_hash[:user][:ingester]
      end

      # rubocop:disable Rails/Output
      def initialize_with_msg( args:,
                               options:,
                               path_to_yaml_file:,
                               cfg_hash:,
                               base_path:,
                               mode: nil,
                               ingester: nil,
                               user_create: DEFAULT_USER_CREATE,
                               msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE",
                               **config )

        DeepBlueDocs::Application.config.provenance_log_echo_to_rails_logger = false
        ProvenanceHelper.echo_to_rails_logger = false

        @options = TaskHelper.task_options_parse options
        if @options.key?( :error ) || @options.key?( 'error' )
          puts "WARNING: options error #{@options['error']}"
          puts "options=#{options}" if @options.key?
          puts "@options=#{@options}" if @options.key?
        end
        @verbose = TaskHelper.task_options_value( @options, key: 'verbose', default_value: DEFAULT_VERBOSE )
        puts "@verbose=#{@verbose}" if @verbose

        verbose_init = false
        @args = args # TODO: args.to_hash
        puts "args=#{args}" if verbose_init
        # puts "args=#{JSON.pretty_print args.as_json}" if verbose_init
        puts "ENV['TMPDIR']=#{ENV['TMPDIR']}" if verbose_init
        puts "ENV['_JAVA_OPTIONS']=#{ENV['_JAVA_OPTIONS']}" if verbose_init
        tmpdir = ENV['TMPDIR']
        tmpdir = File.absolute_path( './tmp/' ) if tmpdir.blank?
        ENV['_JAVA_OPTIONS'] = "-Djava.io.tmpdir=#{tmpdir}"
        puts "ENV['_JAVA_OPTIONS']=#{ENV['_JAVA_OPTIONS']}" if verbose_init
        puts `echo $_JAVA_OPTIONS`.to_s if verbose_init
        @path_to_yaml_file = path_to_yaml_file
        @config = {}
        @config.merge!( config ) if config.present?
        @cfg_hash = cfg_hash
        @base_path = base_path
        @ingest_id = File.basename path_to_yaml_file
        @ingest_timestamp = DateTime.now
        @mode = mode if mode.present?
        @ingester = ingester if ingester.present?
        @user_create = user_create
        @stop_new_content_service = false
        current_dir = Pathname.new( '.' ).realdirpath
        @stop_new_content_service_file = current_dir.join STOP_NEW_CONTENT_SERVICE_FILE_NAME
        @stop_new_content_service_ppid_file = current_dir.join( "#{Process.ppid}_#{STOP_NEW_CONTENT_SERVICE_FILE_NAME}" )
        logger.info msg if msg.present?
      end
      # rubocop:enable Rails/Output

      def log_msg( msg )
        return if msg.blank?
        logger.info "#{timestamp_now} #{msg}"
      end

      def log_object( obj )
        id = if obj.respond_to?( :has_attribute? ) && obj.has_attribute?( :prior_identifier )
               "#{obj.id} prior id: #{Array( obj.prior_identifier )}"
             elsif obj.respond_to? :email
               obj.email
             elsif obj.respond_to? :id
               obj.id.to_s
             else
               'no_id'
             end
        title = if obj.respond_to? :title
                  value = obj.title
                  value = value.first if value.respond_to? :first
                  value
                else
                  'no_title'
                end
        msg = if obj.respond_to? :title
                "#{mode}: #{obj.class.name} id: #{id} title: #{title}"
              else
                "#{mode}: #{obj.class.name} id: #{id}"
              end
        log_msg msg
      end

      def log_provenance_add_child( parent:, child: )
        return unless parent.respond_to? :provenance_child_add
        parent.provenance_child_add( current_user: user,
                                     child_id: child.id,
                                     ingest_id: ingest_id,
                                     ingester: ingester,
                                     ingest_timestamp: ingest_timestamp )
      end

      def log_provenance_fixity_check( curation_concern:, fixity_check_status:, fixity_check_note: )
        return unless curation_concern.respond_to? :provenance_fixity_check
        curation_concern.provenance_fixity_check( current_user: user,
                                                  fixity_check_status: fixity_check_status,
                                                  fixity_check_note: fixity_check_note )
      end

      def log_provenance_ingest( curation_concern: )
        return unless curation_concern.respond_to? :provenance_ingest
        curation_concern.provenance_ingest( current_user: user,
                                            calling_class: self.class.name,
                                            ingest_id: ingest_id,
                                            ingester: ingester,
                                            ingest_timestamp: ingest_timestamp )
      end

      def log_provenance_migrate( curation_concern:, migrate_direction: 'import' )
        return unless curation_concern.respond_to? :provenance_migrate
        curation_concern.provenance_migrate( current_user: user, migrate_direction: migrate_direction )
      end

      def log_provenance_workflow( curation_concern:, workflow:, workflow_state: )
        return unless curation_concern.respond_to? :provenance_workflow
        curation_concern.provenance_workflow( current_user: user,
                                              workflow_name: workflow.name,
                                              workflow_state: workflow_state,
                                              workflow_state_prior: '' )
      end

      def logger
        @logger ||= logger_initialize
      end

      def logger_initialize
        # TODO: add some flags to the input yml file for log level and Rails logging integration
        TaskHelper.logger_new
      end

      def logger_level
        rv = cfg_hash_value( key: :logger_level, default_value: 'info' )
        return rv
      end

      def measurements
        @measurements ||= []
      end

      def mode
        # @mode ||= @cfg_hash[:user][:mode]
        @mode ||= cfg_hash_value( base_key: :user, key: :mode, default_value: MODE_APPEND )
      end

      def new_collection( creator:,
                          curation_notes_admin:,
                          curation_notes_user:,
                          date_created:,
                          date_modified:,
                          date_uploaded:,
                          description:,
                          id:,
                          keyword:,
                          language:,
                          prior_identifier:,
                          referenced_by:,
                          resource_type:,
                          subject_discipline:,
                          title: )

        if id.present?
          Collection.new( creator: creator,
                          curation_notes_admin: curation_notes_admin,
                          curation_notes_user: curation_notes_user,
                          date_created: date_created,
                          date_modified: date_modified,
                          date_uploaded: date_uploaded,
                          description: description,
                          id: id,
                          keyword: keyword,
                          language: language,
                          prior_identifier: prior_identifier,
                          referenced_by: referenced_by,
                          resource_type: resource_type,
                          subject_discipline: subject_discipline,
                          title: title )
        else
          Collection.new( creator: creator,
                          curation_notes_admin: curation_notes_admin,
                          curation_notes_user: curation_notes_user,
                          date_created: date_created,
                          date_modified: date_modified,
                          date_uploaded: date_uploaded,
                          description: description,
                          keyword: keyword,
                          language: language,
                          prior_identifier: prior_identifier,
                          referenced_by: referenced_by,
                          resource_type: resource_type,
                          subject_discipline: subject_discipline,
                          title: title )
        end
      end

      def new_data_set( authoremail:,
                        contributor:,
                        creator:,
                        curation_notes_admin:,
                        curation_notes_user:,
                        date_coverage:,
                        date_created:,
                        date_modified:,
                        date_uploaded:,
                        description:,
                        fundedby:,
                        fundedby_other:,
                        grantnumber:,
                        id:,
                        keyword:,
                        language:,
                        methodology:,
                        prior_identifier:,
                        referenced_by:,
                        resource_type:,
                        rights_license:,
                        rights_license_other:,
                        subject_discipline:,
                        title: )
        if id.present?
          DataSet.new( authoremail: authoremail,
                       contributor: contributor,
                       creator: creator,
                       curation_notes_admin: curation_notes_admin,
                       curation_notes_user: curation_notes_user,
                       date_coverage: date_coverage,
                       date_created: date_created,
                       date_modified: date_modified,
                       date_uploaded: date_uploaded,
                       description: description,
                       fundedby: fundedby,
                       fundedby_other: fundedby_other,
                       grantnumber: grantnumber,
                       id: id,
                       keyword: keyword,
                       language: language,
                       methodology: methodology,
                       prior_identifier: prior_identifier,
                       referenced_by: referenced_by,
                       resource_type: resource_type,
                       rights_license: rights_license,
                       rights_license_other: rights_license_other,
                       subject_discipline: subject_discipline,
                       title: title )
        else
          DataSet.new( authoremail: authoremail,
                       contributor: contributor,
                       creator: creator,
                       curation_notes_admin: curation_notes_admin,
                       curation_notes_user: curation_notes_user,
                       date_coverage: date_coverage,
                       date_created: date_created,
                       date_modified: date_modified,
                       date_uploaded: date_uploaded,
                       description: description,
                       fundedby: fundedby,
                       fundedby_other: fundedby_other,
                       grantnumber: grantnumber,
                       keyword: keyword,
                       language: language,
                       methodology: methodology,
                       prior_identifier: prior_identifier,
                       referenced_by: referenced_by,
                       resource_type: resource_type,
                       rights_license: rights_license,
                       rights_license_other: rights_license_other,
                       subject_discipline: subject_discipline,
                       title: title )
        end
      end

      def new_file_set( id: )
        if id.present?
          FileSet.new( id: id )
        else
          FileSet.new
        end
      end

      def report( first_label:, first_id:, measurements:, total: nil )
        return if measurements.blank?
        label = first_label
        label += ' ' * (first_id.size - label.size)
        log_msg "#{label} #{Benchmark::CAPTION.chop}"
        format = Benchmark::FORMAT.chop
        measurements.each do |measurement|
          label = measurement.label
          log_msg measurement.format( "#{label} #{format} is #{TaskHelper.seconds_to_readable(measurement.real)}" )
        end
        return if measurements.size == 1
        return if total.blank?
        label = 'total'
        label += ' ' * (first_id.size - label.size)
        log_msg total.format( "#{label} #{format} is #{TaskHelper.seconds_to_readable(total.real)}" )
      end

      def report_measurements( first_label: )
        return if measurements.blank?
        puts
        log_msg "Report run time:"
        m1 = measurements[0]
        first_id = m1.label
        total = nil
        measurements.each do |measurement|
          if total.nil?
            total = measurement
          else
            total += measurement
          end
        end
        report( first_label: first_label, first_id: first_id, measurements: measurements, total: total )
      end

      def source
        @source ||= valid_restricted_vocab( @cfg_hash[:user][:source], var: :source, vocab: %w[DBDv1 DBDv2] )
      end

      def timestamp_now
        Time.now.to_formatted_s(:db )
      end

      def update_cc_attribute( curation_concern:, attribute:, value: )
        curation_concern[attribute] = value
      end

      def update_collection( collection:,
                             creator:,
                             curation_notes_admin:,
                             curation_notes_user:,
                             date_created:,
                             date_modified:,
                             date_uploaded:,
                             description:,
                             keyword:,
                             language:,
                             methodology:,
                             prior_identifier:,
                             referenced_by:,
                             resource_type:,
                             subject_discipline:,
                             title: )

        # TODO: provenance
        update_cc_attribute( curation_concern: collection, attribute: :creator, value: creator )
        update_cc_attribute( curation_concern: collection, attribute: :curation_notes_admin, value: curation_notes_admin )
        update_cc_attribute( curation_concern: collection, attribute: :curation_notes_user, value: curation_notes_user )
        update_cc_attribute( curation_concern: collection, attribute: :date_created, value: date_created )
        update_cc_attribute( curation_concern: collection, attribute: :date_modified, value: date_modified )
        update_cc_attribute( curation_concern: collection, attribute: :date_uploaded, value: date_uploaded )
        update_cc_attribute( curation_concern: collection, attribute: :description, value: description )
        update_cc_attribute( curation_concern: collection, attribute: :keyword, value: keyword )
        update_cc_attribute( curation_concern: collection, attribute: :language, value: language )
        update_cc_attribute( curation_concern: collection, attribute: :methodology, value: methodology )
        update_cc_attribute( curation_concern: collection, attribute: :prior_identifier, value: prior_identifier )
        update_cc_attribute( curation_concern: collection, attribute: :referenced_by, value: referenced_by )
        update_cc_attribute( curation_concern: collection, attribute: :resource_type, value: resource_type )
        update_cc_attribute( curation_concern: collection, attribute: :subject_discipline, value: subject_discipline )
        update_cc_attribute( curation_concern: collection, attribute: :title, value: title )
        collection.save!
        collection.reload
        return collection
      end

      def update_edit_users( curation_concern:, edit_users: )
        return if edit_users.blank?
        user_create_users( emails: edit_users )
        curation_concern.edit_users = edit_users
      end

      def update_file_set( file_set:,
                           curation_notes_admin:,
                           curation_notes_user:,
                           date_created:,
                           date_modified:,
                           date_uploaded:,
                           prior_identifier:,
                           title: )

        # TODO: provenance
        update_cc_attribute( curation_concern: file_set, attribute: :curation_notes_admin, value: curation_notes_admin )
        update_cc_attribute( curation_concern: file_set, attribute: :curation_notes_user, value: curation_notes_user )
        update_cc_attribute( curation_concern: file_set, attribute: :date_created, value: date_created )
        update_cc_attribute( curation_concern: file_set, attribute: :date_modified, value: date_modified )
        update_cc_attribute( curation_concern: file_set, attribute: :date_uploaded, value: date_uploaded )
        update_cc_attribute( curation_concern: file_set, attribute: :prior_identifier, value: prior_identifier )
        update_cc_attribute( curation_concern: file_set, attribute: :title, value: title )
        collection.save!
        collection.reload
        return collection
      end

      def update_visibility( curation_concern:, visibility: )
        return unless visibility_curation_concern visibility
        curation_concern.visibility = visibility
      end

      def update_work( work:,
                       authoremail:,
                       contributor:,
                       creator:,
                       curation_notes_admin:,
                       curation_notes_user:,
                       date_coverage:,
                       date_created:,
                       date_modified:,
                       date_uploaded:,
                       description:,
                       fundedby:,
                       fundedby_other:,
                       grantnumber:,
                       keyword:,
                       language:,
                       methodology:,
                       prior_identifier:,
                       referenced_by:,
                       resource_type:,
                       rights_license:,
                       rights_license_other:,
                       subject_discipline:,
                       title: )

        # TODO: provenance
        update_cc_attribute( curation_concern: work, attribute: :authoremail, value: authoremail )
        update_cc_attribute( curation_concern: work, attribute: :contributor, value: contributor )
        update_cc_attribute( curation_concern: work, attribute: :creator, value: creator )
        update_cc_attribute( curation_concern: work, attribute: :curation_notes_admin, value: curation_notes_admin )
        update_cc_attribute( curation_concern: work, attribute: :curation_notes_user, value: curation_notes_user )
        update_cc_attribute( curation_concern: work, attribute: :date_coverage, value: date_coverage )
        update_cc_attribute( curation_concern: work, attribute: :date_created, value: date_created )
        update_cc_attribute( curation_concern: work, attribute: :date_modified, value: date_modified )
        update_cc_attribute( curation_concern: work, attribute: :date_uploaded, value: date_uploaded )
        update_cc_attribute( curation_concern: work, attribute: :description, value: description )
        update_cc_attribute( curation_concern: work, attribute: :fundedby, value: fundedby )
        update_cc_attribute( curation_concern: work, attribute: :fundedby_other, value: fundedby_other )
        update_cc_attribute( curation_concern: work, attribute: :grantnumber, value: grantnumber )
        update_cc_attribute( curation_concern: work, attribute: :keyword, value: keyword )
        update_cc_attribute( curation_concern: work, attribute: :language, value: language )
        update_cc_attribute( curation_concern: work, attribute: :methodology, value: methodology )
        update_cc_attribute( curation_concern: work, attribute: :prior_identifier, value: prior_identifier )
        update_cc_attribute( curation_concern: work, attribute: :referenced_by, value: referenced_by )
        update_cc_attribute( curation_concern: work, attribute: :resource_type, value: resource_type )
        update_cc_attribute( curation_concern: work, attribute: :rights_license, value: rights_license )
        update_cc_attribute( curation_concern: work, attribute: :rights_license_other, value: rights_license_other )
        update_cc_attribute( curation_concern: work, attribute: :subject_discipline, value: subject_discipline )
        update_cc_attribute( curation_concern: work, attribute: :title, value: title )
        work.save!
        work.reload
        return work
      end

      def upload_file_to_file_set( file_set, file )
        Hydra::Works::UploadFileToFileSet.call( file_set, file )
        return true
      rescue Ldp::Conflict
        return false
      end

      def users
        @users ||= users_from_hash( hash: @cfg_hash[:user] )
      end

      def user_create_users( emails:, password: 'password' )
        return unless user_create
        return if emails.blank?
        emails = Array( emails )
        emails.each do |email|
          next if User.find_by_user_key( email ).present?
          User.create!( email: email, password: password, password_confirmation: password )
          log_msg( "Creating user: #{email}" )
        end
      end

      def users_from_hash( hash: )
        [hash[:users]]
      end

      def user_key
        # TODO: validate the email
        @cfg_hash[:user][:email]
      end

      # config needs default user to attribute collections/works/filesets to
      # User needs to have only works or collections
      def validate_config
        # if @cfg_hash.keys != [:user]
        unless @cfg_hash.key?( :user )
          raise TaskConfigError, "Top level keys needs to contain 'user'"
        end
        # rubocop:disable Style/GuardClause
        if (@cfg_hash[:user].keys <=> %i[collections works]) < 1
          raise TaskConfigError, "user can only contain collections and works"
        end
        # rubocop:enable Style/GuardClause
      end

      def valid_restricted_vocab( value, var:, vocab:, error_class: RestrictedVocabularyError )
        unless vocab.include? value
          raise error_class, "Illegal value '#{value}' #{var}, must be one of #{vocab}"
        end
        return value
      end

      def visibility
        @visibility ||= visibility_curation_concern( @cfg_hash[:user][:visibility] )
      end

      def visibility_curation_concern( vis )
        return valid_restricted_vocab( vis,
                                       var: :visibility,
                                       vocab: %w[open restricted],
                                       error_class: VisibilityError )
      end

      def visibility_from_hash( hash: )
        vis = hash[:visibility]
        return visibility_curation_concern( vis ) if vis.present?
        visibility
      end

      def works
        @works ||= works_from_hash( hash: @cfg_hash[:user] )
      end

      def works_from_hash( hash: )
        [hash[:works]]
      end

      def works_from_id( hash:, work_id: )
        id_key = "works_#{work_id}".to_sym
        # puts "id_key=#{id_key}"
        hash[id_key]
      end

  end

end
