# frozen_string_literal: true
#  Reviewed: hyrax4

module Hyrax

  # Renders the Help page, terms of use, messages about exporting to Zotero and Mendeley
  class StaticController < ApplicationController
    include Deepblue::StaticContentControllerBehavior

    class_attribute :presenter_class
    self.presenter_class = WorkViewContentPresenter

    mattr_accessor :static_controller_debug_verbose, default: false

    attr_reader :file_name, :work_title

    layout 'homepage'

    def documentation_work_title_prefix
      ::Deepblue::WorkViewContentService.documentation_work_title_prefix
    end

    def show
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:doc]=#{params[:doc]}",
                                             "" ] if static_controller_debug_verbose

      case params[:doc]
      when "about-top"
        doc = "about"
      when "globus-help"
        return redirect_to( "#{Rails.configuration.relative_url_root}/user-guide#download-globus" )
      when "help"
        doc = "faq"
      else
        doc = params[:doc]
      end
      prefix = documentation_work_title_prefix
      @work_title = "#{prefix}#{doc}"
      @file_name = "#{doc}.html"
      path = "/#{work_title}/#{file_name}"
      file_set = static_content_find_documentation_file_set( work_title: work_title, file_name: file_name, path: path )
      if file_set.present?
        if ::Deepblue::WorkViewContentService.static_controller_redirect_to_work_view_content
          redirect_to( "#{Rails.configuration.relative_url_root}/work_view_content/#{prefix}#{doc}/#{doc}.html" )
        else
          show_static_content_doc( work_title: work_title,
                                   file_name: file_name,
                                   file_set: file_set,
                                   doc: doc,
                                   path: path )
        end
      elsif static_content_file_set( work_title: "DBDDocumentation", file_set_title: "#{doc}.html", path: path ).present?
        redirect_to( "#{Rails.configuration.relative_url_root}/work_view_content/DBDDocumentation/#{doc}.html" )
      elsif static_content_file_set( work_title: "#{prefix}#{doc}", file_set_title: "#{doc}.html", path: path ).present?
        redirect_to( "#{Rails.configuration.relative_url_root}/work_view_content/#{prefix}#{doc}/#{doc}.html" )
      elsif doc =~ %r{
                      about|
                      about-top|
                      agreement|
                      dbd-glossary|
                      depositor-guide|
                      faq|
                      help|
                      globus-help|
                      rest-api|
                      services|
                      user-guide|
                      mendeley|
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
                                             "" ] if static_controller_debug_verbose
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
                                             "" ] if static_controller_debug_verbose
      @layout = params[:layout]
      @doc = params[:doc]
      if params[:format]
        @file = "#{params[:file]}.#{params[:format]}"
      else
        @file = "#{params[:file]}.html"
      end
      render "show"
    end

    def show_static_content_doc( work_title:, file_name:, file_set:, doc:, path: )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "work_title=#{work_title}",
                                             "file_name=#{file_name}",
                                             "file_set=#{file_set}",
                                             "doc=#{doc}",
                                             "path=#{path}",
                                             "" ] if static_controller_debug_verbose
      mime_type = file_set.mime_type if file_set.present?
      options = static_content_options_from( file_set: file_set,
                                             work_title: work_title,
                                             file_id: doc,
                                             format: params[:format] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "mime_type=#{mime_type}",
                                             "options=#{options}",
                                             "" ] if static_controller_debug_verbose
      if static_content_render? mime_type: mime_type
        @presenter = presenter_class.new( controller: self,
                                          file_set: file_set,
                                          format: params[:format],
                                          path: path,
                                          options: options )
        render_with = options[:render_with]
        if render_with.present?
          render render_with
        else
          render 'hyrax/static/work_view_content'
        end
      else
        static_content_send( file_set: file_set, format: params[:format], path: path, options: options )
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
