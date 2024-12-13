# frozen_string_literal: true

class WorkViewDocumentationController < ApplicationController

  mattr_accessor :work_view_documentation_controller_debug_verbose,
                 default: ::Deepblue::WorkViewContentService.work_view_documentation_controller_cc_debug_verbose

  include ActiveSupport::Concern
  # puts "include Blacklight::Base at #{caller_locations(1,1).first}"
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
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params=#{params}",
                                           "params[:commit]=#{params[:commit]}",
                                           "" ] if work_view_documentation_controller_debug_verbose
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
          when t( 'simple_form.actions.work_view_documentation.reload_i18n_templates' )
            action_reload_i18n_templates
          when t( 'simple_form.actions.work_view_documentation.reload_view_templates' )
            action_reload_view_templates
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
    t( 'simple_form.actions.work_view_documentation.clear_cache' )
  end

  def action_cache_on
    ::Deepblue::StaticContentControllerBehavior.work_view_content_enable_cache = true
    t( 'simple_form.actions.work_view_documentation.cache_now_on' )
  end

  def action_cache_off
    ::Deepblue::StaticContentControllerBehavior.work_view_content_enable_cache = false
    t( 'simple_form.actions.work_view_documentation.cache_now_off' )
  end

  def action_export_documentation
    ExportDocumentationJob.perform_later( id: ::Deepblue::WorkViewContentService.content_documentation_collection_id,
                                          export_path: ::Deepblue::WorkViewContentService.export_documentation_path,
                                          user_email: current_user.email )
    t( 'simple_form.actions.work_view_documentation.export_documentation_started' )
  end

  def action_reload_email_templates
    ::Deepblue::ThreadedVarService.touch_semaphore(::Deepblue::ThreadedVarService::THREADED_VAR_EMAIL_TEMPLATES)
    ::Deepblue::WorkViewContentService.load_email_templates( debug_verbose: work_view_documentation_controller_debug_verbose )
    t( 'simple_form.actions.work_view_documentation.reloaded_email_templates' )
  end

  def action_reload_i18n_templates
    ::Deepblue::ThreadedVarService.touch_semaphore(::Deepblue::ThreadedVarService::THREADED_VAR_I18N_TEMPLATES)
    # ::Deepblue::WorkViewContentService.load_i18n_templates( debug_verbose: work_view_documentation_controller_debug_verbose )
    t( 'simple_form.actions.work_view_documentation.reloaded_i18n_templates' )
  end

  def action_reload_view_templates
    ::Deepblue::ThreadedVarService.touch_semaphore(::Deepblue::ThreadedVarService::THREADED_VAR_VIEW_TEMPLATES)
    ::Deepblue::WorkViewContentService.load_view_templates( debug_verbose: work_view_documentation_controller_debug_verbose )
    t( 'simple_form.actions.work_view_documentation.reloaded_view_templates' )
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
                                           "" ] if work_view_documentation_controller_debug_verbose
    rv =   static_content_find_collection_by_title( title: documentation_collection_title )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rv&.id=#{rv&.id}",
                                           "" ] if work_view_documentation_controller_debug_verbose

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
