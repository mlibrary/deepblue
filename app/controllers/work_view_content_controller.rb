# frozen_string_literal: true

class WorkViewContentController < ApplicationController
  include Deepblue::StaticContentControllerBehavior

  class_attribute :presenter_class
  self.presenter_class = WorkViewContentPresenter

  def show
    work_title = params[:id]
    file_name = params[:file_id]
    format = params[:format]
    file_name = "#{file_name}.#{format}" unless format.empty?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "work_title=#{work_title}",
                                           "file_name=#{file_name}",
                                           "format=#{format}",
                                           "" ]
    file_set = static_content_file_set( work_title, file_name )
    mime_type = file_set.mime_type if file_set.present?
    if render_static_content? mime_type: mime_type
      @presenter = presenter_class.new( controller: self, file_set: file_set, format: format )
      render 'hyrax/static/work_view_content'
    else
      send_static_content( file_set: file_set, format: format )
    end
  end

  def render_static_content?( mime_type: )
    # look up file_set and set mime_type
    case mime_type
    when "text/html", "text/plain"
      true
    else
      false
    end
  end

  def send_static_content( file_set:, format: )
    static_content_send_file( file_set: file_set, format: format )
  end

end
