# frozen_string_literal: true

module Hyrax

  module StaticContentHelper

    @@static_content_helper_verbose = false
    mattr_accessor :static_content_helper_verbose

    def self.static_content_cache_title_id( title:, id: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "id=#{id}",
                                             "" ] if static_content_helper_verbose
      @@static_content_title_id_cache ||= {}
      @@static_content_title_id_cache[title] = id
    end

    def self.static_content_title_id_cache_get( title: )
      @@static_content_title_id_cache ||= {}
      rv = @@static_content_title_id_cache[title]
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "rv=#{rv}",
                                             "" ] if static_content_helper_verbose
      return rv
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
                                             "" ] if static_content_helper_verbose
      id = StaticContentHelper.static_content_title_id_cache_get( title: "//#{work_title}//#{file_set_title}//" )
      return static_content_read_file( id: id ) unless id.blank?
      id = StaticContentHelper.static_content_title_id_cache_get( title: work_title )
      work = static_content_find_by_title( work_title: work_title, id: id )
      return "" unless work
      file_set = static_content_work_file_set_find_by_title( work: work,
                                                             work_title: work_title,
                                                             file_set_title: file_set_title )
      return "" unless file_set
      static_content_read_file( file_set: file_set )
    end

    def static_content_find_by_title( work_title:, id: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "id=#{id}",
                                             "" ] if static_content_helper_verbose
      return ActiveFedora::Base.find id unless id.blank?
      id = StaticContentHelper.static_content_title_id_cache_get( title: work_title )
      return ActiveFedora::Base.find id unless id.blank?
      if work_title.size == 9
        begin
          # guess that it is an id, and not a title
          work = ActiveFedora::Base.find work_title
          StaticContentHelper.static_content_cache_title_id( title: work_title, id: work.id )
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
                                             "" ] if static_content_helper_verbose
      results = ::ActiveFedora::SolrService.query(solr_query, rows: 10 )
      if results.size > 0
        result = results[0] if results
        id = result.id
        work = ActiveFedora::Base.find id
        StaticContentHelper.static_content_cache_title_id( title: work_title, id: id )
      end
      return work
    end

    def static_content_read_file( file_set: nil, id: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{id}",
                                             "id=#{id}",
                                             "" ] if static_content_helper_verbose
      file_set = ActiveFedora::Base.find id unless id.blank?
      return "" if file_set.blank?
      file = file_set.files_to_file
      rv = if file.nil?
             "file_set.id #{file_set.id} files[0] is nil"
           else
            source_uri = file.uri.value
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                       ::Deepblue::LoggingHelper.called_from,
                                                       "source_uri=#{source_uri}",
                                                       "" ] if static_content_helper_verbose
            str = open( source_uri, "r:UTF-8" ) { |io| io.read }
            ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                     ::Deepblue::LoggingHelper.called_from,
                                                     "str.encoding=#{str.encoding}",
                                                     "" ] if static_content_helper_verbose
            str
          end
      return rv
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "StaticContentHelper.static_content_read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error msg
      return msg
    end

    def static_content_work_file_set_find_by_title( work:, work_title:, file_set_title: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_set_title=#{file_set_title}",
                                             "" ] if static_content_helper_verbose
      return nil unless work
      return nil unless file_set_title
      id = StaticContentHelper.static_content_title_id_cache_get( title: "//#{work_title}//#{file_set_title}//" )
      return static_content_find_by_id( id: id ) if id.present?
      work.ordered_file_sets.each do |fs|
        # TODO: verify
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "fs.title.join(#{fs.title.join}) ==? file_set_title(#{file_set_title})",
                                               "file_set_title=#{file_set_title}",
                                               "" ] if static_content_helper_verbose
        if fs.title.join == file_set_title
          id = fs.id
          StaticContentHelper.static_content_cache_title_id( title: "//#{work_title}//#{file_set_title}//", id: id )
          return fs
        end
      end
      return nil
    end

  end

end
