# frozen_string_literal: true

module Aptrust

    mattr_accessor :aptrust_debug_verbose, default: true

    mattr_accessor :aptrust_debug_assume_upload_succeeds, default: true # TODO: set this false for production

    STATUS_IN_DB = true unless const_defined? :STATUS_IN_DB

    DEFAULT_UPLOAD_CONFIG_FILE = Rails.root.join( 'data', 'config', 'aptrust.yml' ) unless const_defined? :DEFAULT_UPLOAD_CONFIG_FILE

    EVENT_BAGGED          = 'bagged'          unless const_defined? :EVENT_BAGGED
    EVENT_BAGGING         = 'bagging'         unless const_defined? :EVENT_BAGGING
    EVENT_DEPOSIT_SKIPPED = 'deposit_skipped' unless const_defined? :EVENT_DEPOSIT_SKIPPED
    EVENT_DEPOSITED       = 'deposited'       unless const_defined? :EVENT_DEPOSITED
    EVENT_DEPOSITING      = 'depositing'      unless const_defined? :EVENT_DEPOSITING
    EVENT_EXPORTED        = 'exported'        unless const_defined? :EVENT_EXPORTED
    EVENT_EXPORTING       = 'exporting'       unless const_defined? :EVENT_EXPORTING
    EVENT_EXPORT_FAILED   = 'export_skipped'  unless const_defined? :EVENT_EXPORT_FAILED
    EVENT_FAILED          = 'failed'          unless const_defined? :EVENT_FAILED
    EVENT_PACKED          = 'packed'          unless const_defined? :EVENT_PACKED
    EVENT_PACKING         = 'packing'         unless const_defined? :EVENT_PACKING
    EVENT_UPLOAD_SKIPPED  = 'upload_skipped'  unless const_defined? :EVENT_UPLOAD_SKIPPED
    EVENT_UPLOADED        = 'uploaded'        unless const_defined? :EVENT_UPLOADED
    EVENT_UPLOADING       = 'uploading'       unless const_defined? :EVENT_UPLOADING
    EVENT_UNKNOWN         = 'uknown'          unless const_defined? :EVENT_UNKNOWN
    EVENT_VERIFIED        = 'verified'        unless const_defined? :EVENT_VERIFIED
    EVENT_VERIFY_FAILED   = 'verify_failed'   unless const_defined? :EVENT_VERIFY_FAILED
    EVENT_VERIFYING       = 'verifying'       unless const_defined? :EVENT_VERIFYING

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
                     EVENT_UNKNOWN,
                     EVENT_VERIFIED,
                     EVENT_VERIFY_FAILED,
                     EVENT_VERIFYING ] unless const_defined? :VALID_EVENTS

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
