# frozen_string_literal: true

module Deepblue

  module StaticContentControllerBehavior
    include Deepblue::WorkViewContentService

    mattr_accessor :static_content_cache
    @@static_content_cache = {}
    mattr_accessor :static_content_controller_behavior_verbose
    self.static_content_controller_behavior_verbose = false
    mattr_accessor :static_content_cache_debug_verbose
    self.static_content_cache_debug_verbose = false
    mattr_accessor :static_content_controller_behavior_menu_verbose
    self.static_content_controller_behavior_menu_verbose = false

    mattr_accessor :work_view_content_enable_cache
    self.work_view_content_enable_cache = ::DeepBlueDocs::Application.config.static_content_enable_cache

    def self.static_content_documentation_collection_id
      WorkViewContentService.content_documentation_collection_id
    end

    def self.static_content_cache_id( key:, id: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ">+++++++++ storing to cache ++++++++++<",
                                             "key=#{key}",
                                             "id=#{id}",
                                             "" ] if static_content_controller_behavior_verbose ||
                                                     static_content_cache_debug_verbose
      @@static_content_cache ||= {}
      @@static_content_cache[key] = id
    end

    def self.static_content_cache_get( key: )
      @@static_content_cache ||= {}
      value = @@static_content_cache[key]
      if value.present?
        status = ">[[[[[[[[[[[ retrieved from cache ]]]]]]]]]]]<"
      else
        status = ">---------- not in cache ----------<"
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             status,
                                             "key=#{key}",
                                             "rv=#{value}",
                                             "" ] if static_content_controller_behavior_verbose ||
                                                     static_content_cache_debug_verbose
      return value
    end

    def self.static_content_cache_reset
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if static_content_controller_behavior_verbose
      @@static_content_cache = {}
      return nil
    end

    def self.static_content_find_by_id( id:, cache_id_with_key: nil, raise_error: false )
      return nil if id.blank?
      content = ActiveFedora::Base.find( id )
      return content unless work_view_content_enable_cache
      if content.present? && cache_id_with_key.present?
        return content if @@static_content_cache.key?( cache_id_with_key )
        StaticContentControllerBehavior.static_content_cache_id( key: cache_id_with_key, id: content.id )
      end
      return content
    rescue Ldp::Gone
      raise if raise_error
      return nil
    rescue ActiveFedora::ObjectNotFoundError
      raise if raise_error
      return nil
    end


    attr_reader :static_content_menu,
                :static_content_menu_file_format,
                :static_content_menu_header,
                :static_content_menu_links,
                :static_content_menu_partial,
                :static_content_page_navigation

    def static_content_menu_debug_verbose
      static_content_controller_behavior_menu_verbose
    end

    def documentation_work_title_prefix
      WorkViewContentService.documentation_work_title_prefix
    end

    def documentation_email_title_prefix
      WorkViewContentService.documentation_email_title_prefix
    end

    def documentation_i18n_title_prefix
      WorkViewContentService.documentation_i18n_title_prefix
    end

    def static_content_documentation_collection
      id = StaticContentControllerBehavior::static_content_documentation_collection_id
      collection = Collection.find( id )
      return collection
    end

    def static_content_find_documentation_work_by_title( title: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "" ] if static_content_controller_behavior_verbose
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_cache_get( key: title )
        work = static_content_find_by_id( id: id )
        return work if work.present?
      end
      static_content_documentation_collection.member_works.each do |work|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "#{work.title.first} == #{title} ?",
                                               "" ] if static_content_controller_behavior_verbose
        if work.title.first == title
          if work_view_content_enable_cache
            StaticContentControllerBehavior.static_content_cache_id( key: title, id: work.id )
          end
          return work
        end
      end
      return nil
    end

    def static_content_find_documentation_file_set( work_title:, file_name:, path: )
      path = "/#{work_title}/#{file_name}" if path.blank?
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_cache_get( key: path )
        content = static_content_find_by_id( id: id )
        return content if content.present?
      end
      work = static_content_find_documentation_work_by_title( title: work_title )
      return nil if work.blank?
      work.file_sets.each do |fs|
        if fs.title.first == file_name
          if work_view_content_enable_cache
            StaticContentControllerBehavior.static_content_cache_id( key: path, id: fs.id )
          end
          return fs
        end
      end
      return nil
    end

    def static_content_find_by_id( id:, cache_id_with_key: nil, raise_error: false )
      StaticContentControllerBehavior.static_content_find_by_id( id: id,
                                                                 cache_id_with_key: cache_id_with_key,
                                                                 raise_error: raise_error )
    end

    def static_content_file_set( work_title:, file_set_title:, path:, **options )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "path=#{path}",
                                             "options=#{options}",
                                             "" ] if static_content_controller_behavior_verbose
      path = "/#{work_title}/#{file_set_title}" if path.blank?
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_cache_get( key: path )
        file_set = static_content_find_by_id( id: id ) if id.present?
        return file_set if file_set.present?
      end
      work = static_content_find_work_by_title( title: work_title, id: id )
      return nil unless work
      file_set = static_content_work_file_set_find_by_title( work: work,
                                                             work_title: work_title,
                                                             file_set_title: file_set_title,
                                                             path: path )
      file_set
    end

    def static_content_find_by_title( title:, id:, solr_query: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "id=#{id}",
                                             "" ] if static_content_controller_behavior_verbose
      content = static_content_find_by_id( id: id, cache_id_with_key: title ) unless id.blank?
      return content if content.present?
      if title.size == 9
        # guess that it is an id, and not a title
        content = static_content_find_by_id( id: title, cache_id_with_key: title )
        return content if content.present?
      end
      if title.start_with?( documentation_work_title_prefix )
        content = static_content_find_documentation_work_by_title( title: title )
        return content if content.present?
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_query=#{solr_query}",
                                             "" ] if static_content_controller_behavior_verbose
      results = ::ActiveFedora::SolrService.query( solr_query, rows: 10 )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "results=#{results}",
                                             "" ] if static_content_controller_behavior_verbose
      if results.present? && results.size > 0
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "results[0]=#{results[0]}",
                                               "results[0].id=#{results[0].id}",
                                               "" ] if static_content_controller_behavior_verbose
        id = results[0].id
        content = static_content_find_by_id( id: id, cache_id_with_key: title )
        return content if content.present?
      end
      return nil
    end

    def static_content_find_collection_by_title( title:, id: nil )
      static_content_find_by_title( title: title,
                                    id: id,
                                    solr_query: "+generic_type_sim:Collection AND +title_tesim:#{title}" )
    end

    def static_content_find_work_by_title( title:, id: )
      static_content_find_by_title( title: title,
                                    id: id,
                                    solr_query: "+generic_type_sim:Work AND +title_tesim:#{title}" )
    end

    def static_content_for( work_title:, file_set_title:, path:, **options )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "path=#{path}",
                                             "options=#{options}",
                                             "" ] if static_content_controller_behavior_verbose
      path = "/#{work_title}/#{file_set_title}" if path.blank?
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_cache_get( key: path )
        return static_content_read_file( id: id ) unless id.blank?
      end
      work = static_content_find_work_by_title( title: work_title, id: id )
      return "" unless work
      file_set = static_content_work_file_set_find_by_title( work: work,
                                                             work_title: work_title,
                                                             file_set_title: file_set_title,
                                                             path: path )
      static_content_send_file( file_set: file_set, format: options[:format], path: path )
    end

    def static_content_for_read_file( work_title:, file_set_title:, path:, **options )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "path=#{path}",
                                             "options=#{options}",
                                             "" ] if static_content_controller_behavior_verbose
      path = "/#{work_title}/#{file_set_title}" if path.blank?
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_cache_get( key: path )
        return static_content_read_file( id: id ) unless id.blank?
      end
      work_id = StaticContentControllerBehavior.static_content_cache_get( key: work_title )
      work = static_content_find_work_by_title( title: work_title, id: work_id )
      return "" unless work
      file_set = static_content_work_file_set_find_by_title( work: work,
                                                             work_title: work_title,
                                                             file_set_title: file_set_title,
                                                             path: path )
      static_content_read_file( file_set: file_set )
    end

    def static_content_load_menu_file( work_title:, file_name:, path: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_name=#{file_name}",
                                             "path=#{path}",
                                             "" ] if static_content_controller_behavior_verbose
      @static_content_menu_file_format = File.extname file_name
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@static_content_menu_file_format=#{@static_content_menu_file_format}",
                                             "" ] if static_content_controller_behavior_verbose
      case @static_content_menu_file_format
      when '.yml'
        file = static_content_for_read_file( work_title: work_title, file_set_title: file_name, path: path )
        @static_content_menu_links = YAML.load file
      when '.yaml'
        file = static_content_for_read_file( work_title: work_title, file_set_title: file_name, path: path )
        @static_content_menu_links = YAML.load file
      when '.txt'
        @static_content_menu_links = static_content_for_read_file( work_title: work_title,
                                                                   file_set_title: file_name,
                                                                   path: path ).split( "\n" )
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@static_content_menu_links=#{@static_content_menu_links}",
                                             "" ] if static_content_controller_behavior_verbose
    end

    def static_content_main( params )
      work_title = params[:doc]
      if params[:format]
        file_set_title = "#{params[:file]}.#{params[:format]}"
      else
        file_set_title = "#{params[:file]}.html"
      end
      static_content_for( work_title: work_title, file_set_title: file_set_title, path: nil )
    end

    def static_content_options_from( file_set:, work_title:, file_id:, format: )
      options = {}
      return options if file_set.nil?
      description = Array(file_set.description_file_set)
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "description=#{description}",
                                             "" ] if static_content_controller_behavior_verbose
      return options if description.blank?
      lines = description.join("\n").split("\n")
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "lines=#{lines}",
                                             "" ] if static_content_controller_behavior_verbose
      lines.each do |line|
        case line.strip
        when /^menu:(.+)$/
          options[:menu] = Regexp.last_match(1).strip
          static_content_set_menu( value: options[:menu], work_title: work_title, file_id: file_id, format: format )
        when /^menu_header:(.+)$/
          @static_content_menu_header = Regexp.last_match(1).strip
          options[:menu_header] = @static_content_menu_header
        when /^render_with:(.+)$/
          options[:render_with] = Regexp.last_match(1).strip
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "options=#{options}",
                                             "" ] if static_content_controller_behavior_verbose
      return options
    end

    def static_content_read_file( file_set: nil, id: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set&.id}",
                                             "id=#{id}",
                                             "" ] if static_content_controller_behavior_verbose
      file_set = static_content_find_by_id( id: id ) unless id.blank?
      return "" if file_set.blank?
      file = file_set.files_to_file
      if file.nil?
        return "file_set.id #{file_set.id} files[0] is nil"
      else
        source_uri = file.uri.value
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "source_uri=#{source_uri}",
                                               "" ] if static_content_controller_behavior_verbose
        str = open( source_uri, "r:UTF-8" ) { |io| io.read }
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "str.encoding=#{str.encoding}",
                                               "" ] if static_content_controller_behavior_verbose
        return str
      end
      return ""
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "StaticContentControllerBehavior.static_content_read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error msg
      return msg
    end

    def static_content_render?( mime_type: )
      # look up file_set and set mime_type
      case mime_type
      when "text/html", "text/plain"
        true
      else
        false
      end
    end

    def static_content_send( file_set:, format:, path:, options: {} )
      static_content_send_file( file_set: file_set, format: format, path: path, options: options )
    end

    def static_content_send_file( file_set: nil, id: nil, format: nil, path:, options: {} )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set&.id=#{file_set&.id}",
                                             "id=#{id}",
                                             "format=#{format}",
                                             "path=#{path}",
                                             "options=#{options}",
                                             "" ] if static_content_controller_behavior_verbose
      file_set = static_content_find_by_id( id: id ) if file_set.nil? && id.present?
      source_uri = nil
      if file_set.nil? && id.blank?
        static_content_send_msg "file_set and id both nil"
      elsif file_set.nil?
        static_content_send_msg "failed to find file_set with id #{id}"
      else
        file = file_set.files_to_file
        if file.nil?
          static_content_send_msg "file_set.id #{file_set.id} files_to_file returned nil"
        else
          source_uri = file.uri.value
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "source_uri=#{source_uri}",
                                                 "" ] if static_content_controller_behavior_verbose

          case file_set.mime_type
          when "text/html"
            send_data static_read_text_from( uri: source_uri ), disposition: 'inline', type: file_set.mime_type
            # send_data open( source_uri, "r:UTF-8" ) { |io| io.read }, disposition: 'inline', type: file_set.mime_type
          when "text/plain"
            if format == "html"
              send_data static_read_text_from( uri: source_uri ), disposition: 'inline', type: "text/html"
              # send_data open( source_uri, "r:UTF-8" ) { |io| io.read }, disposition: 'inline', type: "text/html"
            else
              send_data static_read_text_from( uri: source_uri ), disposition: 'inline', type: file_set.mime_type
              # send_data open( source_uri, "r:UTF-8" ) { |io| io.read }, disposition: 'inline', type: file_set.mime_type
            end
          when /^image\//
            send_data open( source_uri, "rb" ) { |io| io.read }, disposition: 'inline', type: file_set.mime_type
          else
            static_content_send_msg "Unhandled mime type for file_set.id #{file_set.id} #{file_set.mime_type}"
          end
        end
      end
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "StaticContentControllerBehavior.static_content_read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0..19].join("\n")}"
      Rails.logger.error msg
      static_content_send_msg msg
    end

    def static_read_text_from( uri: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "uri=#{uri}",
                                             "" ] if static_content_controller_behavior_verbose
      text = open( uri, "r:UTF-8" ) { |io| io.read }
      if text =~ /\%/
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "uri=#{uri}",
                                               "interpolating...",
                                               "" ] if static_content_controller_behavior_verbose
        values = ::Deepblue::InterpolationHelper.new_interporlation_values
        text = ::Deepblue::InterpolationHelper.interpolate( target: text, values: values )
      end
      return text
    end

    def static_content_send_msg( msg )
      send_data "<pre>\n#{msg}\n</pre>", disposition: 'inline', type: "text/html"
    end

    def static_content_set_menu( value:, work_title:, file_id:, format: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "value=#{value}",
                                             "work_title=#{work_title}",
                                             "file_id=#{file_id}",
                                             "format=#{format}",
                                             "" ] if static_content_controller_behavior_verbose
      format = "html" if format.blank?
      @static_content_menu = value
      case value
      when  /^(.+)\.html\.erb$/
        @static_content_menu_partial = Regexp.last_match(1).strip
      when  /^(.+)\/(.+)$/
        static_content_load_menu_file( work_title: Regexp.last_match(1).strip,
                                       file_name: Regexp.last_match(2).strip,
                                       path: value )
        @static_content_page_navigation = static_content_for_read_file( work_title: work_title,
                                                         file_set_title: "#{file_id}.page_navigation.#{format}",
                                                                        path: nil )
      end
    end

    def static_content_sidebar( params )
      work_title = params[:doc]
      if params[:layout]
        file_set_title = "#{params[:layout]}_sidebar.html"
      else
        file_set_title = "#{params[:file]}_sidebar.html"
      end
      static_content_for( work_title: work_title, file_set_title: file_set_title, path: nil )
    end

    def static_content_title( params )
      ""
    end

    def static_content_work_file_set_find_by_title( work:, work_title:, file_set_title:, path: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "path=#{path}",
                                             "" ] if static_content_controller_behavior_verbose
      return nil unless work
      return nil unless file_set_title
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_cache_get( key: path )
        return static_content_find_by_id( id: id ) if id.present?
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work.id=#{work.id}",
                                             "work.title=#{work.title}",
                                             "work.file_set_ids=#{work.file_set_ids}",
                                             "work.file_sets.size=#{work.file_sets.size}",
                                             "" ] if static_content_controller_behavior_verbose
      work.file_sets.each do |fs|
        # TODO: verify
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "fs.title.join(#{fs.title.join}) ==? file_set_title(#{file_set_title})",
                                               # "file_set_title=#{file_set_title}",
                                               "" ] if static_content_controller_behavior_verbose
        if fs.title.join == file_set_title
          id = fs.id
          if work_view_content_enable_cache
            StaticContentControllerBehavior.static_content_cache_id( key: path, id: id )
          end
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "fs.title.join(#{fs.title.join}) ==? file_set_title(#{file_set_title})",
                                                 ">>> Found <<<",
                                                 "" ] if static_content_controller_behavior_verbose
          return fs
        end
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "fs.title.join(#{fs.title.join}) ==? file_set_title(#{file_set_title})",
                                             ">>> Not found <<<",
                                             "" ] if static_content_controller_behavior_verbose
      return nil
    end

    def work_view_content_enable_cache
      StaticContentControllerBehavior.work_view_content_enable_cache
    end

  end

end
