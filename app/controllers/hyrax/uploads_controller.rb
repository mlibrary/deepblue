# frozen_string_literal: true

module Hyrax

  class UploadsController < ApplicationController
    load_and_authorize_resource class: Hyrax::UploadedFile

    def create
      file = params[:files].first
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "file=#{file}",
                                           "file.path=#{file.path}",
                                           "file.size=#{file.size}",
                                           "file.original_filename=#{file.original_filename}",
                                           # "file.methods=#{file.methods.sort}",
                                           # "file.instance_variables=#{file.instance_variables}",
                                           # "file.tempfile.class=#{file.tempfile.class}",
                                           # "file.tempfile.methods=#{file.tempfile.methods.sort}",
                                           "current_user=#{current_user}" ]
      @upload.attributes = { file: file, user: current_user }
      @upload.save!
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "file=#{file}",
                                           "file.path=#{file.path}",
                                           "file.size=#{file.size}",
                                           "file.original_filename=#{file.original_filename}",
                                           "current_user=#{current_user}",
                                           "@upload=#{@upload}",
                                           # Deepblue::LoggingHelper.obj_methods( "@upload",  @upload ),
                                           # Deepblue::LoggingHelper.obj_instance_variables( "@upload", @upload ),
                                           # Deepblue::LoggingHelper.obj_attribute_names( "@upload", @upload ),
                                           Deepblue::LoggingHelper.obj_to_json( "@upload", @upload ),
                                           "" ]
      upload_json = @upload.to_json
      Deepblue::UploadHelper.log( class_name: self.class.name,
                                  event: "create",
                                  id: "NA",
                                  path: file.path,
                                  original_name: file.original_filename,
                                  size: file.size,
                                  upload_json: upload_json,
                                  uploaded_file_id: @upload.id,
                                  user: current_user.to_s )
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "UploadsController.create #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Deepblue::UploadHelper.log( class_name: self.class.name,
                                  event: "create",
                                  event_note: "failed",
                                  id: "NA",
                                  exception: e.to_s,
                                  backtrace0: e.backtrace[0..4] )
      raise
    end

    def destroy
      Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           Deepblue::LoggingHelper.obj_to_json( "@upload", @upload ) ]
      upload_json = @upload.to_json
      Deepblue::UploadHelper.log( class_name: self.class.name,
                                  event: "destroy",
                                  id: "NA",
                                  path: @upload.file.path,
                                  upload_json: upload_json,
                                  uploaded_file_id: @upload.id,
                                  size: File.size( @upload.file.path ),
                                  user: current_user.to_s )
      @upload.destroy
      head :no_content
    rescue Exception => e # rubocop:disable Lint/RescueException
      Rails.logger.error "UploadsController.destroy #{e.class}: #{e.message} at #{e.backtrace[0]}"
      Deepblue::UploadHelper.log( class_name: self.class.name,
                                  event: "destroy",
                                  event_note: "failed",
                                  id: "NA",
                                  exception: e.to_s,
                                  backtrace0: e.backtrace[0] )
      raise
    end

  end

end
