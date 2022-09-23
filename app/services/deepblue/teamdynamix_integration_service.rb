# frozen_string_literal: true

module Deepblue

  module TeamdynamixIntegrationService

    include ::Deepblue::InitializationConstants

    @@_setup_ran = false
    @@_setup_failed = false

    def self.setup
      yield self unless @@_setup_ran
      @@_setup_ran = true
    rescue Exception => e # rubocop:disable Lint/RescueException
      @@_setup_failed = true
      msg = "#{e.class}: #{e.message} at #{e.backtrace.join("\n")}"
      # rubocop:disable Rails/Output
      puts msg
      # rubocop:enable Rails/Output
      Rails.logger.error msg
      raise e
    end

    mattr_accessor :teamdynamix_integration_service_debug_verbose, default: false

    mattr_accessor :teamdynamix_service_debug_verbose, default: false

    mattr_accessor :teamdynamix_service_active,            default: Settings.teamdynamix.active

    mattr_accessor :admin_note_ticket_prefix, default: 'TeamDynamix ticket: '
    mattr_accessor :check_admin_notes_for_existing_ticket, default: true
    mattr_accessor :client_id,     default: Settings.teamdynamix.client_id
    mattr_accessor :client_secret, default: Settings.teamdynamix.client_secret
    mattr_accessor :tdx_rest_url,  default: ''
    mattr_accessor :its_app_id,    default: ''
    mattr_accessor :tdx_url,       default: ''
    mattr_accessor :ulib_app_id,   default: ''

    # custom attributes
    mattr_accessor :attr_depositor_status # db-DepositorStatus, id: 10215
    mattr_accessor :attr_discipline       # db-Discipline, id: 10218
    mattr_accessor :attr_related_pub      # db-relatedpub, id: 10216
    mattr_accessor :attr_req_participants # db-ReqParticipants, id: 10220
    mattr_accessor :attr_summary          # db-Summary, id: 10228
    mattr_accessor :attr_uid              # db-UID, id: 10219
    mattr_accessor :attr_url_in_dbd       # db-URLinDBdata, id: 10217

    def self.tdx_production?
      @tdx_url == 'https://teamdynamix.umich.edu/TDNext/Apps/' # TODO: verify
    end

    def self.tdx_sandbox?
      @tdx_url == 'https://teamdynamix.umich.edu/SBTDNext/Apps/'
    end

  end

end
