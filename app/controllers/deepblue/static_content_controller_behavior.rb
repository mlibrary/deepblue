# frozen_string_literal: true

module Deepblue

  module StaticContentControllerBehavior
    include Deepblue::WorkViewContentService

    mattr_accessor :static_content_controller_behavior_verbose
    self.static_content_controller_behavior_verbose = false
    mattr_accessor :static_content_controller_behavior_menu_verbose
    self.static_content_controller_behavior_menu_verbose = false

    def self.static_content_documentation_collection_id
      @@static_content_documentation_collection_id ||= static_content_documentation_collection_id_init&.id
    end

    def self.static_content_documentation_collection_id_init
      title = WorkViewContentService.documentation_collection_title
      collection = nil
      solr_query = "+generic_type_sim:Collection AND +title_tesim:#{title}"
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "solr_query=#{solr_query}",
      #                                        "" ] if static_content_controller_behavior_verbose
      results = ::ActiveFedora::SolrService.query( solr_query, rows: 10 )
      if results.size > 0
        result = results[0] if results
        id = result.id
        collection = ActiveFedora::Base.find( id )
      end
      return collection
    end

    mattr_accessor :static_content_title_id_cache
    @@static_content_title_id_cache

    def self.static_content_title_id_cache( title: )
      @@static_content_title_id_cache ||= {}
      rv = @@static_content_title_id_cache[title]
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "rv=#{rv}",
                                             "" ] if static_content_controller_behavior_verbose
      return rv
    end

    def self.static_content_cache_title_id( title:, id: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "id=#{id}",
                                             "" ] if static_content_controller_behavior_verbose
      @@static_content_title_id_cache ||= {}
      @@static_content_title_id_cache[title] = id
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
      static_content_documentation_collection.member_works.each do |work|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "#{work.title.first} == #{title} ?",
                                               "" ] if static_content_controller_behavior_verbose
        return work if work.title.first == title
      end
      return nil
    end

    def static_content_find_documentation_file_set( work_title:, file_name: )
      work = static_content_find_documentation_work_by_title( title: work_title )
      return nil if work.blank?
      work.file_sets.each do |fs|
        if fs.title.first == file_name
          return fs
        end
      end
      return nil
    end

    def static_content_file_set( work_title, file_set_title, **options )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "options=#{options}",
                                             "" ] if static_content_controller_behavior_verbose
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_title_id_cache( title: "//#{work_title}//#{file_set_title}//" )
        return static_content_read_file( id: id ) unless id.blank?
        id = StaticContentControllerBehavior.static_content_title_id_cache( title: work_title )
      end
      work = static_content_find_work_by_title(title: work_title, id: id )
      return nil unless work
      file_set = static_content_work_file_set_find_by_title( work: work,
                                                             work_title: work_title,
                                                             file_set_title: file_set_title )
      file_set
    end

    def static_content_find_collection_by_title( title:, id: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "id=#{id}",
                                             "" ] if static_content_controller_behavior_verbose
      return ActiveFedora::Base.find id unless id.blank?
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_title_id_cache( title: title )
        return ActiveFedora::Base.find id unless id.blank?
      end
      if title.size == 9
        begin
          # guess that it is an id, and not a title
          collection = ActiveFedora::Base.find title
          if work_view_content_enable_cache
            StaticContentControllerBehavior.static_content_cache_title_id( title: title, id: collection.id )
          end
          return collection
        rescue ActiveFedora::ObjectNotFoundError
          # ignore and continue
        end
      end
      collection = nil
      solr_query = "+generic_type_sim:Collection AND +title_tesim:#{title}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_query=#{solr_query}",
                                             "" ] if static_content_controller_behavior_verbose
      results = ::ActiveFedora::SolrService.query(solr_query, rows: 10 )
      if results.size > 0
        result = results[0] if results
        id = result.id
        collection = ActiveFedora::Base.find id
        if work_view_content_enable_cache
          StaticContentControllerBehavior.static_content_cache_title_id( title: title, id: id )
        end
      end
      return collection
    end

    def static_content_find_work_by_title( title:, id: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "id=#{id}",
                                             "" ] if static_content_controller_behavior_verbose
      return ActiveFedora::Base.find id unless id.blank?
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_title_id_cache( title: title )
        return ActiveFedora::Base.find id unless id.blank?
      end
      if title.size == 9
        begin
          # guess that it is an id, and not a title
          work = ActiveFedora::Base.find title
          if work_view_content_enable_cache
            StaticContentControllerBehavior.static_content_cache_title_id( title: title, id: work.id )
          end
          return work
        rescue ActiveFedora::ObjectNotFoundError
          # ignore and continue
        end
      end
      work = nil
      work = static_content_find_documentation_work_by_title( title: title ) if title.start_with? documentation_work_title_prefix
      return work if work.present?
      solr_query = "+generic_type_sim:Work AND +title_tesim:#{title}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_query=#{solr_query}",
                                             "" ] if static_content_controller_behavior_verbose
      results = ::ActiveFedora::SolrService.query(solr_query, rows: 10 )
      if results.size > 0
        result = results[0] if results
        id = result.id
        work = ActiveFedora::Base.find id
        if work_view_content_enable_cache
          StaticContentControllerBehavior.static_content_cache_title_id( title: title, id: id )
        end
      end
      return work
    end

    def static_content_for( work_title, file_set_title, **options )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "options=#{options}",
                                             "" ] if static_content_controller_behavior_verbose
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_title_id_cache( title: "//#{work_title}//#{file_set_title}//" )
        return static_content_read_file( id: id ) unless id.blank?
        id = StaticContentControllerBehavior.static_content_title_id_cache( title: work_title )
      end
      work = static_content_find_work_by_title(title: work_title, id: id )
      return "" unless work
      file_set = static_content_work_file_set_find_by_title( work: work,
                                                             work_title: work_title,
                                                             file_set_title: file_set_title )
      static_content_send_file( file_set: file_set, format: options[:format] )
    end

    def static_content_for_read_file( work_title:, file_set_title:, **options )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "options=#{options}",
                                             "" ] if static_content_controller_behavior_verbose
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_title_id_cache( title: "//#{work_title}//#{file_set_title}//" )
        return static_content_read_file( id: id ) unless id.blank?
        id = StaticContentControllerBehavior.static_content_title_id_cache( title: work_title )
      end
      work = static_content_find_work_by_title(title: work_title, id: id )
      return "" unless work
      file_set = static_content_work_file_set_find_by_title( work: work,
                                                             work_title: work_title,
                                                             file_set_title: file_set_title )
      static_content_read_file( file_set: file_set )
    end

    def static_content_load_menu_file( work_title:, file_name: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_name=#{file_name}",
                                             "" ] if static_content_controller_behavior_verbose
      @static_content_menu_file_format = File.extname file_name
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@static_content_menu_file_format=#{@static_content_menu_file_format}",
                                             "" ] if static_content_controller_behavior_verbose
      case @static_content_menu_file_format
      when '.yml'
        file = static_content_for_read_file( work_title: work_title, file_set_title: file_name )
        @static_content_menu_links = YAML.load file
      when '.yaml'
        file = static_content_for_read_file( work_title: work_title, file_set_title: file_name )
        @static_content_menu_links = YAML.load file
      when '.txt'
        @static_content_menu_links = static_content_for_read_file( work_title: work_title, file_set_title: file_name ).split( "\n" )
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
      static_content_for( work_title, file_set_title )
    end

    def static_content_options_from( file_set:, work_title: )
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
          static_content_set_menu( value: options[:menu], work_title: work_title )
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
                                             "file_set=#{id}",
                                             "id=#{id}",
                                             "" ] if static_content_controller_behavior_verbose
      file_set = ActiveFedora::Base.find id unless id.blank?
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

    def static_content_send( file_set:, format:, options: {} )
      static_content_send_file( file_set: file_set, format: format, options: options )
    end

    def static_content_send_file( file_set: nil, id: nil, format: nil, options: {} )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set&.id=#{file_set&.id}",
                                             "id=#{id}",
                                             "format=#{format}",
                                             "options=#{options}",
                                             "" ] if static_content_controller_behavior_verbose
      file_set = ActiveFedora::Base.find id if file_set.nil? && id.present?
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
            send_data open( source_uri, "r:UTF-8" ) { |io| io.read }, disposition: 'inline', type: file_set.mime_type
          when "text/plain"
            if format == "html"
              send_data open( source_uri, "r:UTF-8" ) { |io| io.read }, disposition: 'inline', type: "text/html"
            else
              send_data open( source_uri, "r:UTF-8" ) { |io| io.read }, disposition: 'inline', type: file_set.mime_type
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

    def static_content_send_msg( msg )
      send_data "<pre>\n#{msg}\n</pre>", disposition: 'inline', type: "text/html"
    end

    def static_content_set_menu( value:, work_title: )
      @static_content_menu = value
      case value
      when  /^(.+)\.html\.erb$/
        @static_content_menu_partial = Regexp.last_match(1).strip
      when  /^(.+)\/(.+)$/
        static_content_load_menu_file( work_title: Regexp.last_match(1).strip, file_name: Regexp.last_match(2).strip )
        @static_content_page_navigation = static_content_for_read_file( work_title: work_title,
                                                         file_set_title: "#{file_id}.page_navigation.#{format}" )
      end
    end

    def static_content_sidebar( params )
      work_title = params[:doc]
      if params[:layout]
        file_set_title = "#{params[:layout]}_sidebar.html"
      else
        file_set_title = "#{params[:file]}_sidebar.html"
      end
      static_content_for( work_title, file_set_title )
    end

    def static_content_title( params )
      ""
    end

    def static_content_work_file_set_find_by_title( work:, work_title:, file_set_title: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "" ] if static_content_controller_behavior_verbose
      return nil unless work
      return nil unless file_set_title
      if work_view_content_enable_cache
        id = StaticContentControllerBehavior.static_content_title_id_cache( title: "//#{work_title}//#{file_set_title}//" )
        return static_content_read_file( id: id ) unless id.blank?
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
            StaticContentControllerBehavior.static_content_cache_title_id( title: "//#{work_title}//#{file_set_title}//", id: id )
          end
          return fs
        end
      end
      return nil
    end

  end

end
