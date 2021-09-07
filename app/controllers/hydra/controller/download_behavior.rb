
# monkey replace the original from Hydra gem: "app/controllers/concerns/hydra/controller/download_behavior.rb"

module Hydra
  module Controller
    module DownloadBehavior
      extend ActiveSupport::Concern

      # begin monkey
      mattr_accessor :download_behavior_debug_verbose, default: false
      # end monkey

      included do
        include Hydra::Controller::ControllerBehavior
        before_action :authorize_download!
      end

      # Responds to http requests to show the file
      def show
        # begin monkey
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "" ] if download_behavior_debug_verbose
        # end monkey
        if file.new_record?
          render_404
        else
          send_content
        end
      end

      protected

      def render_404
        respond_to do |format|
          format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
          format.any  { head :not_found }
        end
      end

      # Override this method if asset PID is not passed in params[:id],
      # for example, in a nested resource.
      def asset_param_key
        :id
      end

      # Customize the :download ability in your Ability class, or override this method
      def authorize_download!
        authorize! :download, file
      end

      def asset
        @asset ||= ActiveFedora::Base.find(params[asset_param_key])
      end

      def file
        @file ||= load_file
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "@file=#{@file}",
        #                                        "" ] if download_behavior_debug_verbose
        # @file
      end

      # Override this method to change which file is shown.
      # Loads the file specified by the HTTP parameter `:file_id`.
      # If this object does not have a file by that name, return the default file
      # as returned by {#default_file}
      # @return [ActiveFedora::File] the file
      def load_file
        # begin monkey
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "file_path = params[:file]=#{file_path = params[:file]}",
                                               "" ] if download_behavior_debug_verbose
        # end monkey
        file_path = params[:file]
        f = asset.attached_files[file_path] if file_path
        f ||= default_file
        raise "Unable to find a file for #{asset}" if f.nil?
        # begin monkey
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "f=#{f}",
                                               "" ] if download_behavior_debug_verbose
        # end monkey
        f
      end

      # Handle the HTTP show request
      def send_content
        # begin monkey
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "" ] if download_behavior_debug_verbose
        # end monkey

        response.headers['Accept-Ranges'] = 'bytes'

        if request.head?
          content_head
        elsif request.headers['HTTP_RANGE']
          send_range
        else
          send_file_contents
        end
      end

      # Create some headers for the datastream
      def content_options
        { disposition: 'inline', type: file.mime_type, filename: file_name }
      end

      # Override this if you'd like a different filename
      # @return [String] the filename
      def file_name
        params[:filename] || file.original_name || (asset.respond_to?(:label) && asset.label) || file.id
      end


      # render an HTTP HEAD response
      def content_head
        response.headers['Content-Length'] = file.size
        head :ok, content_type: file.mime_type
      end

      # render an HTTP Range response
      def send_range
        _, range = request.headers['HTTP_RANGE'].split('bytes=')
        from, to = range.split('-').map(&:to_i)
        to = file.size - 1 unless to
        length = to - from + 1
        response.headers['Content-Range'] = "bytes #{from}-#{to}/#{file.size}"
        response.headers['Content-Length'] = "#{length}"
        self.status = 206
        prepare_file_headers
        stream_body file.stream(request.headers['HTTP_RANGE'])
      end

      def send_file_contents
        # begin monkey
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "" ] if download_behavior_debug_verbose
        # end monkey
        self.status = 200
        prepare_file_headers
        # begin monkey
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "file.class.name=#{file.class.name}",
                                               "" ] if download_behavior_debug_verbose
        # end monkey
        stream_body file.stream
      end

      def prepare_file_headers
        send_file_headers! content_options
        response.headers['Content-Type'] = file.mime_type
        response.headers['Content-Length'] ||= file.size.to_s
        # Prevent Rack::ETag from calculating a digest over body
        response.headers['Last-Modified'] = asset.modified_date.utc.strftime("%a, %d %b %Y %T GMT")
        self.content_type = file.mime_type
      end

      private

      def stream_body(iostream)
        # see https://github.com/rails/rails/issues/18714#issuecomment-96204444
        unless response.headers["Last-Modified"] || response.headers["ETag"]
          Rails.logger.warn("Response may be buffered instead of streaming, best to set a Last-Modified or ETag header")
        end
        self.response_body = iostream
      end

      def default_file
        if asset.class.respond_to?(:default_file_path)
          asset.attached_files[asset.class.default_file_path]
        elsif asset.attached_files.key?(DownloadsController.default_file_path)
          asset.attached_files[DownloadsController.default_file_path]
        end
      end

      module ClassMethods
        def default_file_path
          "content"
        end
      end
    end
  end
end
