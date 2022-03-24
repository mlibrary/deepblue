# frozen_string_literal: true

module ProvenanceLogControllerBehavior

  mattr_accessor :provenance_log_controller_behavior_debug_verbose, default: false

  include Deepblue::ControllerWorkflowEventBehavior

  attr_accessor :provenance_log_entries

  def provenance_log_entries?( id: )
    File.exist? provenance_log_path( id: id )
  end

  def provenance_log_entries_present?
    provenance_log_entries.present?
  end

  def provenance_log_entries_refresh( id: )
    return if id.blank?
    # load provenance log for id specified
    file_path = provenance_log_path( id: id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "file_path=#{file_path}",
                                            "" ] if provenance_log_controller_behavior_debug_verbose
    ::Deepblue::ProvenanceLogService.entries( id, refresh: true )
  end

  def provenance_log_display_enabled?
    true
  end

  def provenance_log_path( id: )
    ::Deepblue::ProvenancePath.path_for_reference( id )
  end

end
