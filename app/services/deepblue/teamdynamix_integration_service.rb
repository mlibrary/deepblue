# frozen_string_literal: true

module Deepblue

  module TeamdynamixIntegrationService

    include ::Deepblue::InitializationConstants

    TDX_REST_URL_TEST    = 'https://gw-test.api.it.umich.edu' unless const_defined? :TDX_REST_URL_TEST
    TDX_REST_URL_PROD    = 'https://gw.api.it.umich.edu'      unless const_defined? :TDX_REST_URL_PROD
    TDX_REST_URL_INVALID = 'teamdynamix.tdx_rest_url.invalid' unless const_defined? :TDX_REST_URL_INVALID

    TDX_REST_URL_TEST_OLD    = 'https://apigw-tst.it.umich.edu'   unless const_defined? :TDX_REST_URL_TEST
    TDX_REST_URL_PROD_OLD    = 'https://apigw.it.umich.edu'       unless const_defined? :TDX_REST_URL_PROD

    TDX_URL_TEST = 'https://teamdynamix.umich.edu/SBTDNext/Apps/' unless const_defined? :TDX_URL_TEST
    TDX_URL_PROD = 'https://teamdynamix.umich.edu/TDNext/Apps/'   unless const_defined? :TDX_URL_PROD

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

    mattr_accessor :teamdynamix_service_active, default: Settings.teamdynamix.active
    mattr_accessor :teamdynamix_use_new_api, default: Settings.teamdynamix.use_new_api
    mattr_accessor :tdx_server, default: Settings.teamdynamix.tdx_server

    mattr_accessor :check_admin_notes_for_existing_ticket, default: true
    mattr_accessor :enforce_dbd_account_id,     default: false

    mattr_accessor :admin_note_ticket_prefix, default: 'TeamDynamix ticket: '
    mattr_accessor :client_id,      default: Settings.teamdynamix.client_id
    mattr_accessor :client_secret,  default: Settings.teamdynamix.client_secret
    mattr_accessor :tdx_rest_url,   default: Settings.teamdynamix.tdx_rest_url
    mattr_accessor :its_app_id,     default: ''
    mattr_accessor :tdx_url,        default: ''
    mattr_accessor :ulib_app_id,    default: ''

    mattr_accessor :account_id,     default: nil
    mattr_accessor :form_id,        default: 2220
    mattr_accessor :service_id,     default: 2643
    mattr_accessor :type_id,        default: 769

    mattr_accessor :responsible_group_id, default: 1227

    # custom attributes
    mattr_accessor :attr_depositor_status # db-DepositorStatus, id: 10215
    mattr_accessor :attr_discipline       # db-Discipline, id: 10218
    mattr_accessor :attr_related_pub      # db-relatedpub, id: 10216
    mattr_accessor :attr_req_participants # db-ReqParticipants, id: 10220
    mattr_accessor :attr_summary          # db-Summary, id: 10228
    mattr_accessor :attr_uid              # db-UID, id: 10219
    mattr_accessor :attr_url_in_dbd       # db-URLinDBdata, id: 10217

    def self.tdx_production?
      @tdx_url == 'https://teamdynamix.umich.edu/TDNext/Apps/'
    end

    def self.tdx_sandbox?
      @tdx_url == 'https://teamdynamix.umich.edu/SBTDNext/Apps/'
    end

  end

end
