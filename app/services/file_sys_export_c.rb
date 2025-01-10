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

  STATUS_EXPORT_ERROR      = 'export_error'      unless const_defined? :STATUS_EXPORT_ERROR
  STATUS_EXPORT_NEEDED     = 'export_needed'     unless const_defined? :STATUS_EXPORT_NEEDED
  STATUS_EXPORT_SKIPPED    = 'export_skipped'    unless const_defined? :STATUS_EXPORT_SKIPPED
  STATUS_EXPORTED          = 'exported'          unless const_defined? :STATUS_EXPORTED
  STATUS_EXPORTED_PRIVATE  = 'exported_private'  unless const_defined? :STATUS_EXPORTED_PRIVATE
  STATUS_EXPORTED_PUBLIC   = 'exported_public'   unless const_defined? :STATUS_EXPORTED_PUBLIC
  STATUS_EXPORTING         = 'exporting'         unless const_defined? :STATUS_EXPORTING
  STATUS_EXPORTING_PRIVATE = 'exporting_private' unless const_defined? :STATUS_EXPORTING_PRIVATE
  STATUS_EXPORTING_PUBLIC  = 'exporting_private' unless const_defined? :STATUS_EXPORTING_PUBLIC

end
