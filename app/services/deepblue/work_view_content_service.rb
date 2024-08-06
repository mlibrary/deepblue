# frozen_string_literal: true

require_relative './initialization_constants'

module Deepblue

  module WorkViewContentService

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :interpolation_helper_debug_verbose, default: false
    mattr_accessor :static_content_controller_behavior_verbose, default: false
    mattr_accessor :static_content_cache_debug_verbose, default: false
    mattr_accessor :work_view_documentation_controller_cc_debug_verbose, default: false
    mattr_accessor :work_view_content_service_debug_verbose, default: false
    mattr_accessor :work_view_content_service_email_templates_debug_verbose, default: false
    mattr_accessor :work_view_content_service_i18n_templates_debug_verbose, default: false
    mattr_accessor :work_view_content_service_view_templates_debug_verbose, default: false

    mattr_accessor :documentation_collection_title,   default: "DBDDocumentationCollection"
    mattr_accessor :documentation_work_title_prefix,  default: "DBDDoc-"
    mattr_accessor :documentation_email_title_prefix, default: "DBDEmail-"
    mattr_accessor :documentation_i18n_title_prefix,  default: "DBDI18n-"
    mattr_accessor :documentation_view_title_prefix,  default: "DBDView-"
    mattr_accessor :export_documentation_path,        default: '/tmp/documentation_export'

    mattr_accessor :static_content_controller_behavior_menu_verbose, default: false
    mattr_accessor :static_content_enable_cache,                     default: true
    mattr_accessor :static_content_interpolation_pattern,            default: nil
    mattr_accessor :static_controller_redirect_to_work_view_content, default: false

    mattr_accessor :static_content_documentation_collection_id

    def self.content_documentation_collection_id
      @@static_content_documentation_collection_id ||= content_documentation_collection_id_init
    end

    def self.content_documentation_collection_id_init
      title = documentation_collection_title
      solr_query = "+generic_type_sim:Collection AND +title_tesim:#{title}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "title=#{title}",
                                             "solr_query=#{solr_query}",
                                             "" ] if work_view_content_service_debug_verbose
      results = ::Hyrax::SolrService.query( solr_query, rows: 10 )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "results.class.name=#{results.class.name}",
                                             "results=#{results}",
                                             "" ] if work_view_content_service_debug_verbose
      return nil unless results.present?
      return result.id if results.is_a? Collection
      result = results[0] if results
      return result.id
    end

    def self.content_documentation_collection
      id = content_documentation_collection_id
      collection = content_find_by_id( id: id )
      return collection
    rescue Exception => ignore
      return nil
    end

    def self.content_find_by_id( id:, raise_error: false )
      return nil if id.blank?
      content = ::PersistHelper.find( id )
      return content
    rescue Ldp::Gone
      raise if raise_error
      return nil
    rescue Hyrax::ObjectNotFoundError
      raise if raise_error
      return nil
    end

    def self.content_read_file( file_set: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "file_set=#{file_set.id}",
                                             "" ] if work_view_content_service_debug_verbose
      file = file_set.files_to_file
      if file.nil?
        return nil
      else
        source_uri = file.uri.value
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "source_uri=#{source_uri}",
                                               "" ] if work_view_content_service_debug_verbose
        str = URI.open( source_uri, "r:UTF-8" ) { |io| io.read }
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "str.encoding=#{str.encoding}",
                                               "" ] if work_view_content_service_debug_verbose
        return str
      end
      return nil
    rescue Exception => e # rubocop:disable Lint/RescueException
      msg = "WorkViewContentService.static_content_read_file #{source_uri} - #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Rails.logger.error msg
      return nil
    end

    def self.load_email_templates( debug_verbose: work_view_content_service_email_templates_debug_verbose ||
                                    work_view_content_service_debug_verbose )
      # puts "Current I18n.backend=#{I18n.backend}"
      # puts "Rails.configuration.i18n_backend=#{Rails.configuration.i18n_backend}"
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if debug_verbose
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
                                               "" ] if debug_verbose
        if work.title.first.starts_with? prefix
          work.file_sets.each do |fs|
            file_name = fs.label
            if file_name =~ /^(.+)\.txt$/i
              key = Regexp.last_match(1)
              value = content_read_file( file_set: fs )
              keys_updated << load_templates_store( key: key, value: value )
            elsif file_name =~ /^(.+)\.html$/i
              key = "#{Regexp.last_match(1)}_html"
              value = content_read_file( file_set: fs )
              keys_updated << load_templates_store( key: key, value: value )
            end
          end
        end
      end
      load_templates_store( key: "hyrax.email.templates.keys_loaded",
                           value: keys_updated.join("; ") )
      load_templates_store( key: "hyrax.email.templates.keys_loaded_html",
                           value: "<li>#{keys_updated.join("</li>\n<li>")}</li>" )
      keys_updated << "hyrax.email.templates.keys_loaded"
      keys_updated << "hyrax.email.templates.keys_loaded_html"
      keys_updated << load_templates_store( key: "hyrax.email.templates.loaded", value: "true" )
      keys_updated << load_templates_store( key: "hyrax.email.templates.last_loaded", value: DateTime.now.to_s )
      if debug_verbose
        keys_updated.each do |key|
          options = EmailHelper.template_default_options( curation_concern: nil )
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "key=#{key}",
                                                 I18n.t!( key, **options ),
                                                 "" ] if debug_verbose
        end
      end
    end

    def self.load_templates_store( key:,
                                   value:,
                                   escape: false,
                                   locale: "en",
                                   debug_verbose: work_view_content_service_email_templates_debug_verbose ||
                                     work_view_content_service_debug_verbose )

      I18n.backend.store_translations( locale, { key => value }, :escape => escape )
      I18n.backend.store_translations( locale, { key.to_sym => value }, :escape => escape )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "I18n.t( '#{key}' )='#{I18n.t( key )}'",
                                             "" ], bold_puts: debug_verbose if debug_verbose
      return key
    end

    def self.load_i18n_templates( debug_verbose: work_view_content_service_view_templates_debug_verbose ||
                                    work_view_content_service_debug_verbose )

      load_i18n_templates_using_prefix( prefix: documentation_i18n_title_prefix,
                                        key_prefix: "hyrax.i18n.templates",
                                        debug_verbose: debug_verbose )
    end

    def self.load_view_templates( debug_verbose: work_view_content_service_view_templates_debug_verbose ||
                                    work_view_content_service_debug_verbose )

      load_i18n_templates_using_prefix( prefix: documentation_view_title_prefix,
                                        key_prefix: "hyrax.view.templates",
                                        debug_verbose: debug_verbose )
    end

    def self.load_i18n_templates_using_prefix( prefix:,
                                               key_prefix:,
                                               debug_verbose: work_view_content_service_debug_verbose )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "prefix=#{prefix}",
                                             "key_prefix=#{key_prefix}",
                                             "" ], bold_puts: debug_verbose if debug_verbose

      return unless Dir.exist?( './data/' ) # skip this unless in real server environment (./data/ does not exist for moku build environment)
      docCollection = content_documentation_collection
      return unless docCollection.present?
      docCollection.member_works.each do |work|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "prefix=#{prefix}",
                                               "work.title.first=#{work.title.first}",
                                               "" ], bold_puts: debug_verbose if debug_verbose
        if work.title.first.starts_with? prefix
          work.file_sets.each do |fs|
            file_name = fs.label
            if file_name =~ /^(.+)\.yml$/i
              key = Regexp.last_match(1)
              value = content_read_file( file_set: fs )
              load_i18n_templates_process( key: key, value: value, debug_verbose: debug_verbose )
            elsif file_name =~ /^(.+)\.txt$/i
              key = Regexp.last_match(1)
              value = content_read_file( file_set: fs )
              locale = "en" # TODO: possibly store the locale in description
              ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                     ::Deepblue::LoggingHelper.called_from,
                                                     "key=#{key}",
                                                     "value=#{value}",
                                                     "locale=#{locale}",
                                                     "" ], bold_puts: debug_verbose if debug_verbose
              load_templates_store( key: key, value: value, locale: locale, debug_verbose: debug_verbose )
            end
          end
        end
      end
      load_templates_store( key: "#{key_prefix}.loaded", value: "true", debug_verbose: debug_verbose )
      load_templates_store( key: "#{key_prefix}.last_loaded", value: DateTime.now.to_s, debug_verbose: debug_verbose )
    end

    def self.load_i18n_templates_process( key:, value:, debug_verbose: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "key=#{key}",
                                             "value=#{value}",
                                             "" ], bold_puts: debug_verbose if debug_verbose
      # convert value from yaml to hash of hashes
      hash = YAML.load( value )
      # walk hash and store values
      load_i18n_templates_hash_walk( hash: hash, debug_verbose: debug_verbose )
    end

    def self.load_i18n_templates_hash_walk( hash:, key_path: '', key: '', locale: '', debug_verbose: )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "hash=#{hash}",
                                             "key_path=#{key_path}",
                                             "key=#{key}",
                                             "locale=#{locale}",
                                             "" ], bold_puts: debug_verbose if debug_verbose
      prefix = key_path.to_s
      if locale.blank?
        locale = key
      else
        prefix = "#{prefix}#{key}." if key.present?
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             "prefix=#{prefix}",
                                             "locale=#{locale}",
                                             "" ], bold_puts: debug_verbose if debug_verbose
      hash.each do |key,value|
        if value.is_a?( Hash )
          load_i18n_templates_hash_walk( hash: value,
                                         key_path: prefix,
                                         key: key,
                                         locale: locale,
                                         debug_verbose: debug_verbose )
        else
          put_key = prefix
          put_key = "#{prefix}#{key}" if prefix.present?
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "key=#{key}",
                                                 "value=#{value}",
                                                 "put_key=#{put_key}",
                                                 "locale=#{locale}",
                                                 "" ], bold_puts: debug_verbose if debug_verbose
          load_templates_store( key: put_key, value: value, locale: locale, debug_verbose: debug_verbose )
        end
      end
    end

    def documentation_collection_title
      @@documentation_collection_title
    end

    def work_view_content_enable_cache
      Rails.configuration.static_content_enable_cache
    end

  end

end
