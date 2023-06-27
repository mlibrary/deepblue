# frozen_string_literal: true

class ProvenanceLogPresenter

  include Deepblue::DeepbluePresenterBehavior

  attr_accessor :controller

  delegate :begin_date, :end_date, to: :controller
  delegate :begin_date_value, :end_date_value, to: :controller
  delegate :deleted_ids, :deleted_id_to_key_values_map, to: :controller
  delegate :find_id, :find_user_id, to: :controller
  delegate :id, :id_msg, :id_invalid, :id_deleted, :id_valid?, to: :controller
  delegate :log_entries, to: :controller
  delegate :params, to: :controller
  delegate :presenter_debug_verbose, to: :controller
  delegate :works_by_user_id_ids, :works_by_user_id_to_key_values_map, to: :controller

  def initialize( controller: )
    @controller = controller
  end

  def find_id_value
    debug_verbose = presenter_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:find_id]=#{params[:find_id]}",
                                           "params=#{params.pretty_inspect}",
                                           "" ] if debug_verbose
    rv = params[:find_id]
    rv = params[:id] if rv.blank?
    return rv
  end

  def find_user_id_value
    debug_verbose = presenter_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "params[:find_id]=#{params[:find_id]}",
                                           "params=#{params.pretty_inspect}",
                                           "" ] if debug_verbose
    params[:find_user_id]
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
    Rails.application.routes.url_helpers.url_for( only_path: only_path,
                                                  action: action,
                                                  controller: 'provenance_log',
                                                  id: id )
  end

  def url_for_id( id:, only_path: true )
    url_for( action: "show", id: id, only_path: only_path )
  end

  def url_for_user_id( user_id:, only_path: true )
    query = { find_user_id: user_id }.to_query
    url_for( action: "show", only_path: only_path ) + "?#{query}"
  end

end
