# frozen_string_literal: true

require 'hydra/file_characterization'
require_relative './task_logger'

Hydra::FileCharacterization::Characterizers::Fits.tool_path = `which fits || which fits.sh`.strip

module Deepblue

  class NewContentService

    SOURCE_DBDv1 = 'DBDv1' # rubocop:disable Style/ConstantName
    SOURCE_DBDv2 = 'DBDv2' # rubocop:disable Style/ConstantName
    MODE_APPEND = 'append'
    MODE_BUILD = 'build'

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

    attr_reader :base_path, :cfg_hash, :config, :ingest_id, :ingester, :ingest_timestamp, :path_to_yaml_file, :user

    def initialize( path_to_yaml_file:, cfg_hash:, base_path:, args: )
      initialize_with_msg( args: args,
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

      def add_file_sets_to_work( work_hash:, work: )
        files = work_hash[:files]
        return if files.blank?
        file_ids = work_hash[:file_ids]
        file_ids = [] if file_ids.nil?
        filenames = work_hash[:filenames]
        filenames = [] if filenames.nil?
        paths_and_names = files.zip( filenames, file_ids )
        fsets = paths_and_names.map do |fp|
          build_file_set( path: fp[0], file_set_vis: work.visibility, filename: fp[1], file_ids: fp[2] )
        end
        fsets.each do |fs|
          work.ordered_members << fs
          log_provenance_add_child( parent: work, child: fs )
          work.total_file_size_add_file_set fs
          work.representative = fs if work.representative_id.blank?
          work.thumbnail = fs if work.thumbnail_id.blank?
        end
        work.save!
        work.reload
        return work
      end

      def add_works_to_collection( collection_hash:, collection: )
        # puts "collection_hash=#{collection_hash}"
        work_ids = works_from_hash( hash: collection_hash )
        collection_works = work_ids[0].map do |work_id|
          # puts "work_id=#{work_id}"
          work_hash = works_from_id( hash: collection_hash, work_id: work_id )
          # puts "work_hash=#{work_hash}"
          build_or_find_work( work_hash: work_hash )
        end
        collection_works.each do |work|
          work.member_of_collections << collection
          log_provenance_add_child( parent: collection, child: work )
          work.save!
        end
        collection.save!
        collection.reload
        return collection
      end

      def build_admin_set( hash: )
        admin_set_id = hash[:admin_set_id]
        return default_admin_set if admin_set_id.blank?
        return default_admin_set if AdminSet.default_set? admin_set_id
        begin
          admin_set = AdminSet.find( admin_set_id )
        rescue ActiveFedora::ObjectNotFoundError
          # TODO: Log this
          admin_set = default_admin_set
        end
        admin_set
      end

      def build_date( hash:, key: )
        rv = hash[key]
        return rv unless rv.to_s.empty?
        DateTime.now.to_s
      end

      def build_collection( id:, collection_hash: )
        title = Array( collection_hash[:title] )
        creator = Array( collection_hash[:creator] )
        description = Array( collection_hash[:description] )
        prior_identifier = build_prior_identifier( hash: collection_hash, id: id )
        subject_discipline = build_subject_discipline( hash: collection_hash )
        date_uploaded = build_date( hash: collection_hash, key: :date_uploaded )
        date_modified = build_date( hash: collection_hash, key: :date_modified )
        date_created = build_date( hash: collection_hash, key: :date_created )
        resource_type = Array( collection_hash[:resource_type] || 'Collection' )
        language = Array( collection_hash[:language] )
        keyword = Array( collection_hash[:keyword] )
        referenced_by = build_referenced_by( hash: collection_hash )

        collection = Collection.new( title: title,
                                     creator: creator,
                                     description: description,
                                     resource_type: resource_type,
                                     prior_identifier: prior_identifier,
                                     subject_discipline: subject_discipline,
                                     date_uploaded: date_uploaded,
                                     date_modified: date_modified,
                                     date_created: date_created,
                                     language: language,
                                     keyword: keyword,
                                     referenced_by: referenced_by )

        collection.collection_type = build_collection_type( hash: collection_hash )
        collection.apply_depositor_metadata( user_key )
        collection.visibility = visibility_from_hash( hash: collection_hash )
        collection.save!
        collection.reload
        log_provenance_ingest( curation_concern: collection )
        return collection
      end

      def build_collection_type( hash: )
        return Hyrax::CollectionType.find_or_create_default_collection_type if 'DBDv1' == source
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
        collections.each { |collection_hash| build_or_find_collection( collection_hash: collection_hash ) }
      end

      def build_file_set( path:, file_set_vis:, filename: nil, file_ids: nil )
        # puts "path=#{path} filename=#{filename} file_ids=#{file_ids}"
        # If filename not given, use basename from path
        fname = filename || File.basename( path )
        logger.info "Processing: #{fname}"
        file = File.open( path )
        # fix so that filename comes from the name of the file and not the hash
        file.define_singleton_method( :original_name ) do
          fname
        end
        file_set = FileSet.new
        file_set.apply_depositor_metadata( user_key )
        Hydra::Works::UploadFileToFileSet.call( file_set, file )
        file_set.title = Array( fname )
        file_set.label = fname
        now = DateTime.now.new_offset( 0 )
        file_set.date_uploaded = now
        file_set.visibility = file_set_vis
        file_set.prior_identifier = file_ids if file_ids.present?
        file_set.save!
        log_object file_set
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
        logger.info "Finished: #{fname}"
        return file_set
      end

      def build_or_find_collection( collection_hash: )
        # puts "build_or_find_collection( collection_hash: #{ActiveSupport::JSON.encode( collection_hash )} )"
        return if collection_hash.blank?
        id = collection_hash[:id]
        mode = collection_hash[:mode]
        mode = MODE_BUILD if id.blank?
        collection = nil
        collection = Collection.find( id ) if MODE_APPEND == mode
        collection = build_collection( id: id, collection_hash: collection_hash ) if collection.nil?
        log_object collection if collection.present?
        add_works_to_collection( collection_hash: collection_hash, collection: collection )
        collection.save!
        return collection
      end

      def build_or_find_work( work_hash: )
        # puts "build_or_find_work( work_hash: #{work_hash} )"
        return nil if work_hash.blank?
        id = work_hash[:id]
        mode = work_hash[:mode]
        mode = MODE_BUILD if id.blank?
        work = nil
        work = DataSet.find( id ) if MODE_APPEND == mode
        work = build_work( id: id, work_hash: work_hash ) if work.nil?
        log_object work if work.present?
        add_file_sets_to_work( work_hash: work_hash, work: work )
        return work
      end

      def build_prior_identifier( hash:, id: )
        if 'DBDv1' == source
          Array( id )
        else
          arr = Array( hash[:prior_identifier] )
          arr << id if id.present?
        end
      end

      def build_referenced_by( hash: )
        if 'DBDv1' == source
          Array( hash[:isReferencedBy] )
        else
          hash[:referenced_by]
        end
      end

      def build_rights_liscense( hash: )
        if 'DBDv1' == source
          hash[:rights]
        else
          hash[:rights_license]
        end
      end

      def build_repo_contents
        # override with something interesting
      end

      def build_subject_discipline( hash: )
        if 'DBDv1' == source
          Array( hash[:subject] )
        else
          Array( hash[:subject_discipline] )
        end
      end

      def build_work( id:, work_hash: )
        title = Array( work_hash[:title] )
        creator = Array( work_hash[:creator] )
        authoremail = work_hash[:authoremail]
        rights_license = build_rights_liscense( hash: work_hash )
        description = Array( work_hash[:description] )
        methodology = work_hash[:methodology] || "No Methodology Available"
        prior_identifier = build_prior_identifier( hash: work_hash, id: id )
        subject_discipline = build_subject_discipline( hash: work_hash )
        contributor = Array( work_hash[:contributor] )
        date_uploaded = build_date( hash: work_hash, key: :date_uploaded )
        date_modified = build_date( hash: work_hash, key: :date_modified )
        date_created = build_date( hash: work_hash, key: :date_created )
        date_coverage = work_hash[:date_coverage]
        resource_type = Array( work_hash[:resource_type] || 'Dataset' )
        language = Array( work_hash[:language] )
        keyword = Array( work_hash[:keyword] )
        referenced_by = build_referenced_by( hash: work_hash )
        fundedby = work_hash[:fundedby]
        grantnumber = work_hash[:grantnumber]

        work = DataSet.new( title: title,
                            creator: creator,
                            authoremail: authoremail,
                            rights_license: rights_license,
                            description: description,
                            resource_type: resource_type,
                            methodology: methodology,
                            prior_identifier: prior_identifier,
                            subject_discipline: subject_discipline,
                            contributor: contributor,
                            date_uploaded: date_uploaded,
                            date_modified: date_modified,
                            date_created: date_created,
                            date_coverage: date_coverage,
                            language: language,
                            keyword: keyword,
                            referenced_by: referenced_by,
                            fundedby: fundedby,
                            grantnumber: grantnumber )

        work.apply_depositor_metadata( user_key )
        work.owner = user_key
        work.visibility = visibility_from_hash( hash: work_hash )
        admin_set = build_admin_set( hash: work_hash )
        work.update( admin_set: admin_set )
        work.save!
        work.reload
        log_provenance_ingest( curation_concern: work )
        return work
      end

      def build_works
        return unless works
        works.each do |work_hash|
          work = build_or_find_work( work_hash: work_hash )
          log_object work if work.present?
        end
      end

      def collections
        @collections ||= collections_from_hash( hash: @cfg_hash[:user] )
      end

      def collections_from_hash( hash: )
        [hash[:collections]]
      end

      def cfg_hash_value( key:, default_value: )
        rv = default_value
        if @cfg_hash.key? :config
          rv = @cfg_hash[:config][key] if @cfg_hash[:config].key? key
        end
        return rv
      end

      def default_admin_set
        @default_admin_set ||= AdminSet.find( AdminSet::DEFAULT_ID )
        # @default_admin_set ||= AdminSet.find_or_create_default_admin_set_id
      end

      def find_or_create_user
        user = User.find_by(user_key: user_key) || create_user(user_key)
        raise UserNotFoundError, "User not found: #{user_key}" if user.nil?
        return user
      end

      def find_work( work_hash: )
        work_id = work_hash[:id]
        id = Array(work_id)
        # owner = Array(work_hash[:owner])
        work = DataSet.find id[0]
        raise UserNotFoundError, "Work not found: #{work_id}" if work.nil?
        return work
      end

      def find_works_and_add_files
        return unless works
        works.each do |work_hash|
          work = find_work( work_hash: work_hash )
          add_file_sets_to_work( work_hash: work_hash, work: work )
          work.apply_depositor_metadata( user_key )
          work.owner = user_key
          work.visibility = visibility_from_hash( hash: work_hash )
          work.save!
          log_object work
        end
      end

      def ingest_id
        @ingest_id ||= @cfg_hash[:user][:ingester]
      end

      def ingester
        @cfg_hash[:user][:ingester]
      end

      # rubocop:disable Rails/Output
      def initialize_with_msg( args:,
                               path_to_yaml_file:,
                               cfg_hash:,
                               base_path:,
                               msg: "NEW CONTENT SERVICE AT YOUR ... SERVICE",
                               **config )

        DeepBlueDocs::Application.config.provenance_log_echo_to_rails_logger = false
        ProvenanceHelper.echo_to_rails_logger = false
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
        logger.info msg unless msg.nil?
      end
      # rubocop:enable Rails/Output

      def log_object( obj )
        logger.info "id: #{obj.id} title: #{obj.title.first}"
      end

      def log_provenance_add_child( parent:, child: )
        return unless parent.respond_to? :provenance_ingest
        parent.provenance_child_add( current_user: user,
                                     child_id: child.id,
                                     ingest_id: ingest_id,
                                     ingester: ingester,
                                     ingest_timestamp: ingest_timestamp )
      end

      def log_provenance_ingest( curation_concern: )
        return unless curation_concern.respond_to? :provenance_ingest
        curation_concern.provenance_ingest( current_user: user,
                                            ingest_id: ingest_id,
                                            ingester: ingester,
                                            ingest_timestamp: ingest_timestamp )
      end

      def logger
        @logger ||= logger_initialize
      end

      def logger_initialize
        # TODO: add some flags to the input yml file for log level and Rails logging integration
        # rubocop:disable Style/Semicolon
        Deepblue::TaskLogger.new(STDOUT).tap { |logger| logger.level = logger_level; Rails.logger = logger }
        # rubocop:enable Style/Semicolon
      end

      def logger_level
        rv = cfg_hash_value( key: :logger_level, default_value: 'info' )
        return rv
      end

      def source
        @source ||= valid_restricted_vocab( @cfg_hash[:user][:source], var: :source, vocab: %w[DBDv1 DBDv2] )
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
