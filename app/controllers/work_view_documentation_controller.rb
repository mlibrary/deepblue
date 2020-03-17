# frozen_string_literal: true

class WorkViewDocumentationController < ApplicationController
  include ActiveSupport::Concern
  include Blacklight::Base
  include Blacklight::AccessControls::Catalog
  include Deepblue::StaticContentControllerBehavior
  include Hyrax::Breadcrumbs
  with_themed_layout 'dashboard'
  before_action :authenticate_user!
  before_action :build_breadcrumbs, only: [:show]

  class_attribute :presenter_class
  self.presenter_class = WorkViewDocumentationPresenter

  attr_reader = :documentation_collection

  def show
    @presenter = presenter_class.new( controller: self, current_ability: current_ability )
    @documentation_collection = find_documentation_collection
    render 'hyrax/dashboard/show_work_view_documents'
  end

  def documentation_collection_title
    ::Deepblue::WorkViewContentService.documentation_collection_title
  end

  def documentation_collection
    @documentation_collection ||= find_documentation_collection
  end


  def find_documentation_collection
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "documentation_collection_title=#{documentation_collection_title}",
                                           "" ]
    rv =   static_content_find_collection_by_title title: documentation_collection_title
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

end
