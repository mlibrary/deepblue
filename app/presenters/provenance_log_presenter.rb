# frozen_string_literal: true

class ProvenanceLogPresenter

  include Deepblue::DeepbluePresenterBehavior

  attr_accessor :controller

  delegate :begin_date, :end_date, to: :controller
  delegate :begin_date_value, :end_date_value, to: :controller
  delegate :find_id, :find_user_id, to: :controller

  delegate :log_entries, to: :controller

  delegate :id,
           :id_msg,
           :id_invalid,
           :id_deleted,
           :id_valid?, to: :controller

  delegate :deleted_ids, :deleted_id_to_key_values_map, to: :controller
  delegate :works_by_user_id_ids, :works_by_user_id_to_key_values_map, to: :controller

  def initialize( controller: )
    @controller = controller
  end

  def display_title( title )
    return "" if title.blank?
    return Array( title ).join(" ")
  end

  def provenance_log_entries?
    return false if id.blank?
    file_path = ::Deepblue::ProvenancePath.path_for_reference( id )
    File.exist? file_path
  end

  def provenance_log_display_enabled?
    true
  end

  def url_for( action:, id: nil, only_path: true )
    Rails.application.routes.url_helpers.url_for( only_path: only_path, action: action, controller: 'provenance_log', id: id )
  end

  def url_for_id( id:, only_path: true )
    url_for( action: "show", id: id, only_path: only_path )
  end

end
