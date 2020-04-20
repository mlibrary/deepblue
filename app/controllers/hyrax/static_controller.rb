# frozen_string_literal: true

module Hyrax

  # Renders the Help page, terms of use, messages about exporting to Zotero and Mendeley
  class StaticController < ApplicationController
    include Deepblue::StaticContentControllerBehavior

    STATIC_CONTROLLER_DEBUG_VERBOSE = false

    layout 'homepage'

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

    # TODO: figure out how to redirect to /data/work_view_content as required from this controller

    def show_doc
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:doc]=#{params[:doc]}",
                                             "params[:file]=#{params[:file]}",
                                             "" ] if STATIC_CONTROLLER_DEBUG_VERBOSE
      @doc = params[:doc]
      if params[:format]
        @file = "#{params[:file]}.#{params[:format]}"
      else
        @file = "#{params[:file]}.html"
      end
      render "show"
    end

    def show_layout_doc
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:doc]=#{params[:doc]}",
                                             "params[:file]=#{params[:file]}",
                                             "" ] if STATIC_CONTROLLER_DEBUG_VERBOSE
      @layout = params[:layout]
      @doc = params[:doc]
      if params[:format]
        @file = "#{params[:file]}.#{params[:format]}"
      else
        @file = "#{params[:file]}.html"
      end
      render "show"
    end

    def show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:doc]=#{params[:doc]}",
                                             "" ] if STATIC_CONTROLLER_DEBUG_VERBOSE

      file_set = static_content_file_set( "DBDDocumentation", "#{params[:doc]}.html" )
      if file_set
        redirect_to( "/data/work_view_content/DBDDocumentation/#{params[:doc]}.html" )
      else
        render "hyrax/static/#{params[:doc]}"
      end
    end

    def show2
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
                                             "" ] if work_view_content_controller_debug_verbose
      file_set = static_content_file_set( work_title, file_name )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( "file_set", file_set),
                                             "file_set=#{file_set}",
                                             "" ] if work_view_content_controller_debug_verbose
      mime_type = file_set.mime_type if file_set.present?
      options = options_from( file_set: file_set )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "options=#{options}",
                                             "" ] if work_view_content_controller_debug_verbose
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

    def zotero
      respond_to do |format|
        format.html
        format.js { render layout: false }
      end
    end

    def mendeley
      respond_to do |format|
        format.html
        format.js { render layout: false }
      end
    end

  end

end
