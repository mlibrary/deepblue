# frozen_string_literal: true

class WorkViewContentController < ApplicationController
  include Deepblue::StaticContentControllerBehavior


  class_attribute :work_view_content_controller_verbose
  self.work_view_content_controller_verbose = false

  mattr_accessor :static_contet_helper_verbose

  class_attribute :presenter_class
  self.presenter_class = WorkViewContentPresenter

  attr_reader :file_id,
              :file_name,
              :format,
              :menu,
              :menu_file_format,
              :menu_header,
              :menu_links,
              :menu_partial,
              :page_navigation,
              :work_title

  def show
    @work_title = params[:id]
    @file_id = params[:file_id]
    @file_name = @file_id
    @format = params[:format]
    @file_name = "#{file_name}.#{format}" unless format.empty?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "work_title=#{work_title}",
                                           "file_id=#{file_name}",
                                           "file_name=#{file_name}",
                                           "format=#{format}",
                                           "" ] if work_view_content_controller_verbose
    file_set = static_content_file_set( work_title, file_name )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ::Deepblue::LoggingHelper.obj_class( "file_set", file_set),
                                           "file_set=#{file_set}",
                                           "" ] if work_view_content_controller_verbose
    mime_type = file_set.mime_type if file_set.present?
    options = options_from( file_set: file_set )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ] if work_view_content_controller_verbose
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
                                           "" ] if work_view_content_controller_verbose
    return options if description.blank?
    lines = description.join("\n").split("\n")
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "lines=#{lines}",
                                           "" ] if work_view_content_controller_verbose
    lines.each do |line|
      case line.strip
      when /^menu:(.+)$/
        options[:menu] = Regexp.last_match(1).strip
        set_menu( options[:menu] )
      when /^menu_header:(.+)$/
        @menu_header = Regexp.last_match(1).strip
        options[:menu_header] = @menu_header
      when /^render_with:(.+)$/
        options[:render_with] = Regexp.last_match(1).strip
      end
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "" ] if work_view_content_controller_verbose
    return options
  end

  def set_menu( value )
    @menu = value
    case value
    when  /^(.+)\.html\.erb$/
      @menu_partial = Regexp.last_match(1).strip
    when  /^(.+)\/(.+)$/
      load_menu_file( Regexp.last_match(1).strip, Regexp.last_match(2).strip )
      @page_navigation = static_content_for_read_file( work_title, "#{file_id}.page_navigation.#{format}" )
    end
  end

  def load_menu_file( work_title, file_name )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work_title=#{work_title}",
                                           "file_name=#{file_name}",
                                           "" ] if work_view_content_controller_verbose
    @menu_file_format = File.extname file_name
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@menu_file_format=#{@menu_file_format}",
                                           "" ] if work_view_content_controller_verbose
    case @menu_file_format
    when '.yml'
      file = static_content_for_read_file( work_title, file_name )
      @menu_links = YAML.load file
    when '.yaml'
      file = static_content_for_read_file( work_title, file_name )
      @menu_links = YAML.load file
    when '.txt'
      @menu_links = static_content_for_read_file( work_title, file_name ).split( "\n" )
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@menu_links=#{@menu_links}",
                                           "" ] if work_view_content_controller_verbose
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
