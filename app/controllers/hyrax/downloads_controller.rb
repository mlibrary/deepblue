
# monkey replace the original from Hyrax gem: "app/controllers/hyrax/download_controller.rb"

module Hyrax
  class DownloadsController < ApplicationController

    # begin monkey
    DOWNLOADS_CONTROLLER_DEBUG_VERBOSE = ::DeepBlueDocs::Application.config.downloads_controller_debug_verbose
    # end monkey

    include Hydra::Controller::DownloadBehavior
    include Hyrax::LocalFileDownloadsControllerBehavior

    def self.default_content_path
      :original_file
    end

    # Render the 404 page if the file doesn't exist.
    # Otherwise renders the file.
    def show
      # begin monkey
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:format]=#{params[:format]}",
                                             "" ] if DOWNLOADS_CONTROLLER_DEBUG_VERBOSE
      # begin monkey
      case file
      when ActiveFedora::File
        # begin monkey
        #
        # check if file is too big to download, this will happen when it is a json request
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "file.class.name=#{file.class.name}",
        #                                        "file.metadata=#{file.metadata}",
        #                                        "file.metadata.size=#{file.metadata.size}",
        #                                        "::RDF::Vocab::EBUCore.fileSize.to_s=#{::RDF::Vocab::EBUCore.fileSize.to_s}",
        #                                        "file.metadata.attributes[fileSize]=#{file.metadata.attributes["http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#fileSize"]}",
        #                                        "file.metadata.attributes[::RDF::Vocab::EBUCore.fileSize]=#{file.metadata.attributes[::RDF::Vocab::EBUCore.fileSize]}",
        #                                        "file.metadata.attributes[::RDF::Vocab::EBUCore.fileSize.to_s]=#{file.metadata.attributes[::RDF::Vocab::EBUCore.fileSize.to_s]}",
        #                                        #"file.metadata.methods.sort=#{file.metadata.methods.sort}",
        #                                        "" ] if DOWNLOADS_CONTROLLER_DEBUG_VERBOSE

        relation = file.metadata.attributes[::RDF::Vocab::EBUCore.fileSize.to_s]
        # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
        #                                        ::Deepblue::LoggingHelper.called_from,
        #                                        "relation.methods.sort=#{relation.methods.sort}",
        #                                        "relation.first=#{relation.first}",
        #                                        "relation.first.to_i=#{relation.first.to_i}",
        #                                        "" ] if DOWNLOADS_CONTROLLER_DEBUG_VERBOSE

        file_size = 0
        file_size = relation.first.to_i if relation.present?
        respond_to do |wants|
          wants.html do
            if file_size > DeepBlueDocs::Application.config.max_work_file_size_to_download
              raise ActiveFedora::IllegalOperation # TODO need better error than this
            end
            # For original files that are stored in fedora
            super
          end
          wants.json do
            unless ::DeepBlueDocs::Application.config.rest_api_allow_read
              return render_json_response( response_type: :bad_request, message: "Method not allowed." )
            end
            if file_size > DeepBlueDocs::Application.config.max_work_file_size_to_download
              return render_json_response( response_type: :unprocessable_entity, message: "file too large to download" )
            end
            # For original files that are stored in fedora
            super
          end
        end
        # end monkey
      when String
        # For derivatives stored on the local file system
        send_local_content
      else
        raise ActiveFedora::ObjectNotFoundError
      end
    end

    private

      # Override the Hydra::Controller::DownloadBehavior#content_options so that
      # we have an attachement rather than 'inline'
      def content_options
        super.merge(disposition: 'attachment')
      end

      # Override this method if you want to change the options sent when downloading
      # a derivative file
      def derivative_download_options
        { type: mime_type_for(file), disposition: 'inline' }
      end

      # Customize the :read ability in your Ability class, or override this method.
      # Hydra::Ability#download_permissions can't be used in this case because it assumes
      # that files are in a LDP basic container, and thus, included in the asset's uri.
      def authorize_download!
        authorize! :download, params[asset_param_key]
      rescue CanCan::AccessDenied
        unauthorized_image = Rails.root.join("app", "assets", "images", "unauthorized.png")
        if File.exist? unauthorized_image
          send_file unauthorized_image, status: :unauthorized
        else
          Deprecation.warn(self, "redirect_to default_image is deprecated and will be removed from Hyrax 3.0 (copy unauthorized.png image to directory assets/images instead)")
          redirect_to default_image
        end
      end

      def default_image
        ActionController::Base.helpers.image_path 'default.png'
      end

      # Overrides Hydra::Controller::DownloadBehavior#load_file, which is hard-coded to assume files are in BasicContainer.
      # Override this method to change which file is shown.
      # Loads the file specified by the HTTP parameter `:file`.
      # If this object does not have a file by that name, return the default file
      # as returned by {#default_file}
      # @return [ActiveFedora::File, File, NilClass] Returns the file from the repository or a path to a file on the local file system, if it exists.
      def load_file
        # begin monkey
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "" ] if DOWNLOADS_CONTROLLER_DEBUG_VERBOSE
        # begin monkey
        file_reference = params[:file]
        return default_file unless file_reference

        file_path = Hyrax::DerivativePath.derivative_path_for_reference(params[asset_param_key], file_reference)
        File.exist?(file_path) ? file_path : nil
      end

      def default_file
        default_file_reference = if asset.class.respond_to?(:default_file_path)
                                   asset.class.default_file_path
                                 else
                                   DownloadsController.default_content_path
                                 end
        association = dereference_file(default_file_reference)
        association&.reader
      end

      def mime_type_for(file)
        MIME::Types.type_for(File.extname(file)).first.content_type
      end

      def dereference_file(file_reference)
        return false if file_reference.nil?
        association = asset.association(file_reference.to_sym)
        association if association && association.is_a?(ActiveFedora::Associations::SingularAssociation)
      end
  end
end
