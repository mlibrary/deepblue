# frozen_string_literal: true

require_relative './new_content_service2'

module Deepblue

  class NewContentAppendService < NewContentService2

    mattr_accessor :new_content_append_service_debug_verbose, default: false

    mattr_accessor :new_content_append_service_add_debug_verbose, default: false
    mattr_accessor :new_content_append_service_touch_debug_verbose, default: false

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
      @diff_attrs_skip = [] + NewContentService2::DEFAULT_DIFF_ATTRS_SKIP
      @diff_attrs_skip_if_blank = [] + NewContentService2::DEFAULT_DIFF_ATTRS_SKIP_IF_BLANK
      @diff_user_attrs_skip = [] + NewContentService2::DEFAULT_DIFF_USER_ATTRS_SKIP
      @diff_user_attrs_skip.concat Deepblue::MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE
      @email_after_msg_lines = []
      @emails_after = {}
      @emails_before = {}
      @emails_rest = {}
      @ingest_timestamp = DateTime.now
      @ingest_urls = []
      @ingester = ingester if ingester.present?
      @mode = mode if mode.present?
      @path_to_yaml_file = ingest_script.ingest_script_path
      @update_add_files = NewContentService2::DEFAULT_UPDATE_ADD_FILES
      @update_attrs_skip = [] + NewContentService2::DEFAULT_UPDATE_ATTRS_SKIP
      @update_attrs_skip_if_blank = [] + NewContentService2::DEFAULT_UPDATE_ATTRS_SKIP_IF_BLANK
      @update_build_mode = NewContentService2::DEFAULT_UPDATE_BUILD_MODE
      @update_delete_files = NewContentService2::DEFAULT_UPDATE_DELETE_FILES
      @update_user_attrs_skip = [] + NewContentService2::DEFAULT_UPDATE_USER_ATTRS_SKIP
      @update_user_attrs_skip.concat Deepblue::MetadataHelper::ATTRIBUTE_NAMES_USER_IGNORE
      @verbose = msg_handler.verbose
      log_msg( "@verbose=#{@verbose}", timestamp_it: false ) if @verbose
      @skip_adding_prior_identifier = initialize_options_value( key: :skip_adding_prior_identifier,
                                                                default_value: NewContentService2::DEFAULT_SKIP_ADDING_PRIOR_IDENTIFIER )
      @email_test_mode = initialize_options_value( key: :email_test_mode, default_value: NewContentService2::DEFAULT_EMAIL_TEST_MODE )
      @email_after = initialize_options_value( key: :email_after, default_value: NewContentService2::DEFAULT_EMAIL_AFTER )
      @email_after_add_log_msgs = initialize_options_value( key: :email_after_add_log_msgs,
                                                            default_value: NewContentService2::DEFAULT_EMAIL_AFTER_ADD_LOG_MSGS )
      @email_before = initialize_options_value( key: :email_before, default_value: NewContentService2::DEFAULT_EMAIL_BEFORE )
      @email_each = initialize_options_value( key: :email_each, default_value: NewContentService2::DEFAULT_EMAIL_EACH )
      @email_depositor = initialize_options_value( key: :email_depositor, default_value: NewContentService2::DEFAULT_EMAIL_DEPOSITOR )
      @email_ingester = initialize_options_value( key: :email_ingester, default_value: NewContentService2::DEFAULT_EMAIL_INGESTER )
      @email_owner = initialize_options_value( key: :email_owner, default_value: NewContentService2::DEFAULT_EMAIL_OWNER )
      @email_rest = initialize_options_value( key: :email_rest, default_value: NewContentService2::DEFAULT_EMAIL_REST )
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
                                             "" ] if new_content_append_service_debug_verbose
      initialize_emails_rest
      @user_create = user_create
      @stop_new_content_service = false
      current_dir = Pathname.new( '.' ).realdirpath
      @stop_new_content_service_file = current_dir.join NewContentService2::STOP_NEW_CONTENT_SERVICE_FILE_NAME
      @stop_new_content_service_ppid_file = current_dir.join( "#{Process.ppid}_#{NewContentService2::STOP_NEW_CONTENT_SERVICE_FILE_NAME}" )
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
      debug_verbose = new_content_append_service_add_debug_verbose || new_content_append_service_debug_verbose
      verbose = msg_handler.verbose
      if  @ingest_script.finished?
        msg_handler.msg "Skipping add_file_sets_to_work_from_files because ingest script finished." if verbose
        return work
      end
      @ingest_script.script_section[:stop_new_content_service_file] = @stop_new_content_service_file.to_s
      touch_ingest_script
      no_duplicate_file_names = work_hash[:no_duplicate_file_names]
      no_duplicate_file_names ||= false
      max_appends = @ingest_script.script_section[:max_appends]
      msg_handler.msg_verbose "max_appends=#{max_appends}"
      run_count = @ingest_script.script_section[:run_count]
      msg_handler.msg_verbose "run_count=#{run_count}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "no_duplicate_file_names=#{no_duplicate_file_names}",
                                             "max_appends=#{max_appends}",
                                             "run_count=#{run_count}",
                                             "" ] if debug_verbose
      file_count = @ingest_script.file_set_count
      touched_work = false
      max = file_count - 1
      files_appended = 0
      files_added_or_appended = 0
      for index in 0..max do
        next unless continue_new_content_service
        msg_handler.msg_debug "Processing file index #{index} of 0..#{max}" if debug_verbose
        msg_handler.msg_verbose "Processing file index #{index} of 0..#{max}" if verbose
        file_section = @ingest_script.file_section(index)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "index=#{index}",
                                               "file_section=#{file_section.pretty_inspect}",
                                               "" ] if debug_verbose
        fid = file_section[:id]
        if no_duplicate_file_names
          # look up the first file set with a name that matches this file
          # work.first_file_set_with_name( file_section[:filename] )
          # set's name, then set fid based on found file set
        end
        if fid.present?
          msg_handler.msg_debug "File index #{index} has #{fid}, skipping build." if debug_verbose
          msg_handler.msg_verbose "File index #{index} has #{fid}, skipping build." if verbose
          fs = nil
        else
          path = file_section[:path]
          file_size = add_file_sets_file_size( file_set_hash: nil, path: path )
          msg_handler.msg_debug "Building file index #{index}." if debug_verbose
          msg_handler.msg_verbose "Building file index #{index}." if verbose
          fs = build_file_set( id: nil,
                               path: path,
                               work: work,
                               filename: file_section[:filename],
                               file_ids: file_section[:id],
                               file_set_of: index,
                               file_set_count: file_count,
                               file_size: file_size )
          next if fs.blank?
          file_section[:id] = fs.id
        end
        added_to_work = file_section[:added_to_work]
        if added_to_work
          files_added_or_appended += 1
          msg_handler.msg_debug "File index #{index} with #{fid} already added to work." if debug_verbose
          msg_handler.msg_verbose "File index #{index} with #{fid} already added to work." if verbose
        else
          fs = PersistHelper.find_or_nil( fid ) if fid.present? && fs.blank?
          next if fs.blank?
          msg_handler.msg_debug "Adding file index #{index} with #{fs.id} to work." if debug_verbose
          msg_handler.msg_verbose "Adding file index #{index} with #{fs.id} to work." if verbose
          add_file_set_to_work( work: work, file_set: fs )
          touched_work = true
          # TODO: move ingest step here, this will probably fix file_sets that turn up with missing file sizes
          files_appended += 1
          files_added_or_appended += 1
          file_section[:added_to_work] = true # TODO: validate that the file set was added to work
          @ingest_script.job_file_sets_processed_count_add 1
          touch_ingest_script
          if max_appends > -1 && files_appended >= max_appends
            msg_handler.msg_debug "Max appends (#{max_appends}) exceeded at file index #{index}, stop appending." if debug_verbose
            msg_handler.msg_verbose "Max appends (#{max_appends}) exceeded at file index #{index}, stop appending." if verbose
            break
          end
        end
      end
      if touched_work
        msg_handler.msg_debug "Saving work." if debug_verbose
        msg_handler.msg_verbose "Saving work." if verbose
        work.save!
        work.reload
        valid_or_fix_file_sizes( curation_concern: work )
      end
      if files_added_or_appended >= file_count
        msg_handler.msg_debug "Setting finished to true." if debug_verbose
        msg_handler.msg_verbose "Setting finished to true." if verbose
        @ingest_script.finished = true
        @ingest_script.active = false
      else
        msg_handler.msg_debug "Setting finished to false." if debug_verbose
        msg_handler.msg_verbose "Setting finished to false." if verbose
        @ingest_script.finished = false
      end
      return work
    ensure
      touch_ingest_script
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
    ensure
      touch_ingest_script
    end

    def touch_ingest_script
      debug_verbose = new_content_append_service_touch_debug_verbose || new_content_append_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if debug_verbose
      @ingest_script.log_indexed_save( msg_handler.msg_queue,
                                       source: self.class.name ) if msg_handler.present? && @ingest_script.present?
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
                                             "" ] if new_content_append_service_debug_verbose
      raise ConfigError, "Top level keys needs to contain 'user'" unless @ingest_script.key? :user
    end

    def works_from_hash( hash: )
      @ingest_script.array_from( key: :works, hash: hash )
    end

  end

end
