# frozen_string_literal: true

module Deepblue

  class TeamdynamixService

    mattr_accessor :teamdynamix_service_debug_verbose,
                   default: TeamdynamixIntegrationService.teamdynamix_service_debug_verbose

    mattr_accessor :teamdynamix_service_access_token_debug_verbose, default: false

    mattr_accessor :active, default: TeamdynamixIntegrationService.teamdynamix_service_active

    mattr_accessor :admin_note_ticket_prefix, default: TeamdynamixIntegrationService.admin_note_ticket_prefix

    mattr_accessor :check_admin_notes_for_existing_ticket,
                   default: TeamdynamixIntegrationService.check_admin_notes_for_existing_ticket

    MSG_HANDLER_DEBUG_ONLY = ::Deepblue::MessageHandlerDebugOnly.new( debug_verbose: ->() { teamdynamix_service_debug_verbose } ).freeze
    MSG_HANDLER_TO_CONSOLE = ::Deepblue::MessageHandler.msg_handler_for_task( options: { debug_verbose: teamdynamix_service_debug_verbose } )

    APPLICATION_JSON = 'application/json'

    ATTR_ID    = 'ID'
    ATTR_VALUE = 'Value'

    BUILD_ACCESS_TOKEN_EVERY_TIME = true

    DEFAULT_GROUP_SEARCH_NAME_LIKE = 'ULIB'

    FIELD_DESCRIPTION = 'Description'
    FIELD_ID          = 'ID'

    RESPONSE_ID      = 'ID'
    RESPONSE_MESSAGE = 'Message'

    TEXT_PLAIN = 'text/plain'

    VALUE_UNKNOWN_DESCRIPTION     = 'Unknown Description'
    VALUE_UNKNOWN_REQUESTOR_EMAIL = 'unknown@unknown.com'
    VALUE_UNKNOWN_TITLE           = 'Unknown Title'

    attr_accessor :access_token
    attr_accessor :authentication
    attr_accessor :bearer
    attr_accessor :bearer_basic
    attr_accessor :client_id
    attr_accessor :client_secret
    attr_accessor :its_app_id
    attr_accessor :responses
    attr_accessor :tdx_rest_url
    attr_accessor :tdx_ticket_url
    attr_accessor :tdx_url
    attr_accessor :ulib_app_id

    attr_accessor :msg_handler

    def self.has_service_request?( curation_concern: )
      return false unless curation_concern.present?
      return false unless curation_concern.respond_to? :curation_notes_admin_include?
      rv = curation_concern.curation_notes_admin_include? admin_note_ticket_prefix
      return rv
    end

    def self.to_console( responses: [], verbose: true, debug_verbose: teamdynamix_service_debug_verbose )
      msg_handler = ::Deepblue::MessageHandler.msg_handler_for_task( options: { verbose: verbose,
                                                                                debug_verbose: debug_verbose } )
      TeamdynamixService.new( responses: responses, msg_handler: msg_handler )
    end

    def initialize( responses: [], msg_handler: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "" ] if teamdynamix_service_debug_verbose
      msg_handler ||= MSG_HANDLER_DEBUG_ONLY
      @msg_handler = msg_handler
      msg_handler.bold_debug [ ::Deepblue::LoggingHelper.here,
                               ::Deepblue::LoggingHelper.called_from,
                               "" ] if msg_handler.debug_verbose
      @responses = responses
      @responses ||= []

      @access_token   = nil
      @authentication = nil
      @bearer         = nil
      @bearer_basic   = nil
      @client_id      = TeamdynamixIntegrationService.client_id
      @client_secret  = TeamdynamixIntegrationService.client_secret
      @its_app_id     = TeamdynamixIntegrationService.its_app_id
      @tdx_rest_url   = TeamdynamixIntegrationService.tdx_rest_url
      @tdx_ticket_url = nil
      @tdx_url        = TeamdynamixIntegrationService.tdx_url
      @ulib_app_id    = TeamdynamixIntegrationService.ulib_app_id

      # TODO configure these
      @form_id = 2220
      @service_id = 2643
      @type_id = 769

      # data["StatusID"] = 1012 # TODO: config
      # data["PriorityID"] = 20 # TODO: config
      # data["SourceID"] = 8 # TODO: config
      # data["ResponsibleGroupID"] = 1227 # TODO: config

    end

    def verbose
      @msg_handler.verbose
    end

    def access_token
      if BUILD_ACCESS_TOKEN_EVERY_TIME
        @access_token = build_access_token
      else
        @access_token ||= build_access_token
      end
    end

    def add_tdx_ticket_link_to( curation_concern: )
      note = build_curation_notes_admin_link
      return unless note.present?
      if curation_concern.respond_to? :add_curation_note_admin
        curation_concern.add_curation_note_admin( note: note )
      else
        msg_handler.warning "curation concern #{curation_concern.id} does not respond to :add_curation_note_admin"
        msg_handler.warning "skipping add of curation note: #{note}"
      end
    end

    def authentication
      @authentication ||= build_authentication
    end

    def bearer
      if BUILD_ACCESS_TOKEN_EVERY_TIME
        @bearer = build_bearer
      else
        @bearer ||= build_bearer
      end
    end

    def bearer_basic
      @bearer_basic ||= build_bearer_basic
    end

    def build_access_token
      debug_verbose = teamdynamix_service_access_token_debug_verbose
      build_bearer_basic
      headers = build_headers( auth: bearer_basic, content_type: 'application/x-www-form-urlencoded' )
      msg_handler.msg_verbose { headers.pretty_inspect } if debug_verbose
      parms = '/um/it/oauth2/token?scope=tdxticket&grant_type=client_credentials'
      _status, body = post( connection: build_connection( uri: tdx_rest_url, headers: headers ),
                            parms: parms,
                            debug_verbose: debug_verbose )
      rv=body['access_token']
      msg_handler.msg_verbose "access_token=#{rv}" if debug_verbose
      rv
    end

    def build_authentication
      rv = "#{client_id}:#{client_secret}"
      msg_handler.msg_verbose "authentication=#{rv}"
      rv
    end

    def build_bearer
      rv = "Bearer #{access_token}"
      msg_handler.msg_verbose "bearer=#{rv}"
      rv
    end

    def build_bearer_basic
      rv = "Bearer Basic #{Base64.strict_encode64(authentication)}"
      msg_handler.msg_verbose "bearer_basic=#{rv}"
      rv
    end

    def build_connection( uri:, headers: {} )
      return Faraday.new(uri, headers: headers) if headers.present?
      return Faraday.new(uri)
    end

    def build_curation_notes_admin_link
      return '' if tdx_ticket_url.blank?
      "#{admin_note_ticket_prefix}#{tdx_ticket_url}"
    end

    def build_description_from( curation_concern: )
      cc_title = title_for(curation_concern: curation_concern)
      creator = creator_for(curation_concern: curation_concern)
      depositor = curation_concern.depositor
      deposit_id = curation_concern.id
      deposit_url = ::Deepblue::EmailHelper.curation_concern_url( curation_concern: curation_concern )
      discipline = Array( curation_concern.subject_discipline ).first
      requestor_email = requestor_email_for( curation_concern: curation_concern )
      # jira_summary = '' # keep this blank for now, it'll be a marker for records ported from jira
      description = []
      description << "Title: #{cc_title}<br/>"
      description << "Creator: #{creator}<br/>"
      description << "Deposit ID: #{deposit_id}<br/>"
      description << "Deposit URL: #{deposit_url}<br/>"
      description << "Discipline: #{discipline}<br/>"
      description << "Depositor: #{depositor}<br/>"
      description << "Requestor Email: #{requestor_email}<br/>"
      description << "Description:"
      curation_concern.description.each do |line|
        line = line.split( /[\n\r]+/ ).join(" ")
        description << "<p>#{line}</p>"
      end
      return description.join("\n")
    end

    def build_data( data: )
      return nil if data.nil?
      rv = JSON.dump(data)
      msg_handler.msg_verbose { "data=#{rv.pretty_inspect}" }
      return rv
    end

    def build_headers( accept: APPLICATION_JSON,
                       auth:,
                       content_type: TEXT_PLAIN,
                       debug_verbose: teamdynamix_service_debug_verbose )

      debug_verbose ||= teamdynamix_service_debug_verbose
      msg_handler.msg_verbose "auth=#{auth}" if debug_verbose
      rv = {}
      rv['Content-Type'] = content_type if content_type.present?
      rv['X-IBM-Client-Id'] = @client_id
      rv['Accept'] = accept if accept.present?
      rv['Authorization'] = auth if auth.present?
      msg_handler.msg_verbose { "headers=#{rv.pretty_inspect}" } if debug_verbose
      return rv
    end

    def build_title_last_name( curation_concern: )
      name = Array( curation_concern.creator ).first
      return "" if name.blank?
      match = name.match( /^([^,]+),.*$/ ) # first non-comma substring
      return match[1] if match
      match = name.match( /^.* ([^ ]+)$/ ) # last non-space substring
      return match[1] if match
      return name
    end

    def build_title( curation_concern: )
      title = Array( curation_concern.title ).first
      return "" if title.blank?
      match = title.match( /^([^ ]+) +([^ ]+) [^ ].*$/ ) # three plus words
      return "#{match[1]}#{match[2]}" if match
      match = title.match( /^([^ ]+) +([^ ]+)$/ ) # two words
      return "#{match[1]}#{match[2]}" if match
      match = title.match( /^[^ ]+$/ ) # one word
      return title if match
      return title
    end

    def build_title_for( curation_concern: )
      # Title: [Depositor last name] _ [First two words of deposit] _ [deposit ID] - e.g., Nasser_BootAcceleration_n583xv03w
      title = build_title( curation_concern: curation_concern )
      last_name = build_title_last_name( curation_concern: curation_concern )
      rv = "#{last_name}_#{title}_#{curation_concern.id}"
      return rv
    end

    def build_tdx_create_ticket_fields_with( curation_concern:, fields: {} )
      fields ||= {}
      fields[FIELD_DESCRIPTION] = build_description_from( curation_concern: curation_concern )
      fields["IsRichHtml"] = true
      fields["Attributes"] = build_tdx_custom_attributes( curation_concern: curation_concern )
      msg_handler.msg_verbose { "build_tdx_create_ticket_fields_with rv=#{fields.pretty_inspect}" }
      return fields
    end

    def build_tdx_custom_attributes( curation_concern: )
      # cc_title = title_for(curation_concern: curation_concern)
      # creator = creator_for(curation_concern: curation_concern)
      # depositor = curation_concern.depositor
      deposit_id = curation_concern.id
      deposit_url = ::Deepblue::EmailHelper.curation_concern_url( curation_concern: curation_concern )
      discipline = Array( curation_concern.subject_discipline ).first
      # requestor_email = requestor_email_for( curation_concern: curation_concern )
      jira_summary = '' # keep this blank for now, it'll be a marker for records ported from jira
      custom_attributes = []
      attr_depositor_status = TeamdynamixIntegrationService.attr_depositor_status
      attr_discipline       = TeamdynamixIntegrationService.attr_discipline
      attr_related_pub      = TeamdynamixIntegrationService.attr_related_pub
      attr_url_in_dbd       = TeamdynamixIntegrationService.attr_url_in_dbd
      attr_req_participants = TeamdynamixIntegrationService.attr_req_participants
      attr_uid              = TeamdynamixIntegrationService.attr_uid
      attr_summary          = TeamdynamixIntegrationService.attr_summary
      custom_attributes << { ATTR_ID => "#{attr_discipline}", ATTR_VALUE => discipline   } if discipline.present?
      custom_attributes << { ATTR_ID => "#{attr_url_in_dbd}", ATTR_VALUE => deposit_url  } if deposit_url.present?
      custom_attributes << { ATTR_ID => "#{attr_uid}",        ATTR_VALUE => deposit_id   } if deposit_id.present?
      custom_attributes << { ATTR_ID => "#{attr_summary}",    ATTR_VALUE => jira_summary } if jira_summary.present?
      return custom_attributes
    end

    def build_tdx_data( data: {}, form_id: @form_id, service_id: @service_id, type_id: @type_id )
      data ||= {}
      data["TypeID"] = type_id if type_id.present?
      data["ServiceID"] = service_id if service_id.present?
      data["FormID"] = form_id if form_id.present?
      rv = data
      msg_handler.msg_verbose { "build_tdx_data rv=#{ rv.pretty_inspect }" }
      return rv
    end

    def build_tdx_ticket_url( ticket_id: )
      rv = "#{tdx_url}#{ulib_app_id}/Tickets/TicketDet?TicketID=#{ticket_id}"
      msg_handler.msg_verbose "build_tdx_ticket_url rv=#{rv}"
      return rv
    end

    def connection?( debug_verbose: teamdynamix_service_debug_verbose )
      debug_verbose ||= teamdynamix_service_debug_verbose
      status, _body = group_search( debug_verbose: debug_verbose )
      return 200 == status
    end

    def creator_for( curation_concern: )
      rv = Array( curation_concern.creator ).first
      return rv
    end

    def create_ticket( title:, fields: {}, requestor_email:, debug_verbose: teamdynamix_service_debug_verbose )
      debug_verbose ||= teamdynamix_service_debug_verbose
      fields ||= {}
      build_access_token
      build_bearer
      parms="/um/it/#{ulib_app_id}/tickets"
      headers=build_headers( auth: bearer,
                             accept: APPLICATION_JSON,
                             content_type: APPLICATION_JSON,
                             debug_verbose: debug_verbose )
      data=build_tdx_data
      data["StatusID"] = 1012 # TODO: config
      data["PriorityID"] = 20 # TODO: config
      data["SourceID"] = 8 # TODO: config
      data["ResponsibleGroupID"] = 1227 # TODO: config
      # data["RequestorName"] = "???" # skip
      data["Title"] = title
      data["RequestorEmail"] = requestor_email
      data.merge! fields
      status, body = post( connection: build_connection( uri: tdx_rest_url, headers: headers ),
                           parms: parms,
                           data: data,
                           debug_verbose: debug_verbose )
      return status, body
    end

    def create_ticket_for( curation_concern:,
                           description: VALUE_UNKNOWN_DESCRIPTION,
                           title: VALUE_UNKNOWN_TITLE,
                           user_email: nil,
                           debug_verbose: teamdynamix_service_debug_verbose )

      debug_verbose ||= teamdynamix_service_debug_verbose
      requestor_email = user_email
      if curation_concern.present?
        title = build_title_for( curation_concern: curation_concern )
        fields = build_tdx_create_ticket_fields_with( curation_concern: curation_concern )
        requestor_email ||= requestor_email_for( curation_concern: curation_concern )
      else
        title ||= VALUE_UNKNOWN_TITLE
        description ||= VALUE_UNKNOWN_DESCRIPTION
        fields = { FIELD_DESCRIPTION => description }
        requestor_email ||= VALUE_UNKNOWN_REQUESTOR_EMAIL
      end
      status, body = create_ticket( title: title,
                                    fields: fields,
                                    requestor_email: requestor_email,
                                    debug_verbose: debug_verbose )
      msg_handler.msg_verbose "create_ticket_for status=#{status}"
      msg_handler.msg_verbose { "create_ticket_for response body=#{body.pretty_inspect}" } if debug_verbose
      if status == 200
        # body is parsed
        ticket_id = body[FIELD_ID]
        rv = build_tdx_ticket_url( ticket_id: ticket_id )
        @tdx_ticket_url = rv
      else
        rv = response_msg( responses )
      end
      return rv
    end

    def curation_notes_admin_includes_for( curation_concern:, search_value: )
      return false unless curation_concern.respond_to? :curation_notes_admin_include?
      curation_concern.curation_notes_admin_include? search_value
    end

    def description_for( curation_concern: )
      creator = creator_for(curation_concern: curation_concern)
      rv = Array( curation_concern.title ).join("\n") + "\n\nby #{creator}"
      return rv
    end

    def group_search( name_like: DEFAULT_GROUP_SEARCH_NAME_LIKE, debug_verbose: teamdynamix_service_debug_verbose )
      debug_verbose ||= teamdynamix_service_debug_verbose
      parms = '/um/it/groups/search'
      headers = build_headers( auth: bearer,
                               accept: APPLICATION_JSON,
                               content_type: TEXT_PLAIN,
                               debug_verbose: debug_verbose )
      data = build_data( data: { "IsActive" => true, "NameLike" => name_like } )
      status, body = post( connection: build_connection( uri: tdx_rest_url, headers: headers ),
                           parms: parms,
                           data: data,
                           debug_verbose: debug_verbose )
      return status, body
    end

    def has_service_request_ticket_for( curation_concern: )
      return false unless check_admin_notes_for_existing_ticket
      if curation_notes_admin_includes_for( curation_concern: curation_concern,
                                            search_value: admin_note_ticket_prefix )
       msg_handler.msg "curation concern admin notes already contains teamdynamix ticket"
       return true
      end
      return false
    end

    def post( connection:, parms:, data: nil, debug_verbose: teamdynamix_service_debug_verbose )
      debug_verbose ||= teamdynamix_service_debug_verbose
      if data.present?
        data = JSON.dump( data ) unless data.is_a? String
        msg_handler.msg_verbose { "data=#{data.pretty_inspect}" } if debug_verbose
        responses << connection.post( parms, data )
      else
        responses << connection.post( parms )
      end
      status, body = response_status_body
      return status, body
    end

    def requestor_email_for( curation_concern: )
      rv = curation_concern.depositor
      return rv
    end

    def response_is( index: nil, response: nil )
      return response if response.present?
      return nil if responses.blank?
      return responses.last if index.blank?
      return responses[index]
    end

    def response_body( index: nil, response: nil )
      rv = response_parse_body( index: index, response: response )
      return rv
    end

    def response_msg( index: nil, response: nil )
      rv = response_value( index: index, key: RESPONSE_MESSAGE, response: response )
      return rv
    end

    def response_id( index: nil, response: nil )
      rv = response_value( index: index, key: RESPONSE_ID, response: response )
      return rv
    end

    def response_parse_body( index: nil, response: nil )
      response = response_is( index: index, response: response )
      msg_handler.msg_verbose { "response=#{response.pretty_inspect}" }
      msg_handler.msg_verbose "response&.status=#{response&.status}"
      msg_handler.msg_verbose { "response&.body=#{response&.body.pretty_inspect}" }
      return '' unless response&.body.present?
      rv = JSON.parse( response.body )
      msg_handler.msg_verbose { "response_parse_body rv=#{rv.pretty_inspect}" }
      return rv
    end

    def response_status( index: nil, response: nil )
      response = response_is( index: index, response: response )
      return nil if response.blank?
      rv = response&.status
      msg_handler.msg_verbose "status=#{rv}"
      return rv
    end

    def response_status_body( index: nil, response: nil )
      response = response_is( index: index, response: response )
      return nil, nil if response.blank?
      status = response_status( response: response )
      body = response_body( response: response )
      return status, body
    end

    def response_value( index: nil, key:, response: nil )
      return nil if key.blank?
      body = response_body( index: index, response: response )
      return nil unless body.is_a? Hash
      rv = body[key]
      msg_handler.msg_verbose { "#{key}=#{rv.pretty_inspect}" }
      return rv
    end

    def rv_info( rv )
      msg_handler.msg_verbose "rv[0]['ID']=#{rv[0]['ID']}" if rv.is_a? Array
      msg_handler.msg_verbose { rv.pretty_inspect } # replace pp
    end

    def title_for( curation_concern: )
      rv = Array( curation_concern.title ).join('; ')
      return rv
    end

  end

end
