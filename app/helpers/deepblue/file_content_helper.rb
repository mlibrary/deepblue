# frozen_string_literal: true

module Deepblue

  module FileContentHelper

    FILE_CONTENT_HELPER_DEBUG_VERBOSE = true

    def self.t( key, **options )
      I18n.t( key, options )
    end

    def self.translate( key, **options )
      I18n.translate( key, options )
    end

    def self.find_read_me_file_set( work: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work.id=#{work.id}",
                                             "work.read_me_file_set_id=#{work.read_me_file_set_id}",
                                             "" ] if FILE_CONTENT_HELPER_DEBUG_VERBOSE
      regexp = ::DeepBlueDocs::Application.config.read_me_file_set_file_name_regexp
      candidates = work.file_sets.select do |fs|
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "fs.mime_type=#{File.basename( fs.mime_type )}",
        #                                        "fs.original_file.size=#{fs.original_file.size}",
        #                                        "File.basename( fs.label )=#{File.basename( fs.label )}",
        #                                        "" ] if FILE_CONTENT_HELPER_DEBUG_VERBOSE
        if ::DeepBlueDocs::Application.config.read_me_file_set_view_mime_types.include? fs.mime_type
          if fs.original_file.size <= ::DeepBlueDocs::Application.config.read_me_file_set_view_max_size
            rv = File.basename( fs.label ) =~ regexp
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "File.basename( fs.label )=#{File.basename( fs.label )}",
                                                   "" ] if rv && FILE_CONTENT_HELPER_DEBUG_VERBOSE
            rv
          else
            false
          end
        else
          false
        end
      end
      return nil if candidates.empty?
      # TODO: want to report this out
      return candidates.first
    end

    def self.send_file( id:, format: nil, path:, options: {} )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "format=#{format}",
                                             "path=#{path}",
                                             "options=#{options}",
                                             "" ] if FILE_CONTENT_HELPER_DEBUG_VERBOSE
      file_set = FileSet.find id
      source_uri = nil
      file = file_set.files_to_file
      if file.nil?
        file_content_send_msg "file_set.id #{file_set.id} files_to_file returned nil"
      else
        source_uri = file.uri.value
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "source_uri=#{source_uri}",
                                               "" ] if FILE_CONTENT_HELPER_DEBUG_VERBOSE

        case file_set.mime_type
        when "text/html"
          send_data read_from( uri: source_uri ), disposition: 'inline', type: file_set.mime_type
          # send_data open( source_uri, "r:UTF-8" ) { |io| io.read }, disposition: 'inline', type: file_set.mime_type
        when "text/plain"
          if format == "html"
            send_data read_from( uri: source_uri ), disposition: 'inline', type: "text/html"
            # send_data open( source_uri, "r:UTF-8" ) { |io| io.read }, disposition: 'inline', type: "text/html"
          else
            send_data read_from( uri: source_uri ), disposition: 'inline', type: file_set.mime_type
            # send_data open( source_uri, "r:UTF-8" ) { |io| io.read }, disposition: 'inline', type: file_set.mime_type
          end
        when /^image\//
          send_data open( source_uri, "rb" ) { |io| io.read }, disposition: 'inline', type: file_set.mime_type
        else
          file_content_send_msg "Unhandled mime type for file_set.id #{file_set.id} #{file_set.mime_type}"
        end
      end
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "FileContentHelpoer.read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0..19].join("\n")}"
      Rails.logger.error msg
    end

    def self.read_file( file_set: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set.id}",
                                             "" ] if FILE_CONTENT_HELPER_DEBUG_VERBOSE
      file = file_set.files_to_file
      if file.nil?
        return nil
      else
        source_uri = file.uri.value
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "source_uri=#{source_uri}",
                                               "" ] if FILE_CONTENT_HELPER_DEBUG_VERBOSE
        str = open( source_uri, "r:UTF-8" ) { |io| io.read }
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "str.encoding=#{str.encoding}",
                                               "" ] if FILE_CONTENT_HELPER_DEBUG_VERBOSE
        return str
      end
      return nil
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "WorkViewContentService.static_content_read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error msg
      return nil
    end

    def self.read_from( uri: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "uri=#{uri}",
                                             "" ] if FILE_CONTENT_HELPER_DEBUG_VERBOSE
      text = open( uri, "r:UTF-8" ) { |io| io.read }
      return text
    end

    def self.read_me_file_set( work: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work.id=#{work.id}",
                                             "work.read_me_file_set_id=#{work.read_me_file_set_id}",
                                             "" ] if FILE_CONTENT_HELPER_DEBUG_VERBOSE
      id = work.read_me_file_set_id
      if id.present?
        FileSet.find id
      elsif ::DeepBlueDocs::Application.config.read_me_file_set_auto_read_me_attach
        fs = find_read_me_file_set( work: work )
        return nil if fs.blank?
        work.read_me_file_set_id = fs.id
        # TODO: might have to touch the file
        work.save!
        fs
      else
        nil
      end
    end

  end

end
