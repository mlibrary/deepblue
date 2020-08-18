# frozen_string_literal: true

require 'zip'
require 'tempfile'

module Deepblue

  module ZipDownloadControllerBehavior

    # include ::Deepblue::ZipDownloadService

    ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE = ZipDownloadService.zip_download_service_debug_verbose
    
    def zip_download
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
      respond_to do |wants|
        wants.html do
          if curation_concern.total_file_size > ZipDownloadService.zip_download_max_total_file_size_to_download
            raise ActiveFedora::IllegalOperation # TODO need better error than this
          end
          zip_download_rest( curation_concern: curation_concern )
        end
        wants.json do
          unless ::DeepBlueDocs::Application.config.rest_api_allow_read
            return render_json_response( response_type: :bad_request, message: "Method not allowed." )
          end
          if curation_concern.total_file_size > ZipDownloadService.zip_download_max_total_file_size_to_download
            return render_json_response( response_type: :unprocessable_entity, message: "total file size too large to download" )
          end
          zip_download_rest( curation_concern: curation_concern )
        end
      end
    end

    def zip_download_enabled?
      true
    end

    private

      def zip_download_rest( curation_concern: )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "params=#{params}",
                                               "" ] if ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE

        tmp_dir = ENV['TMPDIR'] || "/tmp"
        tmp_dir = Pathname.new tmp_dir
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "zip_download begin",
                                               "tmp_dir=#{tmp_dir}",
                                               "" ] if ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        target_dir = target_dir_name_id( tmp_dir, curation_concern.id )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "target_dir=#{target_dir}",
                                               "" ] if ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        Dir.mkdir( target_dir ) unless Dir.exist?( target_dir )
        target_zipfile = target_dir_name_id( target_dir, curation_concern.id, ".zip" )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "target_zipfile=#{target_zipfile}",
                                               "" ] if ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        File.delete target_zipfile if File.exist? target_zipfile
        # clean the zip directory if necessary, since the zip structure is currently flat, only
        # have to clean files in the target folder
        files_to_delete = Dir.glob( (target_dir.join '*').to_s)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "files_to_delete=#{files_to_delete}",
                                               "" ] if ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        files_to_delete.each do |file|
          File.delete file if File.exist? file
        end
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "target_zipfile=#{target_zipfile}",
                                               "Download Zip begin copy to folder #{target_dir}",
                                               "" ] if ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        Zip::File.open( target_zipfile.to_s, Zip::File::CREATE ) do |zipfile|
          metadata_filename = curation_concern.metadata_report( dir: target_dir )
          zipfile.add( metadata_filename.basename, metadata_filename )
          ::Deepblue::ExportFilesHelper.export_file_sets( target_dir: target_dir,
                          file_sets: curation_concern.file_sets,
                          log_prefix: "Zip: ",
                          do_export_predicate: ->(_target_file_name, _target_file) { true },
                          quiet: !ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE ) do |target_file_name, target_file|
            zipfile.add( target_file_name, target_file )
          end
        end
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "Download complete target_dir=#{target_dir}",
                                               "target_zipfile=#{target_zipfile}",
                                               "" ] if ZIP_DOWNLOAD_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
        send_file target_zipfile.to_s
      end

  end

end
