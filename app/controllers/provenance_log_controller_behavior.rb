# frozen_string_literal: true

module ProvenanceLogControllerBehavior

  mattr_accessor :provenance_log_controller_behavior_debug_verbose,
                 default: Rails.configuration.provenance_log_controller_behavior_debug_verbose

  include Deepblue::ControllerWorkflowEventBehavior

  attr_accessor :provenance_log_entries

  def provenance_log_entries?( id: )
    File.exist? provenance_log_path( id: id )
  end

  def provenance_log_entries_present?
    provenance_log_entries.present?
  end

  def provenance_log_entries_refresh( id:,
                                      begin_date: nil,
                                      end_date: nil,
                                      debug_verbose: provenance_log_controller_behavior_debug_verbose )

    debug_verbose ||= provenance_log_controller_behavior_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "begin_date=#{begin_date}",
                                           "end_date=#{end_date}",
                                           "" ] if debug_verbose
    return if id.blank?
    file_path = provenance_log_path( id: id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                            ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "file_path=#{file_path}",
                                            "" ] if debug_verbose
    entries = ::Deepblue::ProvenanceLogService.entries( id, refresh: true, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "entries&.size=#{entries&.size}",
                                           "" ] if debug_verbose
    if begin_date.blank? || end_date.blank?
      entries = ::Deepblue::ProvenanceLogService.entries( id, refresh: true, debug_verbose: debug_verbose )
    else
      entries = ::Deepblue::ProvenanceLogService.entries_filter_by_date_range( id: id,
                                                                               begin_date: begin_date,
                                                                               end_date: end_date,
                                                                               refresh: true,
                                                                               debug_verbose: debug_verbose )
    end
    return entries
  end

  def provenance_log_display_enabled?
    true
  end

  def provenance_log_path( id: )
    ::Deepblue::ProvenancePath.path_for_reference( id )
  end

end
