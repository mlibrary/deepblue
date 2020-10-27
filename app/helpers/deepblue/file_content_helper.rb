# frozen_string_literal: true

module Deepblue

  module FileContentHelper

    @@_setup_ran = false

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    @@file_content_helper_debug_verbose = false
    @@read_me_file_set_enabled = true
    @@read_me_file_set_auto_read_me_attach = true
    @@read_me_file_set_file_name_regexp = /read[_ ]?me/i
    @@read_me_file_set_view_max_size = 500.kilobytes
    @@read_me_file_set_view_mime_types = [ "text/plain", "text/markdown" ].freeze
    @@read_me_file_set_ext_as_html = [ ".md" ].freeze
    @@read_me_max_find_file_sets = 40

    mattr_accessor  :file_content_helper_debug_verbose,
                    :read_me_file_set_enabled,
                    :read_me_file_set_auto_read_me_attach,
                    :read_me_file_set_file_name_regexp,
                    :read_me_file_set_view_max_size,
                    :read_me_file_set_view_mime_types,
                    :read_me_file_set_ext_as_html,
                    :read_me_max_find_file_sets


    def self.t( key, **options )
      I18n.t( key, options )
    end

    def self.translate( key, **options )
      I18n.translate( key, options )
    end

    def self.can_assign_as_read_me?( id1:, id2:, file_size: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "false unless not right mime_type=#{read_me_file_set_view_mime_types.include? mime_type}",
                                             "false if too big=#{file_size > read_me_file_set_view_max_size}",
                                             "" ] if file_content_helper_debug_verbose
      return false unless read_me_file_set_enabled
      return false unless read_me_file_set_view_mime_types.include? mime_type
      return false if file_size > read_me_file_set_view_max_size
      return can_edit_file?
    end

    def self.downgrade_html_headers!( html_text: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "html_text=#{html_text}",
                                             "" ] if file_content_helper_debug_verbose
      html_text.gsub!(/<h6( [^<>]*)?>/, '<em>')
      html_text.gsub!(/<\/h6( [^<>]*)?>/, '</em><br />')
      html_text.gsub!(/<h5( [^<>]*)?>/, '<h6>')
      html_text.gsub!(/<\/h5( [^<>]*)?>/, '</h6>')
      html_text.gsub!(/<h4( [^<>]*)?>/, '<h5>')
      html_text.gsub!(/<\/h4( [^<>]*)?>/, '</h5>')
      html_text.gsub!(/<h3( [^<>]*)?>/, '<h4>')
      html_text.gsub!(/<\/h3( [^<>]*)?>/, '</h4>')
      html_text.gsub!(/<h2( [^<>]*)?>/, '<h3>')
      html_text.gsub!(/<\/h2( [^<>]*)?>/, '</h3>')
      html_text.gsub!(/<h1( [^<>]*)?>/, '<h2>')
      html_text.gsub!(/<\/h1( [^<>]*)?>/, '</h2>')
      html_text
    end

    def self.find_read_me_file_set( work:, raise_error: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work.id=#{work.id}",
                                             "work.read_me_file_set_id=#{work.read_me_file_set_id}",
                                             "" ] if file_content_helper_debug_verbose
      regexp = read_me_file_set_file_name_regexp
      candidates = []
      work.file_sets.each_with_index do |fs,index|
        break if index > read_me_max_find_file_sets
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "fs.mime_type=#{File.basename( fs.mime_type )}",
        #                                        "fs.original_file.size=#{fs.original_file.size}",
        #                                        "File.basename( fs.label )=#{File.basename( fs.label )}",
        #                                        "" ] if file_content_helper_debug_verbose
        if read_me_file_set_view_mime_types.include? fs.mime_type
          if fs.original_file.size <= read_me_file_set_view_max_size
            rv = File.basename( fs.label ) =~ regexp
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                   ::Deepblue::LoggingHelper.called_from,
                                                   "File.basename( fs.label )=#{File.basename( fs.label )}",
                                                   "" ] if rv && file_content_helper_debug_verbose
            candidates << fs
          end
        end
      end
      return nil if candidates.empty?
      # TODO: want to report this out
      return candidates.first
    rescue Exception => e
      raise if raise_error
      nil
    end

    def self.find_read_me_file_set_if_necessary( work:, raise_error: false )
      return unless read_me_file_set_auto_read_me_attach
      return if work.read_me_file_set_id.present?
      fs = find_read_me_file_set( work: work, raise_error: raise_error )
      return if fs.blank?
      work.read_me_file_set_id = fs.id
      work.save!
    end

    def self.read_file( file_set: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set.id}",
                                             "" ] if file_content_helper_debug_verbose
      file = file_set.files_to_file
      if file.nil?
        return nil
      else
        source_uri = file.uri.value
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "source_uri=#{source_uri}",
                                               "" ] if file_content_helper_debug_verbose
        str = open( source_uri, "r" ) { |io| io.read }
        # str = open( source_uri, "r" ) { |io| io.read.encode( "UTF-8",
        #                                                      invalid: :replace,
        #                                                      undef: :replace,
        #                                                      replace: '?' ) }
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "str.encoding=#{str.encoding}",
                                               "" ] if file_content_helper_debug_verbose
        case str.encoding.name
        when 'UTF-8'
          # do nothing
        when 'ASCII-8BIT'
          # str = str.encode( 'UTF-8', 'ASCII-8BIT' )
          str = str.force_encoding('ISO-8859-1').encode( 'UTF-8' )
        when Encoding::US_ASCII.name
          str = str.encode( 'UTF-8', Encoding::US_ASCII.name )
        when 'ISO-8859-1'
          str = str.encode( 'UTF-8', 'ISO-8859-1' )
        when 'Windows-1252'
          str = str.encode( 'UTF-8', 'Windows-1252' )
        else
          # TODO: check to see encoding to UTF-8 is possible/supported
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "Unspecified encoding '#{str.encoding}' trying generic conversion to UTF-8",
                                                 "" ] if file_content_helper_debug_verbose
          str = str.encode( 'UTF-8', invalid: :replace, undef: :replace )
        end
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "str.encoding=#{str.encoding}",
                                               "" ] if file_content_helper_debug_verbose
        return str
      end
      return nil
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "read_file.read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error msg
      return nil
    end

    def self.read_file_as_html( file_set: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set.id=#{file_set.id}",
                                             "" ] if file_content_helper_debug_verbose
      text = read_file( file_set: file_set )
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "text=#{text}",
      #                                        "" ] if file_content_helper_debug_verbose
      return text if text.blank?
      html_text = ::Deepblue::MarkdownService.markdown text
      downgrade_html_headers! html_text: html_text
    end

    def self.read_from( uri: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "uri=#{uri}",
                                             "" ] if file_content_helper_debug_verbose
      text = open( uri, "r:UTF-8" ) { |io| io.read }
      return text
    end

    def self.read_me_is_html?( file_set: )
      return false unless file_set.present?
      ext = File.extname file_set.label
      [ ".md" ].include? ext.downcase
    end

    def self.read_me_file_set( work:, raise_error: false )
      return nil if work.blank?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work.id=#{work.id}",
                                             "work.read_me_file_set_id=#{work.read_me_file_set_id}",
                                             "" ] if file_content_helper_debug_verbose
      id = work.read_me_file_set_id
      if id.present?
        FileSet.find id
      elsif read_me_file_set_auto_read_me_attach
        fs = find_read_me_file_set( work: work, raise_error: raise_error )
        return nil if fs.blank?
        work.read_me_file_set_id = fs.id
        # TODO: might have to touch the file
        work.save!
        fs
      else
        nil
      end
    end

    def self.send_file( id:, format: nil, path:, options: {} )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "format=#{format}",
                                             "path=#{path}",
                                             "options=#{options}",
                                             "" ] if file_content_helper_debug_verbose
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
                                               "" ] if file_content_helper_debug_verbose

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

  end

end
