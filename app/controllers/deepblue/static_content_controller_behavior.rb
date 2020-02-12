# frozen_string_literal: true

module Deepblue

  module StaticContentControllerBehavior

    def self.static_content_title_id_cache( title: )
      @@static_content_title_id_cache ||= {}
      rv = @@static_content_title_id_cache[title]
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "rv=#{rv}",
                                             "" ]
      return rv
    end

    def self.static_content_cache_title_id( title:, id: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "id=#{id}",
                                             "" ]
      @@static_content_title_id_cache ||= {}
      @@static_content_title_id_cache[title] = id
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

    def static_content_for( work_title, file_set_title, **options )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "options=#{options}",
                                             "" ]
      id = StaticContentControllerBehavior.static_content_title_id_cache( title: "//#{work_title}//#{file_set_title}//" )
      return static_content_read_file( id: id ) unless id.blank?
      id = StaticContentControllerBehavior.static_content_title_id_cache( title: work_title )
      work = static_content_find_by_title( work_title: work_title, id: id )
      return "" unless work
      file_set = static_content_work_file_set_find_by_title( work: work,
                                                             work_title: work_title,
                                                             file_set_title: file_set_title )
      # return "" unless file_set
      # static_content_read_file( file_set: file_set )
      static_content_send_file( file_set: file_set, format: options[:format] )
    end

    def static_content_file_set( work_title, file_set_title, **options )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "options=#{options}",
                                             "" ]
      id = StaticContentControllerBehavior.static_content_title_id_cache( title: "//#{work_title}//#{file_set_title}//" )
      return static_content_read_file( id: id ) unless id.blank?
      id = StaticContentControllerBehavior.static_content_title_id_cache( title: work_title )
      work = static_content_find_by_title( work_title: work_title, id: id )
      return nil unless work
      file_set = static_content_work_file_set_find_by_title( work: work,
                                                             work_title: work_title,
                                                             file_set_title: file_set_title )
      file_set
    end

    def static_content_find_by_title( work_title:, id: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "id=#{id}",
                                             "" ]
      return ActiveFedora::Base.find id unless id.blank?
      id = StaticContentControllerBehavior.static_content_title_id_cache( title: work_title )
      return ActiveFedora::Base.find id unless id.blank?
      if work_title.size == 9
        begin
          # guess that it is an id, and not a title
          work = ActiveFedora::Base.find work_title
          StaticContentControllerBehavior.static_content_cache_title_id( title: work_title, id: work.id )
          return work
        rescue ActiveFedora::ObjectNotFoundError
          # ignore and continue
        end
      end
      work = nil
      solr_query = "+generic_type_sim:Work AND +title_tesim:#{work_title}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "solr_query=#{solr_query}",
                                             "" ]
      results = ::ActiveFedora::SolrService.query(solr_query, rows: 10 )
      if results.size > 0
        result = results[0] if results
        id = result.id
        work = ActiveFedora::Base.find id
        StaticContentControllerBehavior.static_content_cache_title_id( title: work_title, id: id )
      end
      return work
    end

    def static_content_read_file( file_set: nil, id: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{id}",
                                             "id=#{id}",
                                             "" ]
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
                                               "" ]
        str = open( source_uri, "r:UTF-8" ) { |io| io.read }
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "str.encoding=#{str.encoding}",
                                               "" ]
        return str
      end
      return ""
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "StaticContentControllerBehavior.static_content_read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error msg
      return msg
    end

    def static_content_send_file( file_set: nil, id: nil, format: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set&.id=#{file_set&.id}",
                                             "id=#{id}",
                                             "format=#{format}",
                                             "" ]
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
                                                 "" ]

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
      msg = "StaticContentControllerBehavior.static_content_read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error msg
      static_content_send_msg msg
    end

    def static_content_send_msg( msg )
      send_data "<pre>\n#{msg}\n</pre>", disposition: 'inline', type: "text/html"
    end

    def static_content_work_file_set_find_by_title( work:, work_title:, file_set_title: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "" ]
      return nil unless work
      return nil unless file_set_title
      id = StaticContentControllerBehavior.static_content_title_id_cache( title: "//#{work_title}//#{file_set_title}//" )
      return static_content_read_file( id: id ) unless id.blank?
      work.ordered_file_sets.each do |fs|
        # TODO: verify
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "fs.title.join(#{fs.title.join}) ==? file_set_title(#{file_set_title})",
                                               "file_set_title=#{file_set_title}",
                                               "" ]
        if fs.title.join == file_set_title
          id = fs.id
          StaticContentControllerBehavior.static_content_cache_title_id( title: "//#{work_title}//#{file_set_title}//", id: id )
          return fs
        end
      end
      return nil
    end

  end

end
