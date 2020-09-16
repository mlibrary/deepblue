# frozen_string_literal: true

module ProvenanceLogControllerBehavior

  PROVENANCE_LOG_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE = false

  include Deepblue::ControllerWorkflowEventBehavior

  attr_accessor :provenance_log_entries

  def provenance_log_entries?( id: )
    file_path = ::Deepblue::ProvenancePath.path_for_reference( id )
    File.exist? file_path
  end

  def provenance_log_entries_present?
    provenance_log_entries.present?
  end

  def provenance_log_entries_refresh( id: )
    return if id.blank?
    # load provenance log for id specified
    file_path = ::Deepblue::ProvenancePath.path_for_reference( id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "file_path=#{file_path}",
                                            "" ] if PROVENANCE_LOG_CONTROLLER_BEHAVIOR_DEBUG_VERBOSE
    ::Deepblue::ProvenanceLogService.entries( id, refresh: true )
  end

  def provenance_log_display_enabled?
    true
  end

end
