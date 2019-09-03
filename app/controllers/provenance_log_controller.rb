# frozen_string_literal: true

class ProvenanceLogController < ApplicationController
  include ProvenanceLogControllerBehavior

  class_attribute :presenter_class
  self.presenter_class = ProvenanceLogPresenter

  attr_accessor :id, :id_msg, :id_invalid, :id_deleted

  def show
    raise CanCan::AccessDenied unless current_ability.admin?
    @id = params[:id]
    @id_deleted = false
    @id_invalid = false
    @id_msg = ''
    id_check
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "" ]
    provenance_log_entries_refresh( id: id )
    @presenter = presenter_class.new( controller: self )
    render 'provenance_log/provenance_log'
  end

  def id_check
    return if id.blank?
    ActiveFedora::Base.find( id )
  rescue Ldp::Gone => g
    @id_msg = "deleted"
    @id_deleted = true
  rescue ActiveFedora::ObjectNotFoundError => e2
    @id_msg = "invalid"
    @id_invalid = true
  end

  def id_valid?
    return false if id.blank?
    return false if ( id_deleted || id_invalid )
    true
  end

end
