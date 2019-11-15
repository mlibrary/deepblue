# frozen_string_literal: true

module Hyrax

  # Renders the Help page, terms of use, messages about exporting to Zotero and Mendeley
  class StaticController < ApplicationController
    layout 'homepage'

    def show_doc
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "params=#{params}",
                                             "params[:doc]=#{params[:doc]}",
                                             "params[:file]=#{params[:file]}",
                                             "" ]
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
                                             "" ]
      @layout = params[:layout]
      @doc = params[:doc]
      if params[:format]
        @file = "#{params[:file]}.#{params[:format]}"
      else
        @file = "#{params[:file]}.html"
      end
      render "show"
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
