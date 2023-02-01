# frozen_string_literal: true

require 'hydra/file_characterization'
require_relative '../../../lib/tasks/task_helper'
require_relative '../../../lib/tasks/task_logger'
# require_relative '../../app/helpers/deepblue/email_helper'
require_relative './ingest_integration_service'

Hydra::FileCharacterization::Characterizers::Fits.tool_path = `which fits || which fits.sh`.strip

module Deepblue

  # NOTE: old visibility does not translate directly to new visibility, so diffing / updating visibility has issues
  # NOTE: see Vocab::FedoraResourceStatus for state values and Hyrax::Suppressible

  # see: http://ruby-doc.org/stdlib-2.0.0/libdoc/benchmark/rdoc/Benchmark.html
  require 'benchmark'
  include Benchmark

  # rubocop:disable Rails/Output
  class NewContentService2

    mattr_accessor :new_content_service_debug_verbose,
                   default: ::Deepblue::IngestIntegrationService.new_content_service_debug_verbose

    DEFAULT_DATA_SET_ADMIN_SET_NAME = Rails.configuration.data_set_admin_set_title unless const_defined? :DEFAULT_DATA_SET_ADMIN_SET_NAME
    DEFAULT_DIFF_ATTRS_SKIP = [ :creator_ordered,
                                :curation_notes_admin_ordered, :curation_notes_user_ordered,
                                :date_created, :date_modified,
                                :description_ordered,
                                :keyword_ordered, :language_ordered,
                                :methodology_ordered,
                                :referenced_by_ordered, :title_ordered,
                                :visibility ].freeze unless const_defined? :DEFAULT_DIFF_ATTRS_SKIP
    DEFAULT_DIFF_ATTRS_SKIP_IF_BLANK = [ :creator_ordered,
                                         :curation_notes_admin, :curation_notes_admin_ordered,
                                         :curation_notes_user, :curation_notes_user_ordered,
                                         :checksum_algorithm, :checksum_value,
                                         :date_published,
                                         :description_ordered,
                                         :doi,
                                         :fundedby_other,
                                         :keyword_ordered, :language_ordered,
                                         :methodology_ordered,
                                         :prior_identifier,
                                         :referenced_by_ordered, :title_ordered ].freeze unless const_defined? :DEFAULT_DIFF_ATTRS_SKIP_IF_BLANK
    DEFAULT_DIFF_USER_ATTRS_SKIP = [ :created_at,
                                     :current_sign_in_at, :current_sign_in_ip,
                                     :email, :encrypted_password,
                                     :id,
                                     :updated_at ].freeze unless const_defined? :DEFAULT_DIFF_USER_ATTRS_SKIP
    DEFAULT_DIFF_COLLECTIONS_RECURSE = false unless const_defined? :DEFAULT_DIFF_COLLECTIONS_RECURSE
    DEFAULT_EMAIL_AFTER = false unless const_defined? :DEFAULT_EMAIL_AFTER
    DEFAULT_EMAIL_AFTER_ADD_LOG_MSGS = true unless const_defined? :DEFAULT_EMAIL_AFTER_ADD_LOG_MSGS
    DEFAULT_EMAIL_BEFORE = false unless const_defined? :DEFAULT_EMAIL_BEFORE
    DEFAULT_EMAIL_EACH = false unless const_defined? :DEFAULT_EMAIL_EACH
    DEFAULT_EMAIL_DEPOSITOR = false unless const_defined? :DEFAULT_EMAIL_DEPOSITOR
    DEFAULT_EMAIL_INGESTER = false unless const_defined? :DEFAULT_EMAIL_INGESTER
    DEFAULT_EMAIL_OWNER = false unless const_defined? :DEFAULT_EMAIL_OWNER
    DEFAULT_EMAIL_REST = false unless const_defined? :DEFAULT_EMAIL_REST
    DEFAULT_EMAIL_TEST_MODE = false unless const_defined? :DEFAULT_EMAIL_TEST_MODE
    DEFAULT_SKIP_ADDING_PRIOR_IDENTIFIER = true unless const_defined? :DEFAULT_SKIP_ADDING_PRIOR_IDENTIFIER
    DEFAULT_UPDATE_ADD_FILES = true unless const_defined? :DEFAULT_UPDATE_ADD_FILES
    DEFAULT_UPDATE_ATTRS_SKIP = [ :creator_ordered,
                                  :curation_notes_admin_ordered, :curation_notes_user_ordered,
                                  :date_created, :date_modified, :date_uploaded,
                                  :edit_users,
                                  :read_users,
                                  :keyword_ordered, :language_ordered,
                                  :original_name,
                                  :referenced_by_ordered, :title_ordered,
                                  :visibility ].freeze unless const_defined? :DEFAULT_UPDATE_ATTRS_SKIP
    DEFAULT_UPDATE_ATTRS_SKIP_IF_BLANK = [ :creator_ordered, :curation_notes_admin, :curation_notes_admin_ordered,
                                           :curation_notes_user, :curation_notes_user_ordered,
                                           :checksum_algorithm, :checksum_value,
                                           :description_ordered, :doi,
                                           :fundedby_other, :keyword_ordered, :language_ordered,
                                           :methodology_ordered,
                                           :prior_identifier,
                                           :referenced_by_ordered, :title_ordered ].freeze unless const_defined? :DEFAULT_UPDATE_ATTRS_SKIP_IF_BLANK
    DEFAULT_UPDATE_COLLECTIONS_RECURSE = false unless const_defined? :DEFAULT_UPDATE_COLLECTIONS_RECURSE
    DEFAULT_UPDATE_DELETE_FILES = true unless const_defined? :DEFAULT_UPDATE_DELETE_FILES
    DEFAULT_UPDATE_USER_ATTRS_SKIP = [ :created_at,
                                       :current_sign_in_at, :current_sign_in_ip,
                                       :email, :encrypted_password,
                                       :id,
                                       :updated_at ].freeze unless const_defined? :DEFAULT_UPDATE_USER_ATTRS_SKIP
    DEFAULT_USER_CREATE = true unless const_defined? :DEFAULT_USER_CREATE
    DEFAULT_VERBOSE = true unless const_defined? :DEFAULT_VERBOSE
    DIFF_DATES = false unless const_defined? :DIFF_DATES
    MODE_APPEND = 'append' unless const_defined? :MODE_APPEND
    MODE_BUILD = 'build' unless const_defined? :MODE_BUILD
    MODE_DIFF = 'diff' unless const_defined? :MODE_DIFF
    MODE_MIGRATE = 'migrate' unless const_defined? :MODE_MIGRATE
    MODE_UPDATE = 'update' unless const_defined? :MODE_UPDATE
    # DEFAULT_UPDATE_BUILD_MODE = MODE_BUILD unless const_defined? :DEFAULT_UPDATE_BUILD_MODE
    DEFAULT_UPDATE_BUILD_MODE = MODE_MIGRATE unless const_defined? :DEFAULT_UPDATE_BUILD_MODE
    SOURCE_DBDv1 = 'DBDv1' unless const_defined? :SOURCE_DBDv1 # rubocop:disable Style/ConstantName
    SOURCE_DBDv2 = 'DBDv2' unless const_defined? :SOURCE_DBDv2 # rubocop:disable Style/ConstantName
    STOP_NEW_CONTENT_SERVICE_FILE_NAME = 'stop_umrdr_new_content' unless const_defined? :STOP_NEW_CONTENT_SERVICE_FILE_NAME

    class RestrictedVocabularyError < RuntimeError
    end

    class StateError < RuntimeError
    end

    class ConfigError < RuntimeError
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
                :diff_attrs_skip,
                :diff_attrs_skip_if_blank,
                :diff_user_attrs_skip,
                :diff_collections_recurse,
                :email_after,
                :email_after_add_log_msgs,
                :email_after_msg_lines,
                :email_before,
                :email_each,
                :email_depositor,
                :email_ingester,
                :email_owner,
                :email_rest,
                :email_test_mode,
                :emails_after,
                :emails_before,
                :emails_rest,
                :ingest_id,
                :ingest_timestamp,
                :ingest_urls,
                :ingester,
                :mode,
                :options,
                :path_to_yaml_file,
                :skip_adding_prior_identifier,
                :update_add_files,
                :update_attrs_skip,
                :update_attrs_skip_if_blank,
                :update_user_attrs_skip,
                :update_build_mode,
                :update_collections_recurse,
                :update_delete_files,
                :user,
                :user_create,
                :verbose

    def initialize( path_to_yaml_file:, cfg_hash:, base_path:, options: )
      initialize_with_msg( options: options,
                           path_to_yaml_file: path_to_yaml_file,
                           cfg_hash: cfg_hash,
                           base_path: base_path )
    end

    def self.load_yaml_file( path_to_yaml_file )
      if File.exist? path_to_yaml_file
        cfg_hash = YAML.load_file( path_to_yaml_file )
        return cfg_hash
      else
        puts "yaml file not found: ' #{path_to_yaml_file}'"
        Rails.logger.error "yaml file not found: ' #{path_to_yaml_file}'"
        return nil
      end
    end

    def run
      validate_config
      build_repo_contents
    rescue RestrictedVocabularyError => e
      logger.error e.message.to_s
    rescue ConfigError => e
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
        # TODO: probably should lock the work here.
        work.reload
        work.ordered_members << file_set
        log_provenance_add_child( parent: work, child: file_set )
        work.total_file_size_add_file_set file_set
        work.representative = file_set if work.representative_id.blank?
        work.thumbnail = file_set if work.thumbnail_id.blank?
        work.save!
      rescue Exception => e # rubocop:disable Lint/RescueException
        log_error "#{e.class} work.id=#{work.id} -- #{file_set&.id} -- #{e.message} at #{e.backtrace[0]}"
        ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "new_content_service_error",
                                               "work.id=#{work.id}",
                                               "file_set.id=#{file_set&.id}",
                                               "e=#{e.class.name}",
                                               "e.message=#{e.message}",
                                               "e.backtrace:" ] + e.backtrace[0..25]
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
                                               file_size: file_size,
                                               build_mode: mode )
          next if file_set.blank?
          add_file_set_to_work( work: work, file_set: file_set )
          # TODO: move ingest step here, this will probably fix file_sets that turn up with missing file sizes
        end
        work.save!
        work.reload
        valid_or_fix_file_sizes( curation_concern: work )
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
          next if fs.blank?
          add_file_set_to_work( work: work, file_set: fs )
          # TODO: move ingest step here, this will probably fix file_sets that turn up with missing file sizes
        end
        work.save!
        work.reload
        valid_or_fix_file_sizes( curation_concern: work )
        return work
      end

    def msg_handler_null
      @msg_handler ||= ::Deepblue::MessageHandlerNull.new
    end

    def valid_or_fix_file_sizes( curation_concern: )
      return unless curation_concern.is_a? DataSet
      return if ::Deepblue::FindAndFixHelper.valid_file_sizes?( curation_concern: curation_concern,
                                                                msg_handler: msg_handler_null )
      ::Deepblue::FindAndFixHelper.fix_file_sizes( curation_concern: curation_concern,
                                                   msg_handler: msg_handler_null  )
    end

      def add_measurement( measurement )
        measurements << measurement
      end

      def add_works_to_collection( collection_hash:, collection: )
        # puts "collection_hash=#{collection_hash}"
        work_ids = works_from_hash( hash: collection_hash )
        return collection if work_ids.blank?
        work_ids[0].each do |work_id|
          next unless continue_new_content_service
          # puts "work_id=#{work_id}"
          work_hash = work_hash_from_id( parent_hash: collection_hash, work_id: work_id.to_s )
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

      def add_work_to_parent_ids( work_hash:, work: )
        in_collections = work_hash[:in_collections]
        return if in_collections.blank?
        in_collections.each do |collection_id|
          begin
            next if work.member_of_collection_ids.include? collection_id
            collection = Collection.find( collection_id )
            next unless collection.present? # TODO: report error
            work.member_of_collections << collection
            log_provenance_add_child( parent: collection, child: work )
            work.save!
          rescue Hyrax::ObjectNotFoundError
            puts "Collection #{collection_id} not found. Unable to add work #{work.id} to it."
          end
        end
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
        work.state = state_from_hash( hash: work_hash )
        work.visibility = visibility_from_hash( hash: work_hash )
        work.admin_set = admin_set
        # puts "work.id=#{work.id} admin_set.id=#{admin_set.id} visibility=#{work.visibility}"
        return if TaskHelper.dbd_version_1?
        return unless admin_set_data_set? admin_set
        if work.id.nil?
          work.save!
          work.reload
        end
        # entity = work.workflow_state
        wgid = work.to_global_id.to_s
        entity = Sipity::Entity.where( proxy_for_global_id: wgid )
        # puts "entity=#{entity}"
        # puts "entity.class.name=#{entity.class.name}"
        entity = entity.first if entity.is_a? ActiveRecord::Relation
        wf = work.active_workflow
        entity = Sipity::Entity.create!( proxy_for_global_id: wgid, workflow: wf, workflow_state: nil ) if entity.nil?
        # puts "entity=#{entity}"
        # puts "entity.class.name=#{entity.class.name}"
        # puts "wf.name=#{wf.name}"
        action_name = work_hash[:workflow_state]
        if action_name.blank?
          action_name = if "open" == work.visibility
                          "deposited"
                        else
                          "pending_review"
                        end
        end
        # puts "action_name=#{action_name}"
        action = Sipity::WorkflowAction.find_or_create_by!( workflow: wf, name: action_name )
        wf_state = Sipity::WorkflowState.find_or_create_by!( workflow: wf, name: action_name )
        entity.update!( workflow_state_id: action.id, workflow_state: wf_state )
        log_provenance_workflow( curation_concern: work, workflow: wf, workflow_state: action_name )
      end

      def attr_prefix( cc_or_fs )
        return "file #{cc_or_fs.id}" if cc_or_fs.is_a? FileSet
        return "coll #{cc_or_fs.id}" if cc_or_fs.is_a? Collection
        return "work #{cc_or_fs.id}"
      end

      def build_admin_set_work( hash: )
        return admin_set_work
        # TODO: resolve the issue that we really don't normally need to create admin sets
        admin_set_id = hash[:admin_set_id]
        # TODO: admin_set_title = hash[:admin_set_title]
        return admin_set_work if admin_set_id.blank?
        return admin_set_work if AdminSet.default_set? admin_set_id
        begin
          admin_set = AdminSet.find( admin_set_id )
        rescue Hyrax::ObjectNotFoundError
          # TODO: Log this
          admin_set = admin_set_work
        rescue Ldp::Gone
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
        # date_created = build_date( hash: collection_hash, key: :date_created )
        date_created = Array( build_date( hash: collection_hash, key: :date_created ) ) # update for hyrax v3
        date_modified = build_date( hash: collection_hash, key: :date_modified )
        date_uploaded = build_date( hash: collection_hash, key: :date_uploaded )
        description = Array( collection_hash[:description] )
        description = ["Missing description"] if description.blank?
        description = ["Missing description"] if [nil] == description
        doi = build_doi( hash: collection_hash )
        edit_users = Array( collection_hash[:edit_users] )
        read_users = Array( collection_hash[:read_users] )
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
                                     doi: doi,
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
        update_cc_edit_users(curation_concern: collection, edit_users: edit_users )
        update_cc_read_users(curation_concern: collection, read_users: read_users )
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

      def build_date( hash:, key:, no_default: false )
        rv = hash[key]
        return build_date_now( no_default: no_default ) if rv.blank?
        rv = rv[0] if rv.is_a? Array
        return rv if rv.is_a? DateTime
        return rv if rv.is_a? Time
        rv = DateTime.parse rv
        return rv
      rescue ArgumentError
        return build_date2( rv, key: key, no_default: no_default )
      end

      def build_date2( str, key:, no_default: )
        return DateTime.strptime( str, "%m/%d/%Y" ) if str.match?( /\d\d?\/\d\d?\/\d\d\d\d/ )
        return DateTime.strptime( str, "%m-%d-%Y" ) if str.match?( /\d\d?\-\d\d?\-\d\d\d\d/ )
        return DateTime.strptime( str, "%Y" ) if str.match?( /\d\d\d\d/ )
        return build_date_now( no_default: no_default )
      rescue ArgumentError
        log_msg( "Failed to parse data string '#{str}' for key '#{key}'" )
        return build_date_now( no_default: no_default )
      end

      def build_date_now( no_default: )
        return nil if no_default
        return DateTime.now
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

      def build_doi( hash: )
        doi = hash[:doi]
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "doi=#{doi}",
                                               "" ] if new_content_service_debug_verbose
        doi = nil if ::Deepblue::DoiMintingService::DOI_MINT_NOW == doi
        return doi
      end

      def build_file_set( id:,
                          path:,
                          work:,
                          filename: nil,
                          file_ids: nil,
                          file_set_of:,
                          file_set_count:,
                          file_size: '' )

        file_set = nil
        begin
          # puts "id=#{id} path=#{path} filename=#{filename} file_ids=#{file_ids}"
          log_msg( "#{mode}: building file #{file_set_of} of #{file_set_count}#{file_size}" ) if @verbose
          fname = filename || File.basename( path )
          file_set = build_file_set_new( id: id,
                                         depositor: work.depositor,
                                         path: path,
                                         original_name: fname,
                                         build_mode: mode,
                                         current_user: user_key )
          file_set.title = Array( fname )
          file_set.label = fname
          now = DateTime.now.new_offset( 0 )
          file_set.date_uploaded = now
          file_set.visibility = work.visibility
          # file_set.owner = work.owner
          file_set.depositor = work.depositor
          file_set.prior_identifier = file_ids if file_ids.present?
          file_set.save!
          # TODO: move ingest step to after attach to work, this will probably fix file_sets that turn up with missing file sizes
          rv = build_file_set_ingest( file_set: file_set,
                                      path: path,
                                      checksum_algorithm: nil,
                                      checksum_value: nil,
                                      build_mode: mode )
          return file_set
        rescue Exception => e # rubocop:disable Lint/RescueException
          log_error "#{e.class} work.id=#{work.id} -- #{file_set&.id} -- #{e.message} at #{e.backtrace[0]}"
          ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "new_content_service_error",
                                                 "work.id=#{work.id}",
                                                 "file_set.id=#{file_set&.id}",
                                                 "e=#{e.class.name}",
                                                 "e.message=#{e.message}",
                                                 "e.backtrace:" ] + e.backtrace[0..25]
          return file_set
        end
      end

      def build_file_set_from_hash( id:,
                                    file_set_hash:,
                                    parent:,
                                    file_set_of:,
                                    file_set_count:,
                                    file_size: '',
                                    build_mode: )

        if MODE_APPEND == build_mode && id.present?
          file_set = find_file_set_using_prior_id( prior_id: id, parent: parent )
          log_msg( "#{build_mode}: found file_set with prior id: #{id} title: #{file_set.title.first}" ) if file_set.present?
          return file_set if file_set.present?
        end
        if MODE_MIGRATE == build_mode && id.present?
          file_set = find_file_set_using_id( id: id )
          log_msg( "#{build_mode}: found file_set with id: #{id} title: #{file_set.title.first}" ) if file_set.present?
          return file_set if file_set.present?
        end
        log_msg( "#{build_mode}: building file #{file_set_of} of #{file_set_count}#{file_size}" ) if @verbose
        file_set = nil
        begin
          # puts "id=#{id} path=#{path} filename=#{filename} file_ids=#{file_ids}"
          depositor = build_depositor( hash: file_set_hash )
          path = file_set_hash[:file_path]
          original_name = file_set_hash[:original_name]
          file_set = build_file_set_new( id: id,
                                         depositor: depositor,
                                         path: path,
                                         original_name: original_name,
                                         build_mode: build_mode,
                                         current_user: user_key )

          curation_notes_admin = Array( file_set_hash[:curation_notes_admin] )
          curation_notes_user = Array( file_set_hash[:curation_notes_user] )
          checksum_algorithm = file_set_hash[:checksum_algorithm]
          checksum_value = file_set_hash[:checksum_value]
          date_created = Array( build_date( hash: file_set_hash, key: :date_created ) )
          date_modified = build_date( hash: file_set_hash, key: :date_modified )
          date_uploaded = build_date( hash: file_set_hash, key: :date_uploaded )
          description_file_set = file_set_hash[:description_file_set]
          doi = build_doi( hash: file_set_hash )
          edit_users = Array( file_set_hash[:edit_users] )
          read_users = Array( file_set_hash[:read_users] )
          label = file_set_hash[:label]
          prior_identifier = build_prior_identifier( hash: file_set_hash, id: id )
          title = Array( file_set_hash[:title] )
          visibility = visibility_from_hash( hash: file_set_hash )

          update_cc_attribute( curation_concern: file_set, attribute: :title, value: title )
          update_cc_attribute( curation_concern: file_set,
                               attribute: :curation_notes_admin,
                               value: curation_notes_admin )
          update_cc_attribute( curation_concern: file_set,
                               attribute: :curation_notes_user,
                               value: curation_notes_user )
          file_set.label = label
          file_set.date_uploaded = date_uploaded
          file_set.date_modified = date_modified
          file_set.date_created = date_created
          update_cc_attribute( curation_concern: file_set, attribute: :description_file_set, value: description_file_set )
          update_cc_attribute( curation_concern: file_set, attribute: :doi, value: doi )
          update_cc_edit_users(curation_concern: file_set, edit_users: edit_users )
          update_cc_read_users(curation_concern: file_set, read_users: read_users )
          update_cc_attribute( curation_concern: file_set, attribute: :prior_identifier, value: prior_identifier )
          update_visibility( curation_concern: file_set, visibility: visibility )
          file_set.date_modified = file_set.date_uploaded if file_set.date_modified.blank?
          file_set.date_modified = DateTime.now if file_set.date_modified.blank?
          file_set.save!
          # TODO: move ingest step to after attach to work, this will probably fix file_sets that turn up with missing file sizes
          return build_file_set_ingest( file_set: file_set,
                                        path: path,
                                        checksum_algorithm: checksum_algorithm,
                                        checksum_value: checksum_value,
                                        build_mode: build_mode )
        rescue Exception => e # rubocop:disable Lint/RescueException
          log_error "#{e.class} work.id=#{work.id} -- #{file_set&.id} -- #{e.message} at #{e.backtrace[0]}"
          ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "new_content_service_error",
                                                 "parent.id=#{parent.id}",
                                                 "file_set.id=#{file_set&.id}",
                                                 "e=#{e.class.name}",
                                                 "e.message=#{e.message}",
                                                 "e.backtrace:" ] + e.backtrace[0..25]
          return file_set
        end
      end

      def build_file_set_ingest( file_set:, path:, checksum_algorithm:, checksum_value:, build_mode: )
        log_object file_set
        log_provenance_migrate( curation_concern: file_set ) if MODE_MIGRATE == build_mode
        repository_file_id = nil
        job_status = IngestJobStatus.null_ingest_job_status # TODO: can use actual JobStatus to return messages and errors
        IngestHelper.characterize( file_set,
                                   repository_file_id,
                                   path,
                                   delete_input_file: false,
                                   continue_job_chain: false,
                                   current_user: user,
                                   job_status: job_status,
                                   ingest_id: ingest_id,
                                   ingester: ingester,
                                   ingest_timestamp: ingest_timestamp )
        IngestHelper.create_derivatives( file_set,
                                         repository_file_id,
                                         path,
                                         delete_input_file: false,
                                         current_user: user,
                                         job_status: job_status,
                                         ingest_id: ingest_id,
                                         ingester: ingester,
                                         ingest_timestamp: ingest_timestamp )
        log_provenance_ingest( curation_concern: file_set )
        if checksum_algorithm.present? && checksum_value.present?
          checksum = file_set_checksum( file_set: file_set )
          log_msg( "#{build_mode}: file checksum is nil" ) if checksum.blank?
          if checksum.present? && checksum.algorithm == checksum_algorithm
            if checksum.value == checksum_value
              log_msg( "#{build_mode}: checksum succeeded: #{checksum_value}" )
              log_provenance_fixity_check( curation_concern: file_set,
                                           fixity_check_status: 'success',
                                           fixity_check_note: '' )
            else
              msg = "#{checksum.value} vs #{checksum_value}"
              log_msg( "#{build_mode}: WARNING checksum failed: #{msg}" )
              log_provenance_fixity_check( curation_concern: file_set,
                                           fixity_check_status: 'failed',
                                           fixity_check_note: msg )
            end
          else
            msg = "incompatible checksum algorithms: #{checksum.algorithm} vs #{checksum_algorithm}"
            log_msg( "#{build_mode}: #{msg}" )
            log_provenance_fixity_check( curation_concern: file_set,
                                         fixity_check_status: 'failed',
                                         fixity_check_note: msg )
          end
        end
        file_set.date_modified = file_set.date_uploaded if file_set.date_modified.blank?
        file_set.date_modified = DateTime.now if file_set.date_modified.blank?
        log_msg( "#{build_mode}: finished: #{path}" )
        return file_set
      end

      def build_file_set_new( id:, depositor:, path:, original_name:, build_mode:, current_user: )
        log_msg( "#{build_mode}: processing: #{path}" )
        file = File.open( path )
        # fix so that filename comes from the name of the file and not the hash
        file.define_singleton_method( :original_name ) do
          original_name
        end
        file.define_singleton_method( :current_user ) do
          current_user
        end
        id_new = MODE_MIGRATE == build_mode ? id : nil
        file_set = new_file_set( id: id_new )
        file_set.apply_depositor_metadata( depositor )
        upload_file_to_file_set( file_set, file )
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
        doi_mint( curation_concern: collection )
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
        work = find_work_using_id( id ) if MODE_APPEND == mode
        work = build_work( id: id, work_hash: work_hash, parent: parent ) if work.nil?
        return nil if work.nil?
        log_object work if work.present?
        add_file_sets_to_work( work_hash: work_hash, work: work )
        add_work_to_parent_ids( work_hash: work_hash, work: work )
        doi_mint( curation_concern: work )
        @ingest_urls << work.data_set_url if work.present?
        return work
      end

      def build_prior_identifier( hash:, id: )
        if SOURCE_DBDv1 == source
          if MODE_MIGRATE == mode || skip_adding_prior_identifier
            []
          else
            Array( id )
          end
        else
          arr = Array( hash[:prior_identifier] )
          return arr if MODE_MIGRATE == mode
          return arr if skip_adding_prior_identifier
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

      def build_time( value: )
        return '' if value.nil?
        rv = value
        return rv if rv.is_a? Time
        rv = Time.parse value
      rescue ArgumentError
        return ''
      end

      def build_user( user_hash: )
        email = user_hash[:email]
        log_msg( "User.new( #{email} )" )
        user = User.new( email: email, password: 'password' ) { |u| u.save( validate: false ) }
        update_user( user: user, user_hash: user_hash )
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
        # date_created = build_date( hash: work_hash, key: :date_created )
        date_created = Array( build_date( hash: work_hash, key: :date_created ) ) # update for hyrax v3
        date_modified = build_date( hash: work_hash, key: :date_modified )
        date_published = build_date( hash: work_hash, key: :date_published )
        date_uploaded = build_date( hash: work_hash, key: :date_uploaded )
        description = Array( work_hash[:description] )
        description = ["Missing description"] if description.blank?
        description = ["Missing description"] if [nil] == description
        doi = build_doi( hash: work_hash )
        edit_users = Array( work_hash[:edit_users] )
        read_users = Array( work_hash[:read_users] )
        fundedby = build_fundedby( hash: work_hash )
        fundedby_other = work_hash[:fundedby_other]
        grantnumber = work_hash[:grantnumber]
        language = Array( work_hash[:language] )
        keyword = Array( work_hash[:keyword] )
        methodology = Array( work_hash[:methodology] )
        methodology = [ "No Methodology Available" ] unless methodology.present?
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
                             date_published: date_published,
                             date_uploaded: date_uploaded,
                             description: description,
                             doi: doi,
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
        update_cc_edit_users(curation_concern: work, edit_users: edit_users )
        update_cc_read_users(curation_concern: work, read_users: read_users )
        work.owner = depositor
        admin_set = build_admin_set_work( hash: work_hash )
        work.update( admin_set: admin_set )
        apply_visibility_and_workflow( work: work, work_hash: work_hash, admin_set: admin_set )
        log_msg( "About to save work #{title}", timestamp_it: true ) if verbose
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
          end
          next if work.blank?
          measurement.instance_variable_set( :@label, work_id )
          add_measurement measurement
        end
      end

      def collections
        @collections ||= collections_from_hash( hash: user_hash )
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

      def diff_attr( diffs, cc_or_fs, cc_or_fs_hash, attr_name:, attr_name_hash: nil, multi: true )
        return diffs unless diff_attr? attr_name
        attr_current = cc_or_fs[attr_name]
        value = cc_or_fs_hash[attr_name] if attr_name_hash.blank?
        value = cc_or_fs_hash[attr_name_hash] if attr_name_hash.present?
        value = Array( value ) if multi
        if attr_current.is_a?( Time )
          attr_current = attr_current.change(usec: 0)
          value = build_time( value: value )
          value = value.change(usec: 0) if value.is_a? Time
        end
        return diffs unless diff_attr_if_blank?( attr_name, value: value )
        return diffs if attr_current == value
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} '#{attr_current}' vs. '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def diff_attr?( attr_name, parent: nil )
        return false if diff_attrs_skip.include? attr_name
        return true
      end

      def diff_attr_if_blank?( attr_name, value:, parent: nil )
        return false if value.blank? && diff_attrs_skip_if_blank.include?( attr_name )
        return true
      end

      def diff_attr_value( diffs, cc_or_fs, attr_name:, value: nil, multi: true )
        return diffs unless diff_attr? attr_name
        return diffs unless diff_attr_if_blank?( attr_name, value: value )
        attr_current = cc_or_fs[attr_name]
        return diffs if attr_current == value
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} '#{attr_current}' vs. '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def diff_collection( diffs: nil, collection:, collection_hash: )
        diffs = [] if diffs.nil?
        diff_attr( diffs, collection, collection_hash, attr_name: :creator )
        diff_attr( diffs, collection, collection_hash, attr_name: :creator_ordered, multi: false )
        diff_attr( diffs, collection, collection_hash, attr_name: :curation_notes_admin )
        diff_attr( diffs, collection, collection_hash, attr_name: :curation_notes_admin_ordered, multi: false )
        diff_attr( diffs, collection, collection_hash, attr_name: :curation_notes_user )
        diff_attr( diffs, collection, collection_hash, attr_name: :curation_notes_user_ordered, multi: false )
        diff_attr_value( diffs, collection, attr_name: :date_created, value: build_date( hash: collection_hash, key: :date_created ) )
        diff_attr_value( diffs, collection, attr_name: :date_modified, value: build_date( hash: collection_hash, key: :date_modified ) )
        diff_attr_value( diffs, collection, attr_name: :date_uploaded, value: build_date( hash: collection_hash, key: :date_uploaded ) )
        depositor = build_depositor( hash: collection_hash )
        diff_attr_value( diffs, collection, attr_name: :depositor, value: depositor )
        description = Array( collection_hash[:description] )
        description = ["Missing description"] if description.blank?
        description = ["Missing description"] if [nil] == description
        diff_attr_value( diffs, collection, attr_name: :description, value: description )
        diff_attr( diffs, collection, collection_hash, attr_name: :description_ordered, multi: false )
        diff_attr( diffs, collection, collection_hash, attr_name: :doi, multi: false )
        diff_edit_users( diffs, collection, collection_hash )
        diff_read_users( diffs, collection, collection_hash )
        diff_attr( diffs, collection, collection_hash, attr_name: :keyword )
        diff_attr( diffs, collection, collection_hash, attr_name: :keyword_ordered, multi: false )
        diff_attr( diffs, collection, collection_hash, attr_name: :language )
        diff_attr( diffs, collection, collection_hash, attr_name: :language_ordered, multi: false )
        diff_attr( diffs, collection, collection_hash, attr_name: :prior_identifier )
        diff_attr_value( diffs, collection, attr_name: :referenced_by, value: build_referenced_by( hash: collection_hash ) )
        resource_type = Array( collection_hash[:resource_type] || 'Collection' )
        diff_attr_value( diffs, collection, attr_name: :resource_type, value: resource_type )
        diff_attr_value( diffs, collection, attr_name: :subject_discipline, value: build_subject_discipline( hash: collection_hash ) )
        diff_attr( diffs, collection, collection_hash, attr_name: :title )
        diff_attr( diffs, collection, collection_hash, attr_name: :title_ordered, multi: false )
        return diffs unless diff_collections_recurse
        diffs = diff_collection_works( diffs: diffs, collection: collection, collection_hash: collection_hash )
        return diffs
      end

      def diff_edit_users( diffs, cc_or_fs, cc_or_fs_hash )
        attr_name = :edit_users
        return diffs unless diff_attr? attr_name
        current_value = cc_or_fs.edit_users
        value = Array( cc_or_fs_hash[attr_name] )
        return diffs unless diff_attr_if_blank?( attr_name, value: value )
        xor = current_value + value - ( current_value & value )
        return diffs if xor.empty?
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} '#{current_value}' vs. '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def diff_read_users( diffs, cc_or_fs, cc_or_fs_hash )
        attr_name = :read_users
        return diffs unless diff_attr? attr_name
        current_value = cc_or_fs.read_users
        value = Array( cc_or_fs_hash[attr_name] )
        return diffs unless diff_attr_if_blank?( attr_name, value: value )
        xor = current_value + value - ( current_value & value )
        return diffs if xor.empty?
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} '#{current_value}' vs. '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def diff_collection_works( diffs:, collection:, collection_hash: )
        collection_works = {}
        collection.member_objects.each do |member|
          return diffs unless continue_new_content_service
          collection_works[member.id] = member if TaskHelper.work? member
        end
        work_ids = works_from_hash( hash: collection_hash )
        return diffs if work_ids.blank?
        work_ids[0].each do |work_id|
          return diffs unless continue_new_content_service
          if collection_works.key? work_id
            work_hash = work_hash_from_id( parent_hash: collection_hash, work_id: work_id.to_s )
            diff_work( diffs: diffs, work_hash: work_hash, work: collection_works[work_id], parent: collection )
            collection_works.delete work_id
          else
            diffs << "#{attr_prefix collection}: is missing work #{work_id}"
          end
        end
        collection_works.each_value do |work|
          return diffs unless continue_new_content_service
          diffs << "#{attr_prefix collection}: has extra work #{work.id}"
        end
        return diffs
      end

      def diff_collections
        return unless collections
        collections.each do |collection_hash|
          next unless continue_new_content_service
          collection = nil
          collection_id = 'nil'
          measurement = Benchmark.measure do
            collection, collection_id = find_collection( collection_hash: collection_hash )
            if collection.nil?
              puts "== coll #{collection_id} is missing ==" if collection_id.present?
            else
              puts "coll #{collection_id}: diff..." if verbose
              diffs = diff_collection( collection_hash: collection_hash, collection: collection )
              if diffs.present?
                puts "#{attr_prefix collection}: diffs"
                puts "#{diffs.join("\n")}"
              end
            end
          end
          next if collection.blank?
          measurement.instance_variable_set( :@label, collection_id )
          add_measurement measurement
        end
      end

      def diff_file_set( diffs:, file_set:, file_set_hash:, parent: nil )
        return diffs unless continue_new_content_service
        diff_attr( diffs, file_set, file_set_hash, attr_name: :curation_notes_admin )
        diff_attr( diffs, file_set, file_set_hash, attr_name: :curation_notes_admin_ordered, multi: false )
        diff_attr( diffs, file_set, file_set_hash, attr_name: :curation_notes_user )
        diff_attr( diffs, file_set, file_set_hash, attr_name: :curation_notes_user_ordered, multi: false )
        # diff_attr( diffs, file_set, file_set_hash, attr_name: :checksum_algorithm )
        # diff_attr( diffs, file_set, file_set_hash, attr_name: :checksum_value )
        diff_attr_value( diffs, file_set, attr_name: :date_created, value: build_date( hash: file_set_hash, key: :date_created ) )
        diff_attr_value( diffs, file_set, attr_name: :date_modified, value: build_date( hash: file_set_hash, key: :date_modified ) )
        diff_attr_value( diffs, file_set, attr_name: :date_uploaded, value: build_date( hash: file_set_hash, key: :date_uploaded ) )
        depositor = build_depositor( hash: file_set_hash )
        diff_attr_value( diffs, file_set, attr_name: :depositor, value: depositor )
        diff_attr( diffs, file_set, file_set_hash, attr_name: :description_file_set, multi: false )
        diff_edit_users( diffs, file_set, file_set_hash )
        diff_read_users( diffs, file_set, file_set_hash )
        original_name = file_set_hash[:original_name]
        diff_attr( diffs, file_set, file_set_hash, attr_name: :label, multi: false )
        diff_value_value( diffs, file_set, attr_name: :orignal_name, current_value: file_set.original_name_value, value: original_name )
        diff_attr( diffs, file_set, file_set_hash, attr_name: :prior_identifier )
        diff_attr( diffs, file_set, file_set_hash, attr_name: :title )
        diff_value_value( diffs, file_set, attr_name: :visibility, current_value: file_set.visibility, value: visibility_from_hash( hash: file_set_hash ) )
        return diffs
      end

      def diff_file_sets( diffs:, work_hash:, work: )
        file_set_ids = work_hash[:file_set_ids]
        return diff_file_sets_from_file_set_ids( diffs: diffs, work_hash: work_hash, work: work ) if file_set_ids.present?
        return diff_file_sets_from_files( diffs: diffs, work_hash: work_hash, work: work )
      end

      def diff_file_sets_from_file_set_ids( diffs:, work_hash:, work: )
        work_file_sets = {}
        work.file_sets.each do |fs|
          return diffs unless continue_new_content_service
          work_file_sets[fs.id] = fs
        end
        file_set_ids = work_hash[:file_set_ids]
        file_set_ids.each do |file_set_id|
          return diffs unless continue_new_content_service
          if work_file_sets.key? file_set_id
            file_set_key = "f_#{file_set_id}"
            file_set_hash = work_hash[file_set_key.to_sym]
            diff_file_set( diffs: diffs, file_set: work_file_sets[file_set_id], file_set_hash: file_set_hash, parent: work )
            work_file_sets.delete file_set_id
          else
            diffs << "#{attr_prefix work}: is missing file #{file_set_id}"
          end
        end
        work_file_sets.each_value do |file_set|
          return diffs unless continue_new_content_service
          diffs << "#{attr_prefix work}: has extra file #{file_set.id}"
        end
        return diffs
      end

      def diff_file_sets_from_files( diffs:, work_hash:, work: )
        # TODO
        return diffs
      end

      def diff_user( diffs: nil, user_hash:, user:, user_email: )
        diffs = [] if diffs.nil?
        return diffs unless continue_new_content_service
        attr_names = User.attribute_names
        attr_names.each do |name|
          diff_user_attr( diffs, user, user_hash, user_email, attr_name: name )
        end
        return diffs
      end

      def diff_users
        return unless users
        measurement = Benchmark.measure do
          users.each do |users_hash|
            user_emails = users_hash[:user_emails]
            next if user_emails.blank?
            # log_msg( "users_hash: #{users_hash}" ) if verbose
            user_emails.each do |user_email|
              # log_msg( "processing user: #{user_email}" ) if verbose
              user_email_id = "user_#{user_email}".to_sym
              # log_msg( "user_email_id: #{user_email_id}" ) if verbose
              user_hash = users_hash[user_email_id]
              # log_msg( "user_hash: #{user_hash}" ) if verbose
              user = find_user( user_hash: user_hash )
              if user.nil?
                puts "== user #{user_email} is missing ==" if user_email_id.present?
              else
                puts "#{user_email}: diff..." if verbose
                diffs = diff_user( user_hash: user_hash, user: user, user_email: user_email )
                if diffs.present?
                  puts "#{user_email}: diffs"
                  puts "#{diffs.join("\n")}"
                else
                  puts "#{user_email}: no differences found" if verbose
                end
              end
            end
          end
        end
        return measurement
      end

      def diff_user_attr( diffs, user, user_hash, user_email, attr_name:, attr_name_hash: nil, multi: false )
        attr_name = attr_name.to_sym if attr_name.is_a? String
        return diffs unless diff_user_attr? attr_name
        attr_current = user[attr_name]
        value = user_hash[attr_name] if attr_name_hash.blank?
        value = user_hash[attr_name_hash] if attr_name_hash.present?
        value = Array( value ) if multi
        return diffs unless diff_user_attr_if_blank?( attr_name, value: value )
        return diffs if attr_current == value
        diffs << "#{user_email}: #{attr_name} '#{attr_current}' vs. '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        diffs << "#{user_email}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def diff_user_attr?( attr_name )
        return false if diff_user_attrs_skip.include? attr_name
        return true
      end

      def diff_user_attr_if_blank?( attr_name, value:, parent: nil )
        return false if value.blank? # && diff_attrs_skip_if_blank.include?( attr_name )
        return true
      end

      def diff_value_value( diffs, cc_or_fs, attr_name:, current_value:, value: nil )
        return diffs unless diff_attr? attr_name
        return diffs unless diff_attr_if_blank?( attr_name, value: value )
        return diffs if current_value == value
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} '#{current_value}' vs. '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        diffs << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def diff_work( diffs: nil, work_hash:, work:, parent: nil )
        diffs = [] if diffs.nil?
        return diffs unless continue_new_content_service
        diff_attr( diffs, work, work_hash, attr_name: :authoremail, multi: false )
        diff_attr( diffs, work, work_hash, attr_name: :contributor )
        diff_attr( diffs, work, work_hash, attr_name: :creator )
        diff_attr( diffs, work, work_hash, attr_name: :creator_ordered, multi: false )
        diff_attr( diffs, work, work_hash, attr_name: :curation_notes_admin )
        diff_attr( diffs, work, work_hash, attr_name: :curation_notes_admin_ordered, multi: false )
        diff_attr( diffs, work, work_hash, attr_name: :curation_notes_user )
        diff_attr( diffs, work, work_hash, attr_name: :curation_notes_user_ordered, multi: false )
        diff_attr_value( diffs, work, attr_name: :date_coverage, value: build_date_coverage( hash: work_hash ) )
        diff_attr_value( diffs, work, attr_name: :date_created, value: build_date( hash: work_hash, key: :date_created ) )
        diff_attr_value( diffs, work, attr_name: :date_modified, value: build_date( hash: work_hash, key: :date_modified ) )
        diff_attr_value( diffs, work, attr_name: :date_published, value: build_date( hash: work_hash, key: :date_published ) )
        diff_attr_value( diffs, work, attr_name: :date_uploaded, value: build_date( hash: work_hash, key: :date_uploaded ) )
        depositor = build_depositor( hash: work_hash )
        diff_attr_value( diffs, work, attr_name: :depositor, value: depositor )
        description = Array( work_hash[:description] )
        description = ["Missing description"] if description.blank?
        description = ["Missing description"] if [nil] == description
        diff_attr_value( diffs, work, attr_name: :description, value: description )
        diff_attr( diffs, work, work_hash, attr_name: :description_ordered, multi: false )
        diff_attr( diffs, work, work_hash, attr_name: :doi, multi: false )
        diff_edit_users( diffs, work, work_hash )
        diff_read_users( diffs, work, work_hash )
        diff_attr_value( diffs, work, attr_name: :fundedby, value: build_fundedby( hash: work_hash ) )
        diff_attr( diffs, work, work_hash, attr_name: :fundedby_other )
        diff_attr( diffs, work, work_hash, attr_name: :grantnumber, multi: false )
        diff_attr( diffs, work, work_hash, attr_name: :keyword )
        diff_attr( diffs, work, work_hash, attr_name: :keyword_ordered, multi: false )
        diff_attr( diffs, work, work_hash, attr_name: :language )
        diff_attr( diffs, work, work_hash, attr_name: :language_ordered, multi: false )
        methodology = Array( work_hash[:methodology] )
        methodology = [ "No Methodology Available" ] unless methodology.present?
        diff_attr_value( diffs, work, attr_name: :methodology, value: methodology )
        diff_attr( diffs, work, work_hash, attr_name: :methodology_ordered, multi: false )
        diff_attr_value( diffs, work, attr_name: :owner, value: depositor )
        diff_attr( diffs, work, work_hash, attr_name: :prior_identifier )
        diff_attr_value( diffs, work, attr_name: :referenced_by, value: build_referenced_by( hash: work_hash ) )
        diff_attr( diffs, work, work_hash, attr_name: :referenced_by_ordered, multi: false )
        resource_type = Array( work_hash[:resource_type] || 'Dataset' )
        diff_attr_value( diffs, work, attr_name: :resource_type, value: resource_type )
        diff_attr_value( diffs, work, attr_name: :rights_license, value: build_rights_liscense( hash: work_hash ) )
        diff_attr( diffs, work, work_hash, attr_name: :rights_license_other, multi: false )
        diff_attr_value( diffs, work, attr_name: :subject_discipline, value: build_subject_discipline( hash: work_hash ) )
        diff_attr( diffs, work, work_hash, attr_name: :title )
        diff_attr( diffs, work, work_hash, attr_name: :title_ordered, multi: false )
        diff_value_value( diffs, work, attr_name: :visibility, current_value: work.visibility, value: visibility_from_hash( hash: work_hash ) )
        diffs = diff_file_sets( diffs: diffs, work_hash: work_hash, work: work )
        return diffs
      end

      def diff_works
        return unless works
        works.each do |work_hash|
          next if work_hash.nil?
          next unless continue_new_content_service
          work = nil
          work_id = 'nil'
          measurement = Benchmark.measure do
            work, work_id = find_work( work_hash: work_hash, error_if_not_found: false )
            if work.nil?
              puts "== work #{work_id} is missing ==" if work_id.present?
            else
              puts "#{attr_prefix work}: diff..." if verbose
              diffs = diff_work( work_hash: work_hash, work: work )
              if diffs.present?
                puts "#{attr_prefix work}: diffs"
                puts "#{diffs.join("\n")}"
              else
                puts "#{attr_prefix work}: no differences found" if verbose
              end
            end
          end
          next if work.blank?
          measurement.instance_variable_set( :@label, work_id )
          add_measurement measurement
        end
      end

      def do_email( event:, id:, email_to:, subject:, body: )
        email_sent = false
        unless email_test_mode
          email_sent = EmailHelper.send_email( to: email_to,
                                               subject: subject,
                                               content_type: ::Deepblue::EmailHelper::TEXT_HTML,
                                               body: body )
        end
        EmailHelper.log( class_name: self.class.name,
                         current_user: nil,
                         event: event,
                         id: id,
                         to: email_to,
                         subject: subject,
                         body: body,
                         email_sent: email_sent )
      end

      def do_email_after
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "" ] if new_content_service_debug_verbose
        emails_add_from_hash( emails: @emails_after, hash: user_hash )
        emails_add_rest( emails: @emails_after )
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "@emails_after=#{@emails_after}",
                                               "" ] if new_content_service_debug_verbose
        return if @emails_after.blank?
        lines = []
        lines << EmailHelper.t( "hyrax.new_content_service.notify_after_part_1_html",
                                 mode: mode,
                                 path_to_yaml_file: path_to_yaml_file )
        if ( @ingest_urls.present? )
          lines << "<br/>"
          lines << EmailHelper.t( "hyrax.new_content_service.notify_after_part_2_html" )
          lines << "<ul>"
          @ingest_urls.each do |url|
            lines << "<li><a href='#{url}'>#{url}</a></li>"
          end
          lines << "</ul>"
          lines << "<br/>"
        end
        lines << EmailHelper.t( "hyrax.new_content_service.notify_after_part_3_html" )
        lines << "<pre>"
        lines.append @email_after_msg_lines
        lines << "</pre>"
        body = lines.join( "\n" )
        # puts
        # puts body
        # puts
        event = EmailHelper.t( "hyrax.new_content_service.notify_after_event" )
        id = ""
        subject = EmailHelper.t( "hyrax.new_content_service.notify_after_subject" )
        @emails_after.each_pair do |email_to,_value|
          msg = "do_mail_after: send to #{email_to}"
          puts msg
          ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 "msg=#{msg}",
                                                 "" ] if new_content_service_debug_verbose
          do_email( event: event, id: id, email_to: email_to, subject: subject, body: body  )
        end
      end

      def do_email_before
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "" ] if new_content_service_debug_verbose
        emails_add_from_hash( emails: @emails_before, hash: user_hash )
        emails_add_rest( emails: @emails_before )
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "@emails_before=#{@emails_before}",
                                               "" ] if new_content_service_debug_verbose
        return if @emails_before.blank?
        event = "New Content Service - Before"
        id = ""
        template = "hyrax.new_content_service.notify_before_html"
        body = EmailHelper.t( template, mode: mode, path_to_yaml_file: path_to_yaml_file )
        subject = EmailHelper.t( "#{template}_subject" )
        @emails_before.each_pair do |email_to,_value|
          # send the email
          msg = "do_mail_before: send to #{email_to}"
          puts msg
          ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                                 Deepblue::LoggingHelper.called_from,
                                                 "msg=#{msg}",
                                                 "" ] if new_content_service_debug_verbose
          do_email( event: event, id: id, email_to: email_to, subject: subject, body: body  )
        end
      end

      def doi_mint( curation_concern: )
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "curation_concern.id=#{curation_concern.id}",
                                               "" ] if new_content_service_debug_verbose
        # return unless allow_mint_doi
        return unless curation_concern.respond_to? :doi_mint
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "curation_concern.doi=#{curation_concern.doi}",
                                               "" ] if new_content_service_debug_verbose
        return unless ::Deepblue::DoiMintingService::DOI_MINT_NOW == curation_concern.doi
        curation_concern.doi = nil
        curation_concern.save!
        curation_concern.reload
        curation_concern.doi_mint( current_user: user, event_note: 'NewContentService2', job_delay: 60 )
      rescue Exception => e # rubocop:disable Lint/RescueException
        # updates << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
        log_error "#{e.class} work.id=#{work.id} -- #{e.message} at #{e.backtrace[0]}"
        ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "new_content_service_error",
                                               "e=#{e.class.name}",
                                               "e.message=#{e.message}",
                                               "e.backtrace:" ] + e.backtrace[0..25]
      end

      def emails_add_from_hash( emails:, hash: )
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "emails=#{emails}",
                                               "hash=#{hash}",
                                               "email_owner=#{email_owner}",
                                               "email_ingester=#{email_ingester}",
                                               "email_depositor=#{email_depositor}",
                                               "" ] if new_content_service_debug_verbose
        emails_add( emails: emails, add: hash[:email] ) if email_owner
        emails_add( emails: emails, add: hash[:ingester] ) if email_ingester
        emails_add( emails: emails, add: hash[:depositor] ) if email_depositor
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "emails=#{emails}",
                                               "" ] if new_content_service_debug_verbose
      end

      def emails_add_rest( emails: )
        emails_rest.each_key { |email| emails_add( emails: emails, add: email ) }
      end

      def emails_add( emails:, add: )
        return if add.blank?
        return if emails.nil?
        return if emails.has_key? add.to_s
        emails[add.to_s] = true
      end

      def email_after_msg_lines_add( lines: )
        @email_after_msg_lines.concat( Array(lines) )
      end

      def emails_after_add( email: )
        return unless email_after
        @emails_after ||= {}
        emails_add( emails: @emails_after, add: email )
      end

      def emails_before_add( email: )
        return unless email_before
        @emails_before ||= {}
        emails_add( emails: @emails_before, add: email )
      end

      def emails_rest_add( email: )
        return unless email_rest
        @emails_rest ||= {}
        emails_add( emails: @emails_rest, add: email )
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

      def find_collection( collection_hash: )
        # puts "find_collection( collection_hash: #{ActiveSupport::JSON.encode( collection_hash )} )"
        return nil, nil unless continue_new_content_service
        return nil, nil if collection_hash.blank?
        id = collection_hash[:id].to_s
        mode = collection_hash[:mode]
        collection = nil
        collection = Collection.find( id )
        return collection, id
      end

      def find_collection_using_id( id: )
        return nil if id.blank?
        Collection.find id
      rescue Hyrax::ObjectNotFoundError
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

      def find_collections_and_update
        return unless collections
        user_create_users( emails: user_key )
        collections.each do |collection_hash|
          next unless continue_new_content_service
          collection_id = 'nil'
          collection = nil
          measurement = Benchmark.measure do
            collection, collection_id = find_collection( collection_hash: collection_hash )
            update_collection_from_hash( collection_hash: collection_hash, collection: collection )
          end
          next if collection.blank?
          measurement.instance_variable_set( :@label, collection_id )
          add_measurement measurement
        end
      end

      def find_file_set_using_id( id: )
        return nil if id.blank?
        FileSet.find id
      rescue Hyrax::ObjectNotFoundError
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

      def find_user( user_hash:, user_update: false )
        return nil if user_hash.blank?
        email = user_hash[:email]
        # log_msg( "find_user: email: #{email}" ) if verbose
        user = User.find_by_user_key( email )
        return user
      end

      def find_work( work_hash:, error_if_not_found: true )
        work_id = work_hash[:id].to_s
        id = Array(work_id)
        # owner = Array(work_hash[:owner])
        work = TaskHelper.work_find( id: id[0] )
        return work, id[0]
      rescue Hyrax::ObjectNotFoundError
        raise if error_if_not_found
        return nil, id[0]
      end

      def mode_from_hash( hash: )
        hash[:mode]
      end

      def find_works_and_add_files
        return unless works
        works.each do |work_hash|
          next unless continue_new_content_service
          work, work_id = find_work( work_hash: work_hash )
          measurement = Benchmark.measure( work_id ) do
            add_file_sets_to_work( work_hash: work_hash, work: work )
            # unless MODE_APPEND == mode_from_hash( hash: work_hash )
            #   depositor = build_depositor( hash: work_hash )
            #   work.apply_depositor_metadata( depositor )
            #   work.owner = depositor
            #   admin_set = build_admin_set_work( hash: work_hash )
            #   work.admin_set = admin_set
            #   apply_visibility_and_workflow( work: work, work_hash: work_hash, admin_set: admin_set )
            # end
            work.save!
            work.reload
            valid_or_fix_file_sizes( curation_concern: work )
            log_object work
            @ingest_urls << work.data_set_url if work.present?
          end
          add_measurement measurement
        end
      end

      def find_work_using_id( id: )
        return nil if id.blank?
        TaskHelper.work_find( id: id.to_s )
      rescue Hyrax::ObjectNotFoundError
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
        @ingest_id ||= user_hash[:ingester]
      end

      def ingester
        user_hash[:ingester]
      end

      def initialize_emails_rest
        return unless email_rest
        emails = user_hash[:emails_rest]
        return unless emails.present?
        emails.each { |email| emails_rest_add( email: email ) }
      end

      def initialize_options_value( key:, default_value: )
        # initialize with default value
        value = default_value
        # then, override with the value stored from yaml file
        value = user_hash[key] if user_hash.key? key
        # finally, override with value passed in on command line
        value = TaskHelper.task_options_value( @options, key: key.to_s, default_value: value )
        puts "initialize_options_value #{key}=#{value}" if @verbose
        return value
      end

      def initialize_with_msg( options:,
                               path_to_yaml_file:,
                               cfg_hash:,
                               base_path:,
                               mode: nil,
                               ingester: nil,
                               use_rails_logger: false,
                               user_create: DEFAULT_USER_CREATE,
                               msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE",
                               **config )

        if use_rails_logger
          @logger = Rails.logger
        else
          Rails.configuration.provenance_log_echo_to_rails_logger = false
          ProvenanceHelper.echo_to_rails_logger = false
        end

        @options = TaskHelper.task_options_parse options
        if @options.key?( :error ) || @options.key?( 'error' )
          puts "WARNING: options error #{@options['error']}"
          puts "options=#{options}" if @options.key?( :error )
          puts "@options=#{@options}" if @options.key?( 'error' )
        end
        @base_path = base_path
        @config = {}
        @config.merge!( config ) if config.present?
        @cfg_hash = cfg_hash
        @diff_attrs_skip = [] + DEFAULT_DIFF_ATTRS_SKIP
        @diff_attrs_skip_if_blank = [] + DEFAULT_DIFF_ATTRS_SKIP_IF_BLANK
        @diff_user_attrs_skip = [] + DEFAULT_DIFF_USER_ATTRS_SKIP
        @diff_user_attrs_skip.concat Deepblue::MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE
        @email_after_msg_lines = []
        @emails_after = {}
        @emails_before = {}
        @emails_rest = {}
        @ingest_id = File.basename path_to_yaml_file
        @ingest_timestamp = DateTime.now
        @ingest_urls = []
        @ingester = ingester if ingester.present?
        @mode = mode if mode.present?
        @path_to_yaml_file = path_to_yaml_file
        @update_add_files = DEFAULT_UPDATE_ADD_FILES
        @update_attrs_skip = [] + DEFAULT_UPDATE_ATTRS_SKIP
        @update_attrs_skip_if_blank = [] + DEFAULT_UPDATE_ATTRS_SKIP_IF_BLANK
        @update_build_mode = DEFAULT_UPDATE_BUILD_MODE
        @update_delete_files = DEFAULT_UPDATE_DELETE_FILES
        @update_user_attrs_skip = [] + DEFAULT_UPDATE_USER_ATTRS_SKIP
        @update_user_attrs_skip.concat Deepblue::MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE
        @verbose = initialize_options_value( key: :verbose, default_value: DEFAULT_VERBOSE )
        log_msg( "@verbose=#{@verbose}", timestamp_it: false ) if @verbose
        @skip_adding_prior_identifier = initialize_options_value( key: :skip_adding_prior_identifier,
                                                                  default_value: DEFAULT_SKIP_ADDING_PRIOR_IDENTIFIER )
        @email_test_mode = initialize_options_value( key: :email_test_mode, default_value: DEFAULT_EMAIL_TEST_MODE )
        @email_after = initialize_options_value( key: :email_after, default_value: DEFAULT_EMAIL_AFTER )
        @email_after_add_log_msgs = initialize_options_value( key: :email_after_add_log_msgs,
                                                              default_value: DEFAULT_EMAIL_AFTER_ADD_LOG_MSGS )
        @email_before = initialize_options_value( key: :email_before, default_value: DEFAULT_EMAIL_BEFORE )
        @email_each = initialize_options_value( key: :email_each, default_value: DEFAULT_EMAIL_EACH )
        @email_depositor = initialize_options_value( key: :email_depositor, default_value: DEFAULT_EMAIL_DEPOSITOR )
        @email_ingester = initialize_options_value( key: :email_ingester, default_value: DEFAULT_EMAIL_INGESTER )
        @email_owner = initialize_options_value( key: :email_owner, default_value: DEFAULT_EMAIL_OWNER )
        @email_rest = initialize_options_value( key: :email_rest, default_value: DEFAULT_EMAIL_REST )
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "mode=#{mode}",
                                               "@email_test_mode=#{@email_test_mode}",
                                               "@email_after=#{@email_after}",
                                               "@email_after_add_log_msgs=#{@email_after_add_log_msgs}",
                                               "@email_before=#{@email_before}",
                                               "@email_each=#{@email_each}",
                                               "@email_depositor=#{@email_depositor}",
                                               "@email_ingester=#{@email_ingester}",
                                               "@email_owner=#{@email_owner}",
                                               "@email_rest=#{@email_rest}",
                                               "" ] if new_content_service_debug_verbose
        initialize_emails_rest
        @user_create = user_create
        @stop_new_content_service = false
        current_dir = Pathname.new( '.' ).realdirpath
        @stop_new_content_service_file = current_dir.join STOP_NEW_CONTENT_SERVICE_FILE_NAME
        @stop_new_content_service_ppid_file = current_dir.join( "#{Process.ppid}_#{STOP_NEW_CONTENT_SERVICE_FILE_NAME}" )
        log_msg( msg, timestamp_it: false, not_email_line: true )
        log_msg( "mode=#{mode}", timestamp_it: true ) if verbose
      end

      def log_error( msg )
        logger.error msg
      end

      def log_msg( msg, timestamp_it: true, not_email_line: false )
        return if msg.blank?
        if timestamp_it
          msg = "#{timestamp_now} #{msg}"
        end
        ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                               Deepblue::LoggingHelper.called_from,
                                               "msg=#{msg}",
                                               "" ] if new_content_service_debug_verbose
        logger.info msg
        return if not_email_line
        email_after_msg_lines_add( lines: msg ) if email_after_add_log_msgs
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
                                     child_title: child.title,
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
        # @mode ||= user_hash[:mode]
        @mode ||= cfg_hash_value( base_key: :user, key: :mode, default_value: MODE_APPEND )
      end

      def new_collection( creator:,
                          curation_notes_admin:,
                          curation_notes_user:,
                          date_created:,
                          date_modified:,
                          date_uploaded:,
                          description:,
                          doi:,
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
                          doi: doi,
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
                          doi: doi,
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
                        date_published:,
                        date_uploaded:,
                        description:,
                        doi:,
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
                       date_published: date_published,
                       date_uploaded: date_uploaded,
                       description: description,
                       doi: doi,
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
                       date_published: date_published,
                       date_uploaded: date_uploaded,
                       description: description,
                       doi: doi,
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
        log_msg "#{label} #{Benchmark::CAPTION.chop}", timestamp_it: false
        format = Benchmark::FORMAT.chop
        measurements.each do |measurement|
          label = measurement.label
          log_msg measurement.format( "#{label} #{format} is #{TaskHelper.seconds_to_readable(measurement.real)}" ), timestamp_it: false
        end
        return if measurements.size == 1
        return if total.blank?
        label = 'total'
        label += ' ' * (first_id.size - label.size)
        log_msg total.format( "#{label} #{format} is #{TaskHelper.seconds_to_readable(total.real)}" ), timestamp_it: false
      end

      def report_measurements( first_label: )
        return if measurements.blank?
        puts
        log_msg "Report run time:", timestamp_it: false
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

      def state_curation_concern( state )
        return valid_restricted_vocab( state,
                                       var: :state,
                                       vocab: %w[active deleted inactive unknown],
                                       error_class: StateError )
      end

      def state_from_hash( hash: )
        state = hash[:state]
        state = 'active' if ( state.blank? || 'unknown' == state )
        state_curation_concern( state )
      end

      def state_str_to_fedora_resource_status( state )
        case state
        when 'active'
          Vocab::FedoraResourceStatus.active
        when 'deleted'
          Vocab::FedoraResourceStatus.deleted
        when 'inactive'
          Vocab::FedoraResourceStatus.inactive
        when 'unknown'
          Vocab::FedoraResourceStatus.active
        else
          raise StateError( "Unknown state: #{state}" )
        end
      end

      def source
        @source ||= valid_restricted_vocab( user_hash[:source], var: :source, vocab: %w[DBDv1 DBDv2] )
      end

      def timestamp_now
        Time.now.to_formatted_s(:db )
      end

      def update_attr( updates, cc_or_fs, cc_or_fs_hash, attr_name:, attr_name_hash: nil, multi: true )
        return updates unless update_attr? attr_name
        attr_current = cc_or_fs[attr_name]
        value = cc_or_fs_hash[attr_name] if attr_name_hash.blank?
        value = cc_or_fs_hash[attr_name_hash] if attr_name_hash.present?
        value = Array( value ) if multi
        return updates unless update_attr_if_blank?( attr_name, value: value )
        return updates if attr_current == value
        cc_or_fs[attr_name] = value
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} '#{attr_current}' updated to '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def update_attr?( attr_name, parent: nil )
        return false if update_attrs_skip.include? attr_name
        return true
      end

      def update_attr_if_blank?( attr_name, value:, parent: nil )
        return false if value.blank? # && update_attrs_skip_if_blank.include?( attr_name )
        return true
      end

      def update_attr_doi( updates, cc_or_fs, cc_or_fs_hash, allow_minting: true )
        doi_from_hash = cc_or_fs_hash[:doi]
        if ::Deepblue::DoiMintingService::DOI_MINT_NOW == doi_from_hash
          doi_mint( curation_concern: cc_or_fs ) if allow_minting
        else
          update_attr( updates, cc_or_fs, cc_or_fs_hash, attr_name: :doi, multi: false )
        end
        return updates
      rescue Exception => e # rubocop:disable Lint/RescueException
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def update_attr_value( updates, cc_or_fs, attr_name:, value: nil, multi: true )
        return updates unless update_attr? attr_name
        return updates unless update_attr_if_blank?( attr_name, value: value )
        attr_current = cc_or_fs[attr_name]
        return updates if attr_current == value
        cc_or_fs[attr_name] = value
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} '#{attr_current}' updated to '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def update_cc_attribute( curation_concern:, attribute:, value: )
        curation_concern[attribute] = value
      end

      def update_cc_edit_users( curation_concern:, edit_users: )
        return if edit_users.blank?
        user_create_users( emails: edit_users )
        curation_concern.edit_users = Array( curation_concern.edit_users ) | edit_users
      end

      def update_cc_read_users( curation_concern:, read_users: )
        return if read_users.blank?
        user_create_users( emails: read_users )
        curation_concern.read_users = Array( curation_concern.read_users ) | read_users
      end

      def update_collection_from_hash( collection_hash:, collection: )
        # TODO
      end

      def update_collection( updates: nil, collection:, collection_hash: )
        updates_in = updates
        updates_in = [] if updates_in.nil?
        updates = []
        update_attr( updates, collection, collection_hash, attr_name: :creator )
        update_attr( updates, collection, collection_hash, attr_name: :creator_ordered, multi: false )
        update_attr( updates, collection, collection_hash, attr_name: :curation_notes_admin )
        update_attr( updates, collection, collection_hash, attr_name: :curation_notes_admin_ordered, multi: false )
        update_attr( updates, collection, collection_hash, attr_name: :curation_notes_user )
        update_attr( updates, collection, collection_hash, attr_name: :curation_notes_user_ordered, multi: false )
        update_attr_value( updates, collection, attr_name: :date_created, value: build_date( hash: collection_hash, key: :date_created ) )
        update_attr_value( updates, collection, attr_name: :date_modified, value: build_date( hash: collection_hash, key: :date_modified ) )
        update_attr_value( updates, collection, attr_name: :date_uploaded, value: build_date( hash: collection_hash, key: :date_uploaded ) )
        depositor = build_depositor( hash: collection_hash )
        update_attr_value( updates, collection, attr_name: :depositor, value: depositor )
        description = Array( collection_hash[:description] )
        description = ["Missing description"] if description.blank?
        description = ["Missing description"] if [nil] == description
        update_attr_value( updates, collection, attr_name: :description, value: description )
        update_attr( updates, collection, collection_hash, attr_name: :description_ordered, multi: false )
        # update_attr_doi( updates, collection, collection_hash )
        update_edit_users( updates, collection, collection_hash )
        update_read_users( updates, collection, collection_hash )
        update_attr( updates, collection, collection_hash, attr_name: :keyword )
        update_attr( updates, collection, collection_hash, attr_name: :keyword_ordered, multi: false )
        update_attr( updates, collection, collection_hash, attr_name: :language )
        update_attr( updates, collection, collection_hash, attr_name: :language_ordered, multi: false )
        update_attr( updates, collection, collection_hash, attr_name: :prior_identifier )
        update_attr_value( updates, collection, attr_name: :referenced_by, value: build_referenced_by( hash: collection_hash ) )
        resource_type = Array( collection_hash[:resource_type] || 'Collection' )
        update_attr_value( updates, collection, attr_name: :resource_type, value: resource_type )
        update_attr_value( updates, collection, attr_name: :subject_discipline, value: build_subject_discipline( hash: collection_hash ) )
        update_attr( updates, collection, collection_hash, attr_name: :title )
        update_attr( updates, collection, collection_hash, attr_name: :title_ordered, multi: false )
        collection.save! unless updates.empty?
        return updates_in.concat updates unless update_collections_recurse
        updates = update_collection_works( updates: updates, collection: collection, collection_hash: collection_hash )
        return updates_in.concat updates
      end

      def update_collection_works( updates:, collection:, collection_hash: )
        collection_works = {}
        collection.member_objects.each do |member|
          return updates unless continue_new_content_service
          collection_works[member.id] = member if TaskHelper.work? member
        end
        work_ids = works_from_hash( hash: collection_hash )
        return updates if work_ids.blank?
        work_ids[0].each do |work_id|
          return updates unless continue_new_content_service
          if collection_works.key? work_id
            work_hash = work_hash_from_id( parent_hash: collection_hash, work_id: work_id.to_s )
            update_work( updates: updates, work_hash: work_hash, work: collection_works[work_id], parent: collection )
            collection_works.delete work_id
          else
            updates << "#{attr_prefix collection}: is missing work #{work_id}"
          end
        end
        collection_works.each_value do |work|
          return updates unless continue_new_content_service
          updates << "#{attr_prefix collection}: has extra work #{work.id}"
        end
        return updates
      end

      def update_collections
        return unless collections
        collections.each do |collection_hash|
          next if collection_hash.nil?
          next unless continue_new_content_service
          collection = nil
          collection_id = 'nil'
          measurement = Benchmark.measure do
            collection, collection_id = find_collection( collection_hash: collection_hash )
            if collection.nil?
              puts "== coll #{collection_id} is missing =="
            else
              puts "coll #{collection_id}: update..." if verbose
              updates = update_collection( collection_hash: collection_hash, collection: collection )
              if updates.present?
                puts "#{attr_prefix collection}: updates"
                puts "#{updates.join("\n")}"
              end
            end
          end
          next if collection.blank?
          measurement.instance_variable_set( :@label, collection_id )
          add_measurement measurement
        end
      end

      def update_edit_users( updates, cc_or_fs, cc_or_fs_hash )
        attr_name = :edit_users
        return updates unless diff_attr? attr_name
        current_value = cc_or_fs.edit_users
        value = Array( cc_or_fs_hash[attr_name] )
        return updates unless diff_attr_if_blank?( attr_name, value: value )
        xor = current_value + value - ( current_value & value )
        return updates if xor.empty?
        cc_or_fs.edit_users = value
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} '#{current_value}' updated to '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def update_read_users( updates, cc_or_fs, cc_or_fs_hash )
        attr_name = :read_users
        return updates unless diff_attr? attr_name
        current_value = cc_or_fs.read_users
        value = Array( cc_or_fs_hash[attr_name] )
        return updates unless diff_attr_if_blank?( attr_name, value: value )
        xor = current_value + value - ( current_value & value )
        return updates if xor.empty?
        cc_or_fs.read_users = value
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} '#{current_value}' updated to '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def update_file_set( updates:, file_set:, file_set_hash:, parent: nil )
        return updates unless continue_new_content_service
        updates_in = updates
        updates_in = [] if updates_in.nil?
        updates = []
        update_attr( updates, file_set, file_set_hash, attr_name: :curation_notes_admin )
        update_attr( updates, file_set, file_set_hash, attr_name: :curation_notes_admin_ordered, multi: false )
        update_attr( updates, file_set, file_set_hash, attr_name: :curation_notes_user )
        update_attr( updates, file_set, file_set_hash, attr_name: :curation_notes_user_ordered, multi: false )
        # update_attr( updates, file_set, file_set_hash, attr_name: :checksum_algorithm )
        # update_attr( updates, file_set, file_set_hash, attr_name: :checksum_value )
        update_attr_value( updates, file_set, attr_name: :date_created, value: build_date( hash: file_set_hash, key: :date_created ) )
        update_attr_value( updates, file_set, attr_name: :date_modified, value: build_date( hash: file_set_hash, key: :date_modified ) )
        update_attr_value( updates, file_set, attr_name: :date_uploaded, value: build_date( hash: file_set_hash, key: :date_uploaded ) )
        depositor = build_depositor( hash: file_set_hash )
        update_attr_value( updates, file_set, attr_name: :depositor, value: depositor )
        update_attr( updates, file_set, file_set_hash, attr_name: :description_file_set )
        update_edit_users( updates, file_set, file_set_hash )
        update_read_users( updates, file_set, file_set_hash )
        update_attr( updates, file_set, file_set_hash, attr_name: :label, multi: false )
        original_name = file_set_hash[:original_name]
        update_value_value( updates, file_set, attr_name: :orignal_name, current_value: file_set.original_name_value, value: original_name )
        update_attr( updates, file_set, file_set_hash, attr_name: :prior_identifier )
        update_attr( updates, file_set, file_set_hash, attr_name: :title )
        update_value_value( updates, file_set, attr_name: :visibility, current_value: file_set.visibility, value: visibility_from_hash( hash: file_set_hash ) )
        file_set.save! unless updates.empty?
        return updates_in.concat updates
      end

      def update_file_sets( updates:, work_hash:, work: )
        file_set_ids = work_hash[:file_set_ids]
        return update_file_sets_from_file_set_ids( updates: updates, work_hash: work_hash, work: work ) if file_set_ids.present?
        return update_file_sets_from_files( updates: updates, work_hash: work_hash, work: work )
      end

      def update_file_sets_from_file_set_ids( updates:, work_hash:, work: )
        work_file_sets = {}
        work.file_sets.each do |fs|
          return updates unless continue_new_content_service
          work_file_sets[fs.id] = fs
        end
        file_set_ids = work_hash[:file_set_ids]
        file_set_ids.each do |file_set_id|
          return updates unless continue_new_content_service
          file_set_key = "f_#{file_set_id}"
          if work_file_sets.key? file_set_id
            file_set_hash = work_hash[file_set_key.to_sym]
            update_file_set( updates: updates,
                             file_set: work_file_sets[file_set_id],
                             file_set_hash: file_set_hash,
                             parent: work )
            work_file_sets.delete file_set_id
          else
            updates << "#{attr_prefix work}: is missing file #{file_set_id}"
            next unless update_add_files
            next unless continue_new_content_service
            file_set_hash = work_hash[file_set_key.to_sym]
            file_size = add_file_sets_file_size( file_set_hash: file_set_hash )
            file_set = build_file_set_from_hash( id: file_set_id.to_s,
                                                 file_set_hash: file_set_hash,
                                                 parent: work,
                                                 file_set_of: 1,
                                                 file_set_count: 1,
                                                 file_size: file_size,
                                                 build_mode: update_build_mode )
            next if file_set.blank?
            add_file_set_to_work( work: work, file_set: file_set )
            # TODO: move ingest step here, this will probably fix file_sets that turn up with missing file sizes
            updates << "#{attr_prefix work}: file added #{file_set_id}"
          end
        end
        work_file_sets.each_value do |file_set|
          return updates unless continue_new_content_service
          updates << "#{attr_prefix work}: has extra file #{file_set.id}"
          next unless update_delete_files
          file_set.delete
          updates << "#{attr_prefix work}: file deleted #{file_set.id}"
        end
        return updates
      end

      def update_file_sets_from_files( updates:, work_hash:, work: )
        # TODO: for now, just detect if they are there
        return updates
      end

      def update_user( updates: nil, user:, user_hash:, user_email: nil )
        if user_email.nil?
          # old update
          attr_names = User.attribute_names
          skip = Deepblue::MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE
          attr_names.each do |name|
            next if skip.include?( name )
            next if name == "id"
            next if name == "email"
            value = user_hash[name.to_sym]
            user[name] = value if value.present?
          end
          log_msg( "update_user #{user.email}" )
          user.save( validate: false )
        else
          # new update
          updates = [] if updates.nil?
          return updates unless continue_new_content_service
          attr_names = User.attribute_names
          attr_names.each do |name|
            update_user_attr( updates, user, user_hash, user_email, attr_name: name )
          end
          return updates
        end
      end

      def update_value_value( updates, cc_or_fs, attr_name:, current_value:, value: nil )
        return updates unless update_attr? attr_name
        return updates unless update_attr_if_blank?( attr_name, value: value )
        return updates if current_value == value
        # TODO: this looks like it doesn't actually update the value
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} '#{current_value}' vs. '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        updates << "#{attr_prefix cc_or_fs}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def update_users
        return unless users
        measurement = Benchmark.measure do
          users.each do |users_hash|
            user_emails = users_hash[:user_emails]
            next if user_emails.blank?
            # log_msg( "users_hash: #{users_hash}" ) if verbose
            user_emails.each do |user_email|
              # log_msg( "processing user: #{user_email}" ) if verbose
              user_email_id = "user_#{user_email}".to_sym
              # log_msg( "user_email_id: #{user_email_id}" ) if verbose
              user_hash = users_hash[user_email_id]
              # log_msg( "user_hash: #{user_hash}" ) if verbose
              user = find_user( user_hash: user_hash )
              if user.nil?
                puts "== user #{user_email} is missing ==" if user_email_id.present?
              else
                puts "#{user_email}: update..." if verbose
                updates = update_user( user_hash: user_hash, user: user, user_email: user_email )
                if updates.present?
                  puts "#{user_email}: updated"
                  puts "#{updates.join("\n")}"
                  user.save( validate: false )
                else
                  puts "#{user_email}: no updates done" if verbose
                end
              end
            end
          end
        end
        return measurement
      end

      def update_user_attr( updates, user, user_hash, user_email, attr_name:, attr_name_hash: nil, multi: false )
        attr_name = attr_name.to_sym if attr_name.is_a? String
        return updates unless update_user_attr? attr_name
        attr_current = user[attr_name]
        value = user_hash[attr_name] if attr_name_hash.blank?
        value = user_hash[attr_name_hash] if attr_name_hash.present?
        value = Array( value ) if multi
        if attr_current.is_a?( Time )
          attr_current = attr_current.change(usec: 0)
          value = build_time( value: value )
          value = value.change(usec: 0) if value.is_a? Time
        end
        return updates unless update_user_attr_if_blank?( attr_name, value: value )
        return updates if attr_current == value
        user[attr_name] = value
        updates << "#{user_email}: #{attr_name} '#{attr_current}' updated to '#{value}'"
      rescue Exception => e # rubocop:disable Lint/RescueException
        updates << "#{user_email}: #{attr_name} -- Exception: #{e.class}: #{e.message} at #{e.backtrace[0]}"
      end

      def update_user_attr?( attr_name )
        return false if update_user_attrs_skip.include? attr_name
        return true
      end

      def update_user_attr_if_blank?( attr_name, value:, parent: nil )
        return false if value.blank? # && update_attrs_skip_if_blank.include?( attr_name )
        return true
      end

      def update_visibility( curation_concern:, visibility: )
        return unless visibility_curation_concern visibility
        curation_concern.visibility = visibility
      end

      def update_work( updates: nil, work_hash:, work:, parent: nil )
        updates_in = updates
        updates_in = [] if updates_in.nil?
        updates = []
        return updates_in unless continue_new_content_service
        update_attr( updates, work, work_hash, attr_name: :authoremail, multi: false )
        update_attr( updates, work, work_hash, attr_name: :contributor )
        update_attr( updates, work, work_hash, attr_name: :creator )
        update_attr( updates, work, work_hash, attr_name: :creator_ordered, multi: false )
        update_attr( updates, work, work_hash, attr_name: :curation_notes_admin )
        update_attr( updates, work, work_hash, attr_name: :curation_notes_admin_ordered, multi: false )
        update_attr( updates, work, work_hash, attr_name: :curation_notes_user )
        update_attr( updates, work, work_hash, attr_name: :curation_notes_user_ordered, multi: false )
        update_attr_value( updates, work, attr_name: :date_coverage, value: build_date_coverage(hash: work_hash ) )
        update_attr_value( updates, work, attr_name: :date_created, value: build_date(hash: work_hash, key: :date_created ) )
        update_attr_value( updates, work, attr_name: :date_modified, value: build_date(hash: work_hash, key: :date_modified ) )
        update_attr_value( updates, work, attr_name: :date_published, value: build_date(hash: work_hash, key: :date_published ) )
        update_attr_value( updates, work, attr_name: :date_uploaded, value: build_date(hash: work_hash, key: :date_uploaded ) )
        depositor = build_depositor( hash: work_hash )
        update_attr_value( updates, work, attr_name: :depositor, value: depositor )
        description = Array( work_hash[:description] )
        description = ["Missing description"] if description.blank?
        description = ["Missing description"] if [nil] == description
        update_attr_value( updates, work, attr_name: :description, value: description )
        update_attr( updates, work, work_hash, attr_name: :description_ordered, multi: false )
        update_edit_users( updates, work, work_hash )
        update_read_users( updates, work, work_hash )
        update_attr_value( updates, work, attr_name: :fundedby, value: build_fundedby(hash: work_hash ) )
        update_attr( updates, work, work_hash, attr_name: :fundedby_other )
        update_attr( updates, work, work_hash, attr_name: :grantnumber, multi: false )
        update_attr( updates, work, work_hash, attr_name: :keyword )
        update_attr( updates, work, work_hash, attr_name: :keyword_ordered, multi: false )
        update_attr( updates, work, work_hash, attr_name: :language )
        update_attr( updates, work, work_hash, attr_name: :language_ordered, multi: false )
        methodology = Array( work_hash[:methodology] )
        methodology = [ "No Methodology Available" ] unless methodology.present?
        update_attr_value( updates, work, attr_name: :methodology, value: methodology )
        update_attr( updates, work, work_hash, attr_name: :methodology_ordered, multi: false )
        update_attr_value( updates, work, attr_name: :owner, value: depositor )
        update_attr( updates, work, work_hash, attr_name: :prior_identifier )
        update_attr_value( updates, work, attr_name: :referenced_by, value: build_referenced_by(hash: work_hash ) )
        update_attr( updates, work, work_hash, attr_name: :referenced_by_ordered, multi: false )
        resource_type = Array( work_hash[:resource_type] || 'Dataset' )
        update_attr_value( updates, work, attr_name: :resource_type, value: resource_type )
        update_attr_value( updates, work, attr_name: :rights_license, value: build_rights_liscense(hash: work_hash ) )
        update_attr( updates, work, work_hash, attr_name: :rights_license_other, multi: false )
        update_attr_value( updates, work, attr_name: :subject_discipline, value: build_subject_discipline(hash: work_hash ) )
        update_attr( updates, work, work_hash, attr_name: :title )
        update_attr( updates, work, work_hash, attr_name: :title_ordered, multi: false )
        update_value_value( updates, work, attr_name: :visibility, current_value: work.visibility, value: visibility_from_hash(hash: work_hash ) )
        work.save! unless updates.empty?
        updates = update_file_sets( updates: updates, work_hash: work_hash, work: work )
        update_attr_doi( updates, work, work_hash )
        work.save! unless updates.empty?
        return updates_in.concat updates
      end

      def update_works
        return unless works
        works.each do |work_hash|
          next if work_hash.nil?
          next unless continue_new_content_service
          work = nil
          work_id = 'nil'
          measurement = Benchmark.measure do
            work, work_id = find_work( work_hash: work_hash, error_if_not_found: false )
            if work.nil?
              puts "== work #{work_id} is missing =="
            else
              puts "#{attr_prefix work}: update..." if verbose
              updates = update_work( work_hash: work_hash, work: work )
              if updates.present?
                puts "#{attr_prefix work}: updated"
                puts "#{updates.join("\n")}"
              end
              add_work_to_parent_ids( work_hash: work_hash, work: work )
              # doi_mint( curation_concern: work )
            end
          end
          next if work.blank?
          measurement.instance_variable_set( :@label, work_id )
          add_measurement measurement
        end
      end

      # def update_work_from_hash( work_hash:, work: )
      #   # TODO
      # end

      def upload_file_to_file_set( file_set, file )
        Hydra::Works::UploadFileToFileSet.call( file_set, file )
        return true
      rescue Ldp::Conflict
        return false
      end

      def users
        @users ||= users_from_hash( hash: user_hash )
      end

      def user_create_users( emails:, password: 'password' )
        return unless user_create
        return if emails.blank?
        emails = Array( emails )
        emails.each do |email|
          next if User.find_by_user_key( email ).present?
          # User.create!( email: email, password: password, password_confirmation: password )
          User.new( email: email, password: password ) { |u| u.save( validate: false ) }
          log_msg( "Creating user: #{email}" )
        end
      end

      def users_from_hash( hash: )
        [hash[:users]]
      end

      def user_key
        # TODO: validate the email
        user_hash[:email]
      end

      def user_hash
        cfg_hash[:user]
      end

      # config needs default user to attribute collections/works/filesets to
      # User needs to have only works or collections
      def validate_config
        # if cfg_hash.keys != [:user]
        unless cfg_hash.key?( :user )
          raise ConfigError, "Top level keys needs to contain 'user'"
        end
        # # rubocop:disable Style/GuardClause
        # if (user_hash.keys <=> %i[collections works]) < 1
        #   raise ConfigError, "user can only contain collections and works"
        # end
        # rubocop:enable Style/GuardClause
      end

      def valid_restricted_vocab( value, var:, vocab:, error_class: RestrictedVocabularyError )
        unless vocab.include? value
          raise error_class, "Illegal value '#{value}' #{var}, must be one of #{vocab}"
          # raise error_class.new "Illegal value '#{value}' #{var}, must be one of #{vocab}"
        end
        return value
      end

      def visibility
        @visibility ||= visibility_curation_concern( user_hash[:visibility] )
      end

      def visibility_curation_concern( vis )
        return valid_restricted_vocab( vis,
                                       var: :visibility,
                                       vocab: %w[open institution restricted],
                                       error_class: VisibilityError )
      end

      def visibility_from_hash( hash: )
        vis = hash[:visibility]
        return visibility_curation_concern( vis ) if vis.present?
        visibility
      end

      def work_hash_from_id( parent_hash:, work_id: )
        id_key = "works_#{work_id}".to_sym
        # puts "id_key=#{id_key}"
        parent_hash[id_key]
      end

      def works
        @works ||= works_from_hash( hash: user_hash )
      end

      def works_from_hash( hash: )
        [hash[:works]]
      rescue Exception => e
        ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] + e.backtrace[0..20]
        raise
      end

  end
  # rubocop:enable Rails/Output

end
