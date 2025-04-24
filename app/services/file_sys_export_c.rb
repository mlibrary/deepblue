# frozen_string_literal: true

# a place to store constants (for now)
module FileSysExportC

  ANCILLARY_ID_BASE       = "ANCILLARY:"                     unless const_defined? :ANCILLARY_ID_BASE
  ANCILLARY_ID_INGEST     = ANCILLARY_ID_BASE + "Ingest"     unless const_defined? :ANCILLARY_ID_INGEST
  ANCILLARY_ID_METADATA   = ANCILLARY_ID_BASE + "Metadata"   unless const_defined? :ANCILLARY_ID_METADATA
  ANCILLARY_ID_PROVENANCE = ANCILLARY_ID_BASE + "Provenance" unless const_defined? :ANCILLARY_ID_PROVENANCE

  NOIDS_KEEP_PRIVATE = ActiveSupport::HashWithIndifferentAccess.new( { ANCILLARY_ID_INGEST => true,
                                                                       ANCILLARY_ID_PROVENANCE => true } )

  METADATA_REPORT_FILENAME = "metadata_report.txt" unless const_defined? :METADATA_REPORT_FILENAME

  STATUS_DELETED           = 'deleted'           unless const_defined? :STATUS_DELETED
  STATUS_EXPORT_ERROR      = 'export_error'      unless const_defined? :STATUS_EXPORT_ERROR
  STATUS_EXPORT_NEEDED     = 'export_needed'     unless const_defined? :STATUS_EXPORT_NEEDED
  STATUS_EXPORT_SKIPPED    = 'export_skipped'    unless const_defined? :STATUS_EXPORT_SKIPPED
  STATUS_EXPORT_UPDATING   = 'export_updating'   unless const_defined? :STATUS_EXPORT_UPDATING
  STATUS_EXPORTED          = 'exported'          unless const_defined? :STATUS_EXPORTED
  STATUS_EXPORTED_PRIVATE  = 'exported_private'  unless const_defined? :STATUS_EXPORTED_PRIVATE
  STATUS_EXPORTED_PUBLIC   = 'exported_public'   unless const_defined? :STATUS_EXPORTED_PUBLIC
  STATUS_EXPORTING         = 'exporting'         unless const_defined? :STATUS_EXPORTING
  STATUS_EXPORTING_PRIVATE = 'exporting_private' unless const_defined? :STATUS_EXPORTING_PRIVATE
  STATUS_EXPORTING_PUBLIC  = 'exporting_private' unless const_defined? :STATUS_EXPORTING_PUBLIC
  STATUS_REEXPORT          = 'reexport'          unless const_defined? :STATUS_REEXPORT

  ALL_STATUS_EXPORT = { STATUS_DELETED           => 'Deleted',
                        STATUS_EXPORT_ERROR      => 'Export Error',
                        STATUS_EXPORT_NEEDED     => 'Export Needed',
                        STATUS_EXPORT_SKIPPED    => 'Export Skipped',
                        STATUS_EXPORT_UPDATING   => 'Export Updating',
                        STATUS_EXPORTED          => 'Exported',
                        STATUS_EXPORTED_PRIVATE  => 'Exported Private',
                        STATUS_EXPORTED_PUBLIC   => 'Exported Public',
                        STATUS_EXPORTING         => 'Exporting',
                        STATUS_EXPORTING_PRIVATE => 'Exporting Private',
                        STATUS_EXPORTING_PUBLIC  => 'Exporting Private',
                        STATUS_REEXPORT          => 'Reexport' } unless const_defined? :ALL_STATUS_EXPORT

  def self.invert_all_status_export
    rv = {}
    ALL_STATUS_EXPORT.each_pair { |k,v| rv[v] = k }
    return rv
  end

  ALL_STATUS_EXPORT_MAP = FileSysExportC.invert_all_status_export unless const_defined? :ALL_STATUS_EXPORT_MAP

  ALL_STATUS_EXPORT_NEEDED = { STATUS_EXPORT_ERROR => true,
                               STATUS_EXPORT_NEEDED => true,
                               STATUS_EXPORT_SKIPPED => true,
                               STATUS_EXPORT_UPDATING => true,
                               STATUS_REEXPORT => true } unless const_defined? :ALL_STATUS_EXPORT_NEEDED

  ALL_STATUS_EXPORTED      = { STATUS_EXPORTED => true,
                               STATUS_EXPORTED_PRIVATE => true,
                               STATUS_EXPORTED_PUBLIC => true } unless const_defined? :ALL_STATUS_EXPORTED

  ALL_STATUS_EXPORTING     = { STATUS_EXPORTING => true,
                               STATUS_EXPORTING_PRIVATE => true,
                               STATUS_EXPORTING_PUBLIC => true } unless const_defined? :ALL_STATUS_EXPORTING

end
