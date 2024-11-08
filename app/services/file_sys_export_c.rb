# frozen_string_literal: true

# a place to store constants (for now)
module FileSysExportC

  STATUS_EXPORT_ERROR   = 'export_error'   unless const_defined? :STATUS_EXPORT_ERROR
  STATUS_EXPORT_NEEDED  = 'export_needed'  unless const_defined? :STATUS_EXPORT_NEEDED
  STATUS_EXPORT_SKIPPED = 'export_skipped' unless const_defined? :STATUS_EXPORT_SKIPPED
  STATUS_EXPORTED       = 'exported'       unless const_defined? :STATUS_EXPORTED
  STATUS_EXPORTING      = 'exporting'      unless const_defined? :STATUS_EXPORTING

end
