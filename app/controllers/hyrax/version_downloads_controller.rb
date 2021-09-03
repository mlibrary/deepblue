# frozen_string_literal: true

module Hyrax

  # see: http://www.railstips.org/blog/archives/2009/08/07/patterns-are-not-scary-method-missing-proxy/
  class FileVersionProxy < BasicObject

    mattr_accessor :file_version_proxy_debug_verbose, default: false

    def initialize( file:, version_uri: )
      @file = file
      @version_uri = version_uri
    end

    def uri
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "@version_uri=#{@version_uri}",
                                             "" ] if file_version_proxy_debug_verbose
      return @version_uri unless @version_uri.blank?
      @file.uri
    end

    private

      def method_missing(method, *args, &block)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "method=#{method}",
                                               "" ] if file_version_proxy_debug_verbose
        @file.send(method, *args, &block)
      end

  end

  class VersionDownloadsController < DownloadsController

    mattr_accessor :version_downloads_controller_debug_verbose, default: false

    # Overrides Controllers::Hyrax::DownloadsController#load_file
    def load_file
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:id]=#{params[:id]}",
                                             "params[:version]=#{params[:version]}",
                                             "asset.id=#{asset.id}",
                                             "versions_uri=#{versions_uri}",
                                             "version_uri=#{version_uri}",
                                             "" ] if version_downloads_controller_debug_verbose

      rv = default_file
      # TODO: tell rv (an instance of Hydra::PCDM::File) is, that it's suppose to use the uri version by wrapping
      #       in a proxy that overrides the uri method
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:id]=#{params[:id]}",
                                             "params[:version]=#{params[:version]}",
                                             "asset.id=#{asset.id}",
                                             "rv.class.name=#{rv.class.name}",
                                             ">>>",
                                             "Wrap rv in a proxy here to produce correct uri stream: rv=#{rv}",
                                             "<<<",
                                             "" ] if version_downloads_controller_debug_verbose
      rv = FileVersionProxy.new( file: rv, version_uri: version_uri )
      return rv
    end

    private

      def versions_request
        return false unless has_versions?
        ActiveFedora.fedora.connection.get(versions_uri)
      end

      def versions_uri
        asset.uri + '/fcr:versions'
      end

      def version_id
        params[:version]
      end

      def version_uri
        @version_uri ||= version_uri_init
      end

    def version_uri_init
      # brute force this for now
      version_label = params[:version]
      asset.versions.each do |version|
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "version_label=#{version_label}",
                                               "version=#{version.label}",
                                               "version.uri=#{version.uri.to_s}",
                                               "" ] if version_downloads_controller_debug_verbose
        return version.uri.to_s if version.label == version_label
      end
      "not found"
    end

      def versioned_file_id
        versions = asset.versions
        return ActiveFedora::Base.uri_to_id(versions.last.uri) if versions.present?
        asset.id
      end

  end

end
