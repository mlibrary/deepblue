# frozen_string_literal: true

class WorkViewDocumentationController < ApplicationController
  include ActiveSupport::Concern
  include Blacklight::Base
  include Blacklight::AccessControls::Catalog
  include Hyrax::Breadcrumbs
  include Deepblue::StaticContentControllerBehavior
  include ActionView::Helpers::TranslationHelper
  with_themed_layout 'dashboard'
  before_action :authenticate_user!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class
  self.presenter_class = WorkViewDocumentationPresenter

  attr_reader :action_error

  def action
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ]
    action = params[:commit]
    @action_error = false
    msg = case action
          when t( 'simple_form.actions.work_view_documentation.clear_cache' )
            action_clear_cache
          when t( 'simple_form.actions.work_view_documentation.cache_on' )
            action_cache_on
          when t( 'simple_form.actions.work_view_documentation.cache_off' )
            action_cache_off
          when t( 'simple_form.actions.work_view_documentation.export_documentation' )
            action_export_documentation
          when t( 'simple_form.actions.work_view_documentation.reload_email_templates' )
            action_reload_email_templates
          else
            @action_error = true
            "Unkown action #{action}"
          end
      if action_error
        redirect_to work_view_documentation_path, alert: msg
      else
        redirect_to work_view_documentation_path, notice: msg
      end

  end

  def action_clear_cache
    ::Deepblue::StaticContentControllerBehavior.static_content_cache_reset
    "Cache cleared."
  end

  def action_cache_on
    ::Deepblue::StaticContentControllerBehavior.work_view_content_enable_cache = true
    "Cache is now on."
  end

  def action_cache_off
    ::Deepblue::StaticContentControllerBehavior.work_view_content_enable_cache = false
    "Cache is now off."
  end

  def action_export_documentation
    ExportDocumentationJob.perform_later( id: ::Deepblue::WorkViewContentService.content_documentation_collection_id,
                                          export_path: "./data/" )
    "Export documentation job started."
  end

  def action_reload_email_templates
    ::Deepblue::WorkViewContentService.load_email_templates
    "Reloaded email templates."
  end

  def documentation_collection
    @documentation_collection ||= find_documentation_collection
  end

  def documentation_collection_title
    ::Deepblue::WorkViewContentService.documentation_collection_title
  end

  def documentation_work_title_prefix
    ::Deepblue::WorkViewContentService.documentation_work_title_prefix
  end

  def find_documentation_collection
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "documentation_collection_title=#{documentation_collection_title}",
                                           "" ]
    rv =   static_content_find_collection_by_title( title: documentation_collection_title )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rv&.id=#{rv&.id}",
                                           "" ]

    rv
  end

  def search_session
    session[:search] ||= {}
    # Need to call the getter again. The value is mutated
    # https://github.com/rails/rails/issues/23884
    session[:search]
  end

  def show
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    @documentation_collection = find_documentation_collection
    render 'hyrax/dashboard/show_work_view_documents'
  end

end
