# frozen_string_literal: true

class WorkViewDocumentationPresenter
  include Hyrax::CreateWorkPresenterBehavior

  delegate :static_content_documentation_collection,
           :documentation_collection_title,
           :search_session,
           :static_content_controller_behavior_verbose,
           :work_view_content_enable_cache, to: :controller

  delegate :member_presenters,
           :ordered_ids,
           :file_set_presenters,
           :work_presenters, to: :member_presenter_factory

  delegate :doi_minted?, :tombstone, to: :current_work

  attr_accessor :controller, :current_ability, :current_work

  def initialize( controller:, current_ability: )
    @controller = controller
    @current_ability = current_ability
    # search_session
  end

  def current_work=(work)
    # reset work dependent members
    @solr_document = nil
    @workflow = nil
    @member_presenter_factory = nil
    @current_work = work
  end

  def editor?
    current_ability.can?( :edit, solr_document )
  end

  # @return [Array]
  def list_of_item_ids_to_display
    current_work.file_set_ids
  end

  # @param [Array<String>] ids a list of ids to build presenters for
  # @return [Array<presenter_class>] presenters for the array of ids (not filtered by class)
  def member_presenters_for(an_array_of_ids)
    member_presenters(an_array_of_ids)
  end

  def member_presenter_factory
    @member_presenter_factory ||= Hyrax::MemberPresenterFactory.new( solr_document, current_ability )
  end

  def show_path_collection( collection: )
    Rails.application.routes.url_helpers.hyrax_collection_path( collection.id, locale: I18n.locale )
  end

  def show_path_data_set( work: )
    Rails.application.routes.url_helpers.hyrax_data_set_path( work.id, locale: I18n.locale )
  end

  def solr_document
    @solr_document ||= SolrDocument.find current_work.id
  end

  def workflow
    @workflow ||= Hyrax::WorkflowPresenter.new( solr_document, current_ability )
  end

end