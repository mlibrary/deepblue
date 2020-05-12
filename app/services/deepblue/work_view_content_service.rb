# frozen_string_literal: true

module Deepblue

  module WorkViewContentService

    WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE = false
    WORK_VIEW_CONTENT_SERVICE_EMAIL_TEMPLATES_DEBUG_VERBOSE = true

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false

    @@documentation_collection_title = "DBDDocumentationCollection"
    mattr_accessor :documentation_collection_title

    @@documentation_work_title_prefix = "DBDDoc-"
    mattr_accessor :documentation_work_title_prefix

    @@documentation_work_title_prefix = "DBDEmail-"
    mattr_accessor :documentation_email_title_prefix

    @@static_controller_redirect_to_work_view_content = false
    mattr_accessor :static_controller_redirect_to_work_view_content


    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    def self.content_documentation_collection_id
      @@static_content_documentation_collection_id ||= content_documentation_collection_id_init
    end

    def self.content_documentation_collection_id_init
      title = documentation_collection_title
      collection = nil
      solr_query = "+generic_type_sim:Collection AND +title_tesim:#{title}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "solr_query=#{solr_query}",
                                             "" ] if WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE
      results = ::ActiveFedora::SolrService.query( solr_query, rows: 10 )
      if results.size > 0
        result = results[0] if results
        return result.id
      end
      return nil
    end

    def self.content_documentation_collection
      id = content_documentation_collection_id
      collection = content_find_by_id( id: id )
      return collection
    end

    def self.content_find_by_id( id:, raise_error: false )
      return nil if id.blank?
      content = ActiveFedora::Base.find( id )
      return content
    rescue Ldp::Gone
      raise if raise_error
      return nil
    rescue ActiveFedora::ObjectNotFoundError
      raise if raise_error
      return nil
    end

    def self.content_read_file( file_set: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set.id}",
                                             "" ] if WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE
      file = file_set.files_to_file
      if file.nil?
        return nil
      else
        source_uri = file.uri.value
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "source_uri=#{source_uri}",
                                               "" ] if WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE
        str = open( source_uri, "r:UTF-8" ) { |io| io.read }
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "str.encoding=#{str.encoding}",
                                               "" ] if WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE
        return str
      end
      return nil
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "WorkViewContentService.static_content_read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error msg
      return nil
    end

    def self.load_email_templates
      # puts "Current I18n.backend=#{I18n.backend}"
      # puts "DeepBlueDocs::Application.config.i18n_backend=#{DeepBlueDocs::Application.config.i18n_backend}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if WORK_VIEW_CONTENT_SERVICE_EMAIL_TEMPLATES_DEBUG_VERBOSE ||
                                                     WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE
      return unless Dir.exist?( './data/' ) # skip this unless in real server environment (./data/ does not exist for moku build environment)
      docCollection = content_documentation_collection
      return unless docCollection.present?
      prefix = documentation_email_title_prefix
      keys_updated = []
      docCollection.member_works.each do |work|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "prefix=#{prefix}",
                                               "work.title.first=#{work.title.first}",
                                               "" ] if WORK_VIEW_CONTENT_SERVICE_EMAIL_TEMPLATES_DEBUG_VERBOSE ||
                                                       WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE
        if work.title.first.starts_with? prefix
          work.file_sets.each do |fs|
            file_name = fs.label
            if file_name =~ /^(.+)\.txt$/i
              key = Regexp.last_match(1)
              value = content_read_file( file_set: fs )
              keys_updated << load_email_templates_store( key: key, value: value )
            elsif file_name =~ /^(.+)\.html$/i
              key = "#{Regexp.last_match(1)}_html"
              value = content_read_file( file_set: fs )
              keys_updated << load_email_templates_store( key: key, value: value )
            end
          end
        end
      end
      load_email_templates_store( key: "hyrax.email.templates.keys_loaded",
                                  value: keys_updated.join("; ") )
      load_email_templates_store( key: "hyrax.email.templates.keys_loaded_html",
                                  value: "<li>#{keys_updated.join("</li>\n<li>")}</li>" )
      keys_updated << "hyrax.email.templates.keys_loaded"
      keys_updated << "hyrax.email.templates.keys_loaded_html"
      keys_updated << load_email_templates_store( key: "hyrax.email.templates.loaded", value: "true" )
      keys_updated << load_email_templates_store( key: "hyrax.email.templates.last_loaded", value: DateTime.now.to_s )
      if WORK_VIEW_CONTENT_SERVICE_EMAIL_TEMPLATES_DEBUG_VERBOSE || WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE
        keys_updated.each do |key|
          options = EmailHelper.template_default_options( curation_concern: nil )
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "key=#{key}",
                                                 I18n.t( key, **options ),
                                                 "" ] if WORK_VIEW_CONTENT_SERVICE_EMAIL_TEMPLATES_DEBUG_VERBOSE ||
                                                         WORK_VIEW_CONTENT_SERVICE_DEBUG_VERBOSE
        end
      end
    end

    def self.load_email_templates_store( key:, value:, escape: false, locale: "en" )
      I18n.backend.store_translations( locale, { key => value }, :escape => escape )
      I18n.backend.store_translations( locale, { key.to_sym => value }, :escape => escape )
      return key
    end

    def documentation_collection_title
      @@documentation_collection_title
    end

    def work_view_content_enable_cache
      ::DeepBlueDocs::Application.config.static_content_enable_cache
    end

  end

end
