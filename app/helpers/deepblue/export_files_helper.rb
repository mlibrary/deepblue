# frozen_string_literal: true

module Deepblue

  class ExportFilesError < ::StandardError; end

  class ExportFilesChecksumMismatch < ::Deepblue::ExportFilesError
    attr_reader :algorithm
    attr_reader :checksum
    attr_reader :file_name
    attr_reader :file_set_id
    attr_reader :message
    attr_writer :default_message

    def initialize( algorithm:, checksum:, file_set: nil, file_name:, message: nil )
      @algorithm = algorithm
      @checksum = checksum
      @file_set_id = file_set.present? ? file_set.id : ''
      @file_name = file_name
      @message = message
      id = nil
      id = file_set.id if file_set.present?
      id ||= File.basename file_name
      @default_message = "#{id}: checksum mismatch #{checksum}/#{algorithm} for file: #{file_name}"
      @message ||= @default_message
    end

    def to_s
      @message || @default_message
    end
  end

  module ExportFilesHelper

    mattr_accessor :export_files_helper_debug_verbose, default: false

    mattr_accessor :export_files_throw_checksum_mismatch, default: true

    require 'down'

    DEFAULT_LOG_PREFIX = "export_file_sets" unless const_defined? :DEFAULT_LOG_PREFIX
    DEFAULT_QUIET      = false              unless const_defined? :DEFAULT_QUIET

    def self.export_file( file:, target_file:, debug_verbose: export_files_helper_debug_verbose )
      debug_verbose = debug_verbose || export_files_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file=#{file}",
                                             "file.class.name=#{file.class.name}",
                                             "target_file=#{target_file}",
                                             "target_file.class.name=#{target_file.class.name}",
                                             "" ] if debug_verbose
                                             #"Call stack:" ] + caller_locations(1..30) if debug_verbose
      if file.respond_to?(:new_record?) && file.new_record?
        target_file.write(file.content.read) # is this efficient?
        file.content.rewind
        bytes_copied = file.size
      elsif file.respond_to? :uri
        source_uri = file.uri.value
        bytes_copied = export_file_uri( source_uri: source_uri, target_file: target_file, debug_verbose: debug_verbose )
      else
        ::Deepblue::LoggingHelper.bold_error [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "file=#{file}",
                                               "file.class.name=#{file.class.name}",
                                               "target_file=#{target_file}",
                                               "target_file.class.name=#{target_file.class.name}",
                                               "file is not a new_record, and does not have a uri method",
                                               "" ] if debug_verbose
        bytes_copied = 0
      end
      return bytes_copied
    end

    def self.export_file_name( file_name: )
      rv = file_name.gsub( /[\/\?\<\>\\\:\*\|\'\"\^\;]/, '_' )
      return rv
    end

    def self.export_file_name_fs( file_set:, include_id: false )
      title = file_set.title[0]
      file = ::Deepblue::MetadataHelper.file_from_file_set( file_set )
      if file.nil?
        rv = "nil_file"
      else
        rv = file&.original_name
        rv = "nil_original_file" if rv.nil?
      end
      rv = title unless title == rv
      rv = rv.gsub( /[\/\?\<\>\\\:\*\|\'\"\^\;]/, '_' )
      rv = "#{file_set.id}_#{rv}" if include_id
      return rv
    end

    def self.export_file_name_increment( file_name:, count: )
      rv = file_name
      ext = ::File.extname( file_name )
      basename = ::File.basename( file_name, ".*" )
      rv = basename + "_" + count.to_s.rjust( 3, '0' ) + ext
      return rv
    end

    def self.export_file_uri( source_uri:,
                              file_set: nil,
                              target_file:,
                              validate_with_checksum: nil,
                              log_lines: nil,
                              errors: nil,
                              checksum_mismatch_is_error: export_files_throw_checksum_mismatch,
                              debug_verbose: export_files_helper_debug_verbose )

      debug_verbose = debug_verbose || export_files_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "source_uri=#{source_uri}",
                                             "target_file=#{target_file}",
                                             "target_file.class.name=#{target_file.class.name}",
                                             "validate_with_checksum=#{validate_with_checksum}",
                                             "" ] if debug_verbose
      if source_uri.starts_with?( "http:" ) || source_uri.starts_with?( "https:" )
        begin
          # see: https://github.com/janko-m/down
          Down.download( source_uri, destination: target_file )
          bytes_exported = File.size target_file
        rescue Exception => e # rubocop:disable Lint/RescueException
          Rails.logger.error "ExportFilesHelper.export_file_uri(#{source_uri},#{target_file}) #{e.class}: #{e.message} at #{e.backtrace[0]}"
          bytes_exported = URI.open( source_uri ) { |io| IO.copy_stream( io, target_file ) }
        end
      else
        bytes_exported = URI.open( source_uri ) { |io| IO.copy_stream( io, target_file ) }
      end
      rv = export_validate_checksum( validate_with_checksum: validate_with_checksum,
                                     file_set: file_set,
                                     file: target_file,
                                     log_lines: log_lines,
                                     errors: errors,
                                     checksum_mismatch_is_error: checksum_mismatch_is_error,
                                     debug_verbose: debug_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "bytes_exported=#{bytes_exported}",
                                             "" ] if debug_verbose
      return bytes_exported
    end

    def self.export_file_uri_bytes( source_uri: )
      # TODO: replace this with Down gem
      bytes_expected = -1
      URI.open( source_uri ) { |io| bytes_expected = io.meta['content-length'] }
      return bytes_expected
    end

    def self.export_file_sets_fix_file_name( file_set:, files_extracted: )
      # fix possible issues with target file name
      file_name = file_set.label
      file_name = '_nil_' if file_name.nil?
      file_name = '_empty_' if file_name.empty?
      if files_extracted.key? file_name
        dup_count = 1
        ext = File.extname file_name
        basename = File.basename file_name, ext
        file_name = basename + "_" + dup_count.to_s.rjust( 3, '0' ) + ext
        while files_extracted.key? file_name
          dup_count += 1
          file_name = basename + "_" + dup_count.to_s.rjust( 3, '0' ) + ext
        end
      end
      # files_extracted[file_name] = true
      files_extracted[file_name] = file_set.id
      return file_name
    end

    def self.export_file_set?( fs:, filter_viruses: true )
      return false if fs.blank?
      return true if !filter_viruses
      fs.virus_scan_status != ::Deepblue::VirusScanService::VIRUS_SCAN_VIRUS
    end

    def self.export_file_set_id?( id:, filter_viruses: true )
      # TODO: Solr version
      return false if id.blank?
      export_file_set?( fs: PersistHelper.find_or_nil( id ), filter_viruses: filter_viruses )
    end

    def self.export_file_sets( target_dir:,
                               file_sets:,
                               log_prefix: DEFAULT_LOG_PREFIX,
                               do_export_predicate: ->(_target_file_name, _target_file) { true },
                               quiet: DEFAULT_QUIET,
                               &on_export_block )

      LoggingHelper.debug "#{log_prefix} Starting export to #{target_dir}" unless quiet
      files_extracted = {}
      total_bytes = 0
      file_sets.each do |file_set|
        file = file_set.files_to_file
        if file.nil?
          Rails.logger.warn "#{log_prefix} file_set.id #{file_set.id} files[0] is nil"
        else
          # target_file_name = file_set.label
          # # fix possible issues with target file name
          # target_file_name = '_nil_' if target_file_name.nil?
          # target_file_name = '_empty_' if target_file_name.empty?
          # if files_extracted.key? target_file_name
          #   dup_count = 1
          #   base_ext = File.extname target_file_name
          #   base_target_file_name = File.basename target_file_name, base_ext
          #   target_file_name = base_target_file_name + "_" + dup_count.to_s.rjust( 3, '0' ) + base_ext
          #   while files_extracted.key? target_file_name
          #     dup_count += 1
          #     target_file_name = base_target_file_name + "_" + dup_count.to_s.rjust( 3, '0' ) + base_ext
          #   end
          # end
          # files_extracted.store( target_file_name, true )
          target_file_name = export_file_sets_fix_file_name( file_set: file_set, files_extracted: files_extracted )
          target_file = target_dir.join target_file_name
          if do_export_predicate.call( target_file_name, target_file )
            source_uri = file.uri.value
            # LoggingHelper.debug "#{log_prefix} #{source_uri} exists? #{File.exist?( source_uri )}" unless quiet
            LoggingHelper.debug "#{log_prefix} export #{target_file} << #{source_uri}" unless quiet
            bytes_copied = export_file_uri( source_uri: source_uri, target_file: target_file )
            total_bytes += bytes_copied
            copied = DeepblueHelper.human_readable_size( bytes_copied )
            LoggingHelper.debug "#{log_prefix} copied #{copied} to #{target_file}" unless quiet
            on_export_block.call( file_set, target_file_name, target_file ) if on_export_block # rubocop:disable Style/SafeNavigation
          else
            LoggingHelper.debug "#{log_prefix} skipped export of #{target_file}" unless quiet
          end
        end
      end
      total_copied = DeepblueHelper.human_readable_size( total_bytes )
      LoggingHelper.debug "#{log_prefix} Finished export to #{target_dir}; total #{total_copied} in #{files_extracted.size} files" unless quiet
      total_bytes
    end

    def self.export_log_files( msg_handler: nil,
                               src_dir: './log',
                               target_root_dir: nil,
                               debug_verbose: export_files_helper_debug_verbose )

      server_part = export_server_part
      if target_root_dir.blank?
        if ::Deepblue::InitializationConstants::HOSTNAME_LOCAL == server_part
          target_root_dir = "#{File.join( Rails.configuration.shared_drive_volumes_ulib_dbd_prep, 'logs' )}"
        else
          target_root_dir = "#{File.join( Rails.configuration.shared_drive_deepbluedata_prep, 'logs' )}"
        end
      end
      debug_verbose = debug_verbose || export_files_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "src_dir=#{src_dir}",
                                             "target_path=#{target_path}",
                                             "" ] if debug_verbose
      target_dir_path = Time.now.strftime( "%Y%m%d%H%M%S" )
      target_dir_path = "#{target_root_dir}#{server_part}/#{target_dir_path}"
      msg_handler.msg "Target dir is: #{target_dir_path}" unless msg_handler.nil?
      FileUtilsHelper.mkdir_p target_dir_path unless Dir.exist? target_dir_path
      log_path = File.realpath src_dir
      cmd = "ls -l \"#{log_path}/\"*"
      rv = `#{cmd}`
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "cmd=#{cmd}",
                                             "" ] if debug_verbose
      msg_handler.msg rv unless msg_handler.nil?
      cmd = "cp \"#{log_path}/\"* \"#{target_dir_path}\""
      msg_handler.msg cmd unless msg_handler.nil?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "cmd=#{cmd}",
                                             "" ] if debug_verbose
      # rv = `cp #{log_path}/* #{target_dir_path}`
      msg_handler.msg "Copy started at: #{Time.now}" unless msg_handler.nil?
      `#{cmd}`
      # `ls "#{target_path}"`
      msg_handler.msg "Copy finished at: #{Time.now}" unless msg_handler.nil?
    end

    def self.export_server_part
      case Rails.configuration.hostname
      when ::Deepblue::InitializationConstants::HOSTNAME_PROD
        ::Deepblue::InitializationConstants::PRODUCTION
      when ::Deepblue::InitializationConstants::HOSTNAME_TESTING
        ::Deepblue::InitializationConstants::TESTING
      when ::Deepblue::InitializationConstants::HOSTNAME_STAGING
        ::Deepblue::InitializationConstants::STAGING
      when ::Deepblue::InitializationConstants::HOSTNAME_TEST
        ::Deepblue::InitializationConstants::TEST
      when ::Deepblue::InitializationConstants::HOSTNAME_LOCAL
        ::Deepblue::InitializationConstants::LOCAL
      else
        ::Deepblue::InitializationConstants::UNKNOWN
      end
    end

    def self.export_to_temp_file( file:, temp_file:, debug_verbose: export_files_helper_debug_verbose )
      debug_verbose = debug_verbose || export_files_helper_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file=#{file}",
                                             "file.class.name=#{file.class.name}",
                                             "temp_file=#{temp_file}",
                                             "temp_file.class.name=#{temp_file.class.name}",
                                             "" ] if debug_verbose
      export_file( file: file, target_file: temp_file, debug_verbose: debug_verbose )
    end

    def self.export_validate_checksum( validate_with_checksum:,
                                       file:,
                                       file_set: nil,
                                       log_lines: nil,
                                       errors: nil,
                                       checksum_mismatch_is_error: export_files_throw_checksum_mismatch,
                                       debug_verbose: export_files_helper_debug_verbose )

      debug_verbose = debug_verbose || export_files_helper_debug_verbose
      # validate_with_checksum.present? --> of the form [ algorithm, checksum ], algorithm should be sha1
      return true unless validate_with_checksum.present?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "validate_with_checksum=#{validate_with_checksum}",
                                             "file=#{file}",
                                             "errors=#{errors}",
                                             "checksum_mismatch_is_error=#{checksum_mismatch_is_error}",
                                             "" ] if debug_verbose
      algorithm = validate_with_checksum[:algorithm]
      checksum = validate_with_checksum[:checksum]
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "algorithm=#{algorithm}",
                                             "checksum=#{checksum}",
                                             "" ] if debug_verbose
      # TODO: deal with non-SHA1 algorithms
      rv = Digest::SHA1.file file
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "digest rv=#{rv}",
                                             "rv == checksum=#{rv == checksum}",
                                             "" ] if debug_verbose
      rv = rv == checksum
      log_lines << "Checksum #{checksum}/#{algorithm} validated: #{rv}" unless log_lines.nil?
      unless rv
        error = ExportFilesChecksumMismatch.new( file_set: file_set,
                                                 algorithm: algorithm,
                                                 checksum: checksum,
                                                 file_name: file )
        errors << error unless errors.nil?
        raise error if checksum_mismatch_is_error
      end
      return rv
    end

  end

end
