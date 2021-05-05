# frozen_string_literal: true

class WorkViewContentController < ApplicationController
  include Deepblue::StaticContentControllerBehavior

  mattr_accessor :work_view_content_controller_debug_verbose, default: false
  mattr_accessor :static_content_helper_debug_verbose, default: false

  class_attribute :presenter_class
  self.presenter_class = WorkViewContentPresenter

  attr_reader :file_id,
              :file_name,
              :format,
              :work_title

  def show
    @work_title = params[:id]
    @file_id = params[:file_id]
    @file_name = @file_id
    @format = params[:format]
    @file_name = "#{file_name}.#{format}" unless format.empty?
    path = "/#{work_title}/#{file_name}"
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "work_title=#{work_title}",
                                           "file_id=#{file_name}",
                                           "file_name=#{file_name}",
                                           "format=#{format}",
                                           "path=#{path}",
                                           "" ] if work_view_content_controller_debug_verbose
    file_set = static_content_file_set( work_title: work_title, file_set_title: file_name, path: path )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( "file_set", file_set),
                                           "file_set=#{file_set}",
                                           "" ] if work_view_content_controller_debug_verbose
    mime_type = file_set.mime_type if file_set.present?
    options = static_content_options_from( file_set: file_set,
                                           work_title: work_title,
                                           file_id: @file_id,
                                           format: @format )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ] if work_view_content_controller_debug_verbose
    if static_content_render? mime_type: mime_type
      @presenter = presenter_class.new( controller: self,
                                        file_set: file_set,
                                        format: format,
                                        path: path,
                                        options: options )
      render_with = options[:render_with]
      if render_with.present?
        render render_with
      else
        render 'hyrax/static/work_view_content'
      end
    else
      static_content_send( file_set: file_set, format: format, path: path, options: options )
    end
  end

end
