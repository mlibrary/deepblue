# frozen_string_literal: true

module Aptrust

    mattr_accessor :aptrust_debug_verbose, default: true

    DEBUG_ASSUME_UPLOAD_SUCCEEDS = true

    STATUS_IN_DB = false

    EVENT_BAGGED          = 'bagged'
    EVENT_BAGGING         = 'bagging'
    EVENT_DEPOSIT_SKIPPED = 'deposit_skipped'
    EVENT_DEPOSITED       = 'deposited'
    EVENT_DEPOSITING      = 'depositing'
    EVENT_EXPORTED        = 'exported'
    EVENT_EXPORTING       = 'exporting'
    EVENT_EXPORT_FAILED   = 'export_skipped'
    EVENT_FAILED          = 'failed'
    EVENT_PACKED          = 'packed'
    EVENT_PACKING         = 'packing'
    EVENT_UPLOAD_SKIPPED  = 'upload_skipped'
    EVENT_UPLOADED        = 'uploading'
    EVENT_UPLOADING       = 'uploading'
    EVENT_UNKNOWN         = 'uknown'

    VALID_EVENTS = [ EVENT_BAGGED,
                     EVENT_BAGGING,
                     EVENT_DEPOSIT_SKIPPED,
                     EVENT_DEPOSITED,
                     EVENT_DEPOSITING,
                     EVENT_EXPORT_FAILED,
                     EVENT_EXPORTED,
                     EVENT_EXPORTING,
                     EVENT_FAILED,
                     EVENT_PACKED,
                     EVENT_PACKING,
                     EVENT_UPLOAD_SKIPPED,
                     EVENT_UPLOADED,
                     EVENT_UPLOADING,
                     EVENT_UNKNOWN ]

    def self.arg_init( attr, default )
        attr ||= default
        return attr
    end

    def self.arg_init_squish(attr, default, squish: 255 )
        attr ||= default
        if attr.blank? && squish.present?
            attr = ''
        else
            attr = attr.squish[0..squish]
        end
        return attr
    end

end
