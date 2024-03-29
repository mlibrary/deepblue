# frozen_string_literal: true

require 'tmpdir'
require 'dropbox_api'
require_relative 'authentication_factory'

module BrowseEverything

  module Driver
    class Dropbox < Base

      # begin monkey
      mattr_accessor :browse_everything_driver_dropbox_debug_verbose,
                     default: ::BrowseEverythingIntegrationService.browse_everything_driver_dropbox_debug_verbose
      mattr_accessor :browse_everything_driver_dropbox2_debug_verbose,
                     default: ::BrowseEverythingIntegrationService.browse_everything_driver_dropbox2_debug_verbose
      # end monkey

      class FileEntryFactory
        def self.build(metadata:, key:)
          factory_klass = klass_for metadata
          factory_klass.build(metadata: metadata, key: key)
        end

        class << self
          private

          def klass_for(metadata)
            case metadata
            when DropboxApi::Metadata::File
              FileFactory
            else
              ResourceFactory
            end
          end
        end
      end

      class ResourceFactory
        def self.build(metadata:, key:)
          path = metadata.path_display
          BrowseEverything::FileEntry.new(
            path,
            [key, path].join(':'),
            File.basename(path),
            nil,
            nil,
            true
          )
        end
      end

      class FileFactory
        def self.build(metadata:, key:)
          path = metadata.path_display
          BrowseEverything::FileEntry.new(
            path,
            [key, path].join(':'),
            File.basename(path),
            metadata.size,
            metadata.client_modified,
            false
          )
        end
      end

      class << self
        attr_accessor :authentication_klass

        def default_authentication_klass
          DropboxApi::Authenticator
        end
      end

      # Constructor
      # @param config_values [Hash] configuration for the driver
      def initialize(config_values)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               # "config_values=#{config_values}",
                                               "config_values=#{::Deepblue::LoggingHelper.mask(config_values,
                                                                             keys: ['client_secret'] )}",
                                               "" ] if browse_everything_driver_dropbox2_debug_verbose
        self.class.authentication_klass ||= self.class.default_authentication_klass
        @downloaded_files = {}
        super(config_values)
      end

      def icon
        'dropbox'
      end

      def validate_config
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                               ::Deepblue::LoggingHelper.called_from,
                               "@valid_config=#{@valid_config}",
                               "@config[:client_id]=#{::Deepblue::LoggingHelper.mask @config[:client_id]}",
                               "@config[:client_secret]=#{::Deepblue::LoggingHelper.mask @config[:client_secret]}",
                               "" ] if browse_everything_driver_dropbox2_debug_verbose
        return true if @valid_config
        @valid_config ||= validate_config_init
        raise InitializationError, 'Dropbox driver requires a :client_id argument' unless @config[:client_id]
        raise InitializationError, 'Dropbox driver requires a :client_secret argument' unless @config[:client_secret]
      end

      def validate_config_init
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                               ::Deepblue::LoggingHelper.called_from,
                               "@config[:client_id]=#{::Deepblue::LoggingHelper.mask @config[:client_id]}",
                               "@config[:client_secret]=#{::Deepblue::LoggingHelper.mask @config[:client_secret]}",
                               "" ] if browse_everything_driver_dropbox2_debug_verbose
        @config[:client_id].present? && @config[:client_secret].present?
      end

      def contents(path = '')
        path = '/' + path unless path == ''
        response = client.list_folder(path)
        values = response.entries.map { |entry| FileEntryFactory.build(metadata: entry, key: key) }
        @entries = values.compact
        @sorter.call(@entries)
      end

      def downloaded_file_for(path)
        return @downloaded_files[path] if @downloaded_files.key?(path)

        # This ensures that the name of the file its extension are preserved for user downloads
        temp_file_path = File.join(download_directory_path, File.basename(path))
        temp_file = File.open(temp_file_path, mode: 'w+', encoding: 'ascii-8bit')
        client.download(path) do |chunk|
          temp_file.write chunk
        end
        temp_file.close
        @downloaded_files[path] = temp_file
      end

      def uri_for(path)
        temp_file = downloaded_file_for(path)
        "file://#{temp_file.path}"
      end

      def file_size_for(path)
        downloaded_file = downloaded_file_for(path)
        size = File.size(downloaded_file.path)
        size.to_i
      rescue StandardError => error
        Rails.logger.error "Failed to find the file size for #{path}: #{error}"
        0
      end

      def link_for(path)
        uri = uri_for(path)
        file_name = File.basename(path)
        file_size = file_size_for(path)

        [uri, { file_name: file_name, file_size: file_size }]
      end

      def auth_link(url_options)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "url_options=#{url_options}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        rv = authenticator.authorize_url redirect_uri: redirect_uri(url_options)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "auth_link rv=#{rv}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        rv
      end

      def connect(params, _data, url_options)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params[:code]=#{params[:code]}",
                                               "url_options=#{url_options}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        auth_bearer = authenticator.get_token params[:code], redirect_uri: redirect_uri(url_options)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "auth_bearer=#{auth_bearer}",
                                               "auth_bearer.token=#{auth_bearer.token}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        self.token = auth_bearer.token
      end

      def authorized?
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "token=#{token}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        token.present?
      end

      private

      def session
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "config[:client_id]=#{config[:client_id]}",
                                             "config[:client_secret]=#{::Deepblue::LoggingHelper.mask config[:client_secret]}",
                                             "" ] if browse_everything_driver_dropbox_debug_verbose
        AuthenticationFactory.new(
          self.class.authentication_klass,
          config[:client_id],
          config[:client_secret]
        )
      end

      def authenticate
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "session=#{session}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        rv = session.authenticate
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "authenticate rv=#{rv}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        rv
      end

      def authenticator
        @authenticator ||= authenticate
      end

      def client
        DropboxApi::Client.new(token)
      end

      def redirect_uri(url_options)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "url_options=#{url_options}",
                                               "method(:connector_response_url).source_location=#{method(:connector_response_url).source_location}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        rv = connector_response_url(**url_options)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        # Unfortunately, the connector_response_url does not return with /data as part of its path
        rv = rv.gsub( '/browse', '/data/browse' )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "rv=#{rv}",
                                               "" ] if browse_everything_driver_dropbox_debug_verbose
        return rv
      end

      # Ensures that the "tmp" directory is used if there is no default download
      # directory specified in the configuration
      # @return [String]
      def default_download_directory
        Rails.root.join('tmp')
      end

      # Retrieves the directory path for downloads used when retrieving the
      # resource from Dropbox
      # @return [String]
      def download_directory_path
        dir_path = config[:download_directory] || default_download_directory
        File.expand_path(dir_path)
      end
    end
  end

end
