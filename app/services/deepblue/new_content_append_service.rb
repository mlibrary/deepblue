# frozen_string_literal: true

require_relative './new_content_service'

module Deepblue

  class NewContentAppendService < NewContentService

    attr_accessor :ingest_script
    attr_accessor :msg_handler

    def initialize( msg_handler:, ingest_script:, options: )
      initialize_with( ingest_script: ingest_script, msg_handler: msg_handler, options: options )
    end

    def initialize_with( ingest_script:,
                         msg_handler:,
                         options:,
                         mode: nil,
                         ingester: nil,
                         **config )

      @msg_handler = msg_handler
      @ingest_script = ingest_script

      @options = OptionsHelper.parse options
      if @options.key?( :error ) || @options.key?( 'error' )
        msg_handler.msg_warn "options error #{@options['error']}"
        msg_handler.msg_warn "options=#{options}" if @options.key?( :error )
        msg_handler.msg_warn "@options=#{@options}" if @options.key?( 'error' )
      end
      @base_path = ingest_script.base_path
      @config = {}
      @config.merge!( config ) if config.present?
      @diff_attrs_skip = [] + NewContentService::DEFAULT_DIFF_ATTRS_SKIP
      @diff_attrs_skip_if_blank = [] + NewContentService::DEFAULT_DIFF_ATTRS_SKIP_IF_BLANK
      @diff_user_attrs_skip = [] + NewContentService::DEFAULT_DIFF_USER_ATTRS_SKIP
      @diff_user_attrs_skip.concat Deepblue::MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE
      @email_after_msg_lines = []
      @emails_after = {}
      @emails_before = {}
      @emails_rest = {}
      # @ingest_id = File.basename path_to_yaml_file
      @ingest_timestamp = DateTime.now
      @ingest_urls = []
      @ingester = ingester if ingester.present?
      @mode = mode if mode.present?
      @path_to_yaml_file = ingest_script.ingest_script_path
      @update_add_files = NewContentService::DEFAULT_UPDATE_ADD_FILES
      @update_attrs_skip = [] + NewContentService::DEFAULT_UPDATE_ATTRS_SKIP
      @update_attrs_skip_if_blank = [] + NewContentService::DEFAULT_UPDATE_ATTRS_SKIP_IF_BLANK
      @update_build_mode = NewContentService::DEFAULT_UPDATE_BUILD_MODE
      @update_delete_files = NewContentService::DEFAULT_UPDATE_DELETE_FILES
      @update_user_attrs_skip = [] + NewContentService::DEFAULT_UPDATE_USER_ATTRS_SKIP
      @update_user_attrs_skip.concat Deepblue::MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE
      @verbose = msg_handler.verbose
      log_msg( "@verbose=#{@verbose}", timestamp_it: false ) if @verbose
      @skip_adding_prior_identifier = initialize_options_value( key: :skip_adding_prior_identifier,
                                                                default_value: NewContentService::DEFAULT_SKIP_ADDING_PRIOR_IDENTIFIER )
      @email_test_mode = initialize_options_value( key: :email_test_mode, default_value: NewContentService::DEFAULT_EMAIL_TEST_MODE )
      @email_after = initialize_options_value( key: :email_after, default_value: NewContentService::DEFAULT_EMAIL_AFTER )
      @email_after_add_log_msgs = initialize_options_value( key: :email_after_add_log_msgs,
                                                            default_value: NewContentService::DEFAULT_EMAIL_AFTER_ADD_LOG_MSGS )
      @email_before = initialize_options_value( key: :email_before, default_value: NewContentService::DEFAULT_EMAIL_BEFORE )
      @email_each = initialize_options_value( key: :email_each, default_value: NewContentService::DEFAULT_EMAIL_EACH )
      @email_depositor = initialize_options_value( key: :email_depositor, default_value: NewContentService::DEFAULT_EMAIL_DEPOSITOR )
      @email_ingester = initialize_options_value( key: :email_ingester, default_value: NewContentService::DEFAULT_EMAIL_INGESTER )
      @email_owner = initialize_options_value( key: :email_owner, default_value: NewContentService::DEFAULT_EMAIL_OWNER )
      @email_rest = initialize_options_value( key: :email_rest, default_value: NewContentService::DEFAULT_EMAIL_REST )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
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
      @stop_new_content_service_file = current_dir.join NewContentService::STOP_NEW_CONTENT_SERVICE_FILE_NAME
      @stop_new_content_service_ppid_file = current_dir.join( "#{Process.ppid}_#{NewContentService::STOP_NEW_CONTENT_SERVICE_FILE_NAME}" )
      # log_msg( msg, timestamp_it: false, not_email_line: true )
      log_msg( "mode=#{mode}", timestamp_it: true ) if verbose
    end

    def initialize_options_value( key:, default_value: )
      # # initialize with default value
      # value = default_value
      # # then, override with the value stored from yaml file
      # value = user_hash[key] if user_hash.key? key
      # # finally, override with value passed in on command line
      value = OptionsHelper.value( @options, key: key, default_value: default_value, msg_handler: @msg_handler )
      # puts "initialize_options_value #{key}=#{value}" if @verbose
      return value
    end

    def add_file_sets_to_work_from_files( work_hash:, work: )
      files = work_hash[:files]
      return work if files.blank?
      return super unless work_hash.key? @ingest_script.script_section_key
      file_count = @ingest_script.file_set_count
      max = file_count-1
      for index in 0..max do
        next unless continue_new_content_service
        file_section = @ingest_script.file_section(index)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "index=#{index}",
                                               "file_section=#{file_section.pretty_inspect}",
                                               "" ] if new_content_service_debug_verbose
        path = file_section[:path]
        file_size = add_file_sets_file_size( file_set_hash: nil, path: path )
        fs = build_file_set( id: nil,
                             path: path,
                             work: work,
                             filename: file_section[:filename],
                             file_ids: file_section[:id],
                             file_set_of: index,
                             file_set_count: file_count,
                             file_size: file_size )
        next if fs.blank?
        file_section[:id] = fs.id if file_section[:id].blank?
        @ingest_script.touch
        add_file_set_to_work( work: work, file_set: fs )
        file_section[:added_to_work] = true # TODO: validate this with work
        @ingest_script.job_file_sets_processed_count_add 1
        # TODO: move ingest step here, this will probably fix file_sets that turn up with missing file sizes
      end
      work.save!
      work.reload
      valid_or_fix_file_sizes( curation_concern: work )
      @ingest_script.finished = true
      @ingest_script.touch
      return work
    end

    def cfg_hash
      @ingest_script
    end

    def cfg_hash_value( base_key: :config, key:, default_value: )
      rv = default_value
      if @ingest_script.key? base_key
        rv = @ingest_script[base_key][key] if @ingest_script[base_key].key? key
      end
      return rv
    end

    def collections_from_hash( hash: )
      @ingest_script.array_from( key: :collections, hash: hash )
    end

    def log_error( msg )
      @msg_handler.msg_error msg
    end

    def log_msg( msg, timestamp_it: true, not_email_line: false )
      return if msg.blank?
      msg = "#{timestamp_now} #{msg}" if timestamp_it
      @msg_handler.msg msg
      return if not_email_line
      email_after_msg_lines_add( lines: msg ) if email_after_add_log_msgs
    end

    def run
      validate_config
      build_repo_contents
    rescue RestrictedVocabularyError => e
      msg_handler.msg_error e.message.to_s
    rescue ConfigError => e
      msg_handler.msg_error e.message.to_s
    rescue UserNotFoundError => e
      msg_handler.msg_error e.message.to_s
    rescue VisibilityError => e
      msg_handler.msg_error e.message.to_s
    rescue WorkNotFoundError => e
      msg_handler.msg_error e.message.to_s
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg_handler.msg_error "#{e.class}: #{e.message} at #{e.backtrace[0]}"
    end

    def users_from_hash( hash: )
      @ingest_script.array_from( key: :users, hash: hash )
    end

    def user_hash
      @ingest_script.user_section
    end

    # config needs default user to attribute collections/works/filesets to
    # User needs to have only works or collections
    def validate_config
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@ingest_script=#{@ingest_script.pretty_inspect}",
                                             "@ingest_script.key? :user=#{@ingest_script.key? :user}",
                                             "" ] if new_content_service_debug_verbose
      raise ConfigError, "Top level keys needs to contain 'user'" unless @ingest_script.key? :user
    end

    def works_from_hash( hash: )
      @ingest_script.array_from( key: :works, hash: hash )
    end

  end

end
