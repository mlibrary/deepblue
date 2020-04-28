# frozen_string_literal: true

module Hyrax

  # Renders the Help page, terms of use, messages about exporting to Zotero and Mendeley
  class StaticController < ApplicationController
    include Deepblue::StaticContentControllerBehavior

    class_attribute :presenter_class
    self.presenter_class = WorkViewContentPresenter

    STATIC_CONTROLLER_DEBUG_VERBOSE = false

    layout 'homepage'

    # TODO: figure out how to redirect to /data/work_view_content as required from this controller


    def show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:doc]=#{params[:doc]}",
                                             "" ] if STATIC_CONTROLLER_DEBUG_VERBOSE

      doc = params[:doc]
      prefix = documentation_work_title_prefix
      work_title = "#{prefix}#{doc}"
      file_name = "#{doc}.html"
      file_set = static_content_find_documentation_file_set( work_title: work_title, file_name: file_name )
      if file_set.present?
        if ::Deepblue::WorkViewContentService.static_controller_redirect_to_work_view_content
          redirect_to( "/data/work_view_content/#{prefix}#{doc}/#{doc}.html" )
        else
          show_static_content_doc( work_title: work_title, file_name: file_name, file_set: file_set )
        end
      elsif static_content_file_set( "DBDDocumentation", "#{doc}.html" ).present?
        redirect_to( "/data/work_view_content/DBDDocumentation/#{doc}.html" )
      elsif static_content_file_set( "#{prefix}#{doc}", "#{doc}.html" ).present?
        redirect_to( "/data/work_view_content/#{prefix}#{doc}/#{doc}.html" )
      elsif doc =~ %r{
                    about|
                    agreement|
                    dbd-documentation-guide|
                    dbd-glossary|
                    file-format-preservation|
                    globus-help|
                    help|
                    how-to-upload|
                    management-plan-text|
                    mendeley|
                    metadata-guidance|
                    prepare-your-data|
                    rest-api|
                    retention|
                    subject_libraries|
                    support-for-depositors|
                    terms|
                    use-downloaded-data|
                    versions|
                    zotero
                    }x
        render "hyrax/static/#{doc}"
      else
        redirect_to( main_app.root_path, status: 404 )
      end
    end

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

    def show_static_content_doc( work_title:, file_name:, file_set: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_name=#{file_name}",
                                             "file_set=#{file_set}",
                                             "" ] if STATIC_CONTROLLER_DEBUG_VERBOSE
      mime_type = file_set.mime_type if file_set.present?
      options = static_content_options_from( file_set: file_set, work_title: work_title )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "options=#{options}",
                                             "" ] if STATIC_CONTROLLER_DEBUG_VERBOSE
      if static_content_render? mime_type: mime_type
        @presenter = presenter_class.new( controller: self, file_set: file_set, format: format, options: options )
        render_with = options[:render_with]
        if render_with.present?
          render render_with
        else
          render 'hyrax/static/work_view_content'
        end
      else
        static_content_send( file_set: file_set, format: format, options: options )
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
