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
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( "file_set", file_set),
                                           "file_set=#{file_set}",
                                           "" ]
    mime_type = file_set.mime_type if file_set.present?
    options = options_from( file_set: file_set )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ]
    if render_static_content? mime_type: mime_type
      @presenter = presenter_class.new( controller: self, file_set: file_set, format: format, options: options )
      render_with = options[:render_with]
      if render_with.present?
        render render_with
      else
        render 'hyrax/static/work_view_content'
      end
    else
      send_static_content( file_set: file_set, format: format, options: options )
    end
  end

  def options_from( file_set: )
    options = {}
    return options if file_set.nil?
    description = Array(file_set.description_file_set)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "description=#{description}",
                                           "" ]
    return options if description.blank?
    lines = description.join("\n").split("\n")
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "lines=#{lines}",
                                           "" ]
    lines.each do |line|
      case line.strip
      when /^menu:(.+)$/
        options[:menu] = Regexp.last_match(1).strip
      when /^menu_header:(.+)$/
        options[:menu_header] = Regexp.last_match(1).strip
      when /^render_with:(.+)$/
        options[:render_with] = Regexp.last_match(1).strip
      end
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ]
    return options
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

  def send_static_content( file_set:, format:, options: {} )
    static_content_send_file( file_set: file_set, format: format, options: options )
  end

end
