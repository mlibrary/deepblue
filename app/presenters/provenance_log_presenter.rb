# frozen_string_literal: true

class ProvenanceLogPresenter

  attr_accessor :controller

  delegate :id, :id_msg, :id_invalid, :id_deleted, :id_valid?, to: :controller

  def initialize( controller: )
    @controller = controller
  end

  def provenance_log_entries?
    return false if id.blank?
    file_path = ::Deepblue::ProvenancePath.path_for_reference( id )
    File.exist? file_path
  end

  def provenance_log_display_enabled?
    true
  end

end