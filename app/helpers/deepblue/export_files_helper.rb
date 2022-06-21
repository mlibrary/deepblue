# frozen_string_literal: true

module Deepblue

  module ExportFilesHelper

    mattr_accessor :export_files_helper_debug_verbose, default: false

    require 'down'

    def self.export_file_uri( source_uri:, target_file: )
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
      return bytes_exported
    end

    def self.export_file_uri_bytes( source_uri: )
      # TODO: replace this with Down gem
      bytes_expected = -1
      URI.open( source_uri ) { |io| bytes_expected = io.meta['content-length'] }
      return bytes_expected
    end

    def self.export_file_sets( target_dir:,
                               file_sets:,
                               log_prefix: "export_file_sets",
                               do_export_predicate: ->(_target_file_name, _target_file) { true },
                               quiet: false,
                               &on_export_block )

      LoggingHelper.debug "#{log_prefix} Starting export to #{target_dir}" unless quiet
      files_extracted = {}
      total_bytes = 0
      file_sets.each do |file_set|
        file = file_set.files_to_file
        if file.nil?
          Rails.logger.warn "#{log_prefix} file_set.id #{file_set.id} files[0] is nil"
        else
          target_file_name = file_set.label
          # fix possible issues with target file name
          target_file_name = '_nil_' if target_file_name.nil?
          target_file_name = '_empty_' if target_file_name.empty?
          if files_extracted.key? target_file_name
            dup_count = 1
            base_ext = File.extname target_file_name
            base_target_file_name = File.basename target_file_name, base_ext
            target_file_name = base_target_file_name + "_" + dup_count.to_s.rjust( 3, '0' ) + base_ext
            while files_extracted.key? target_file_name
              dup_count += 1
              target_file_name = base_target_file_name + "_" + dup_count.to_s.rjust( 3, '0' ) + base_ext
            end
          end
          files_extracted.store( target_file_name, true )
          target_file = target_dir.join target_file_name
          if do_export_predicate.call( target_file_name, target_file )
            source_uri = file.uri.value
            # LoggingHelper.debug "#{log_prefix} #{source_uri} exists? #{File.exist?( source_uri )}" unless quiet
            LoggingHelper.debug "#{log_prefix} export #{target_file} << #{source_uri}" unless quiet
            bytes_copied = export_file_uri( source_uri: source_uri, target_file: target_file )
            total_bytes += bytes_copied
            copied = DeepblueHelper.human_readable_size( bytes_copied )
            LoggingHelper.debug "#{log_prefix} copied #{copied} to #{target_file}" unless quiet
            on_export_block.call( target_file_name, target_file ) if on_export_block # rubocop:disable Style/SafeNavigation
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
                               target_path: nil,
                               debug_verbose: export_files_helper_debug_verbose )

      debug_verbose = debug_verbose || export_files_helper_debug_verbose
      unless target_path.present?
        server_part = case Rails.configuration.hostname
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
        target_dir_name = Time.now.strftime('%Y%m%d')
        target_path = "/deepbluedata-prep/logs/#{server_part}/#{target_dir_name}"
      end
      msg_handler.msg "Target dir is: #{target_path}" unless msg_handler.nil?
      # `ls "/deepbluedata-prep/logs/#{server_part}/"`
      # `ls "/deepbluedata-prep/logs/"`
      FileUtils.mkdir_p target_path unless Dir.exist? target_path

      log_path = File.realpath './log'

      # `ls "#{log_path}"`
      # `ls "#{log_path}/"*`
      # `ls "#{target_path}"`

      src_path = "#{log_path}/"
      # `ls "#{src_path}"`
      # `ls "#{src_path}"*`

      cmd = "cp \"#{src_path}\"* \"#{target_path}\""
      msg_handler.msg "Copy started at: #{Time.now}" unless msg_handler.nil?
      `#{cmd}`
      # `ls "#{target_path}"`
      msg_handler.msg "Copy finished at: #{Time.now}" unless msg_handler.nil?
    end

  end

end
