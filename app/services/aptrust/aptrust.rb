# frozen_string_literal: true

require_relative '../deepblue/message_handler'
require_relative '../deepblue/message_handler_null'

module Aptrust

    mattr_accessor :aptrust_debug_verbose, default: false

    mattr_accessor :aptrust_debug_assume_upload_succeeds, default: false # TODO: set this false for production

    STATUS_IN_DB = true unless const_defined? :STATUS_IN_DB

    DEFAULT_UPLOAD_CONFIG_FILE = Rails.root.join( 'data', 'config', 'aptrust.yml' ) unless const_defined? :DEFAULT_UPLOAD_CONFIG_FILE

    IDENTIFIER_TEMPLATE = '%local_repository%.%context%%type%%id%' unless const_defined? :IDENTIFIER_TEMPLATE

    NULL_MSG_HANDLER      = ::Deepblue::MessageHandlerNull.new unless const_defined? :NULL_MSG_HANDLER

    EVENT_BAGGED          = 'bagged'          unless const_defined? :EVENT_BAGGED
    EVENT_BAGGING         = 'bagging'         unless const_defined? :EVENT_BAGGING
    EVENT_DELETE_FAILED   = 'deleted_failed'  unless const_defined? :EVENT_DELETE_FAILED
    EVENT_DELETE_PENDING  = 'deleted_pending' unless const_defined? :EVENT_DELETE_PENDING
    EVENT_DELETED         = 'deleted'         unless const_defined? :EVENT_DELETED
    EVENT_DELETING        = 'deleting'        unless const_defined? :EVENT_DELETING
    EVENT_DEPOSIT_FAILED  = 'deposit_failed'  unless const_defined? :EVENT_DEPOSIT_FAILED
    EVENT_DEPOSIT_SKIPPED = 'deposit_skipped' unless const_defined? :EVENT_DEPOSIT_SKIPPED
    EVENT_DEPOSITED       = 'deposited'       unless const_defined? :EVENT_DEPOSITED
    EVENT_DEPOSITING      = 'depositing'      unless const_defined? :EVENT_DEPOSITING
    EVENT_ERROR           = 'error'           unless const_defined? :EVENT_ERROR
    EVENT_EXPORTED        = 'exported'        unless const_defined? :EVENT_EXPORTED
    EVENT_EXPORTING       = 'exporting'       unless const_defined? :EVENT_EXPORTING
    EVENT_EXPORT_FAILED   = 'export_failed'   unless const_defined? :EVENT_EXPORT_FAILED
    EVENT_FAILED          = 'failed'          unless const_defined? :EVENT_FAILED
    EVENT_PACKED          = 'packed'          unless const_defined? :EVENT_PACKED
    EVENT_PACKING         = 'packing'         unless const_defined? :EVENT_PACKING
    EVENT_UPLOAD_AGAIN    = 'upload_again'    unless const_defined? :EVENT_UPLOAD_AGAIN
    EVENT_UPLOAD_FAILED   = 'upload_failed'   unless const_defined? :EVENT_UPLOAD_FAILED
    EVENT_UPLOAD_SKIPPED  = 'upload_skipped'  unless const_defined? :EVENT_UPLOAD_SKIPPED
    EVENT_UPLOADED        = 'uploaded'        unless const_defined? :EVENT_UPLOADED
    EVENT_UPLOADING       = 'uploading'       unless const_defined? :EVENT_UPLOADING
    EVENT_UNKNOWN         = 'unknown'         unless const_defined? :EVENT_UNKNOWN
    EVENT_VERIFIED        = 'verified'        unless const_defined? :EVENT_VERIFIED
    EVENT_VERIFY_FAILED   = 'verify_failed'   unless const_defined? :EVENT_VERIFY_FAILED
    EVENT_VERIFY_PENDING  = 'verify_pending'  unless const_defined? :EVENT_VERIFY_PENDING
    EVENT_VERIFY_SKIPPED  = 'verify_skipped'  unless const_defined? :EVENT_VERIFY_SKIPPED
    EVENT_VERIFYING       = 'verifying'       unless const_defined? :EVENT_VERIFYING

    EVENTS_FINISHED = [ EVENT_DEPOSITED,
                        EVENT_DEPOSIT_SKIPPED ] unless const_defined? :EVENTS_FINISHED

    EVENTS_ERRORS = [ EVENT_EXPORT_FAILED,
                      EVENT_DEPOSIT_FAILED,
                      EVENT_FAILED,
                      EVENT_UPLOAD_FAILED,
                      EVENT_VERIFY_FAILED ] unless const_defined? :EVENTS_ERRORS

    EVENTS_FAILED = [ EVENT_EXPORT_FAILED,
                      EVENT_DELETE_FAILED,
                      EVENT_DEPOSIT_FAILED,
                      EVENT_FAILED,
                      EVENT_UPLOAD_FAILED,
                      EVENT_VERIFY_FAILED ] unless const_defined? :EVENTS_FAILED

    EVENTS_NEED_VERIFY = [ EVENT_DEPOSITED,
                           EVENT_UPLOAD_SKIPPED, # for testing
                           EVENT_VERIFYING,
                           EVENT_VERIFY_PENDING ] unless const_defined? :EVENTS_NEED_VERIFY

    EVENTS_PROCESSING = [ EVENT_BAGGED,
                          EVENT_BAGGING,
                          # EVENT_DELETING,
                          # EVENT_DEPOSITED,
                          EVENT_DEPOSITING,
                          EVENT_EXPORTED,
                          EVENT_EXPORTING,
                          EVENT_PACKED,
                          EVENT_PACKING,
                          EVENT_UPLOADED,
                          EVENT_UPLOADING ] unless const_defined? :EVENTS_PROCESSING

    EVENTS_SKIPPED = [ EVENT_DEPOSIT_SKIPPED,
                       EVENT_UPLOAD_SKIPPED,
                       EVENT_VERIFY_SKIPPED ] unless const_defined? :EVENTS_SKIPPED

    def self.arg_init( attr, default )
        attr ||= default
        return attr
    end

    def self.arg_init_squish( attr, default, squish: 255 )
        attr ||= default
        if attr.blank? && squish.present?
            attr = ''
        else
            attr = attr.squish[0..squish]
        end
        return attr
    end

    def self.aptrust_identifier( template:, local_repository:, context:, type:, noid: )
        rv = template
        rv = rv.gsub( /\%local_repository\%/, local_repository )
        rv = rv.gsub( /\%context\%/, context )
        rv = rv.gsub( /\%type\%/, type )
        rv = rv.gsub( /\%id\%/, noid )
        return rv
    end

end
