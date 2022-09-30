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

    MSG_HANDLER_DEBUG_ONLY = ::Deepblue::MessageHandlerDebugOnly.new( debug_verbose: ->() {
      teamdynamix_service_debug_verbose } ).freeze
    MSG_HANDLER_TO_CONSOLE = ::Deepblue::MessageHandler.msg_handler_for_task( options: {
      debug_verbose: teamdynamix_service_debug_verbose } )

    APPLICATION_JSON = 'application/json'

    ATTR_ID    = 'ID'
    ATTR_VALUE = 'Value'

    BUILD_ACCESS_TOKEN_EVERY_TIME = true

    DEFAULT_GROUP_SEARCH_NAME_LIKE = 'ULIB'

    KEY_ACCOUNT_ID           = 'AccountID'
    KEY_ATTRIBUTES           = 'Attributes'
    KEY_DESCRIPTION          = 'Description'
    KEY_ID                   = 'ID'
    KEY_IS_RICH_HTML         = 'IsRichHtml'
    KEY_PRIORITY_ID          = 'PriorityID'
    KEY_REQUESTOR_EMAIL      = 'RequestorEmail'
    KEY_REQUESTOR_NAME       = 'RequestorName'
    KEY_REQUESTOR_UID        = 'RequestorUid'
    KEY_RESPONSIBLE_GROUP_ID = 'ResponsibleGroupID'
    KEY_SOURCE_ID            = 'SourceID'
    KEY_STATUS_ID            = 'StatusID'
    KEY_TITLE                = 'Title'

    RESPONSE_ID      = 'ID'
    RESPONSE_MESSAGE = 'Message'

    TEXT_PLAIN = 'text/plain'

    VALUE_UNKNOWN_DESCRIPTION     = 'Unknown Description'
    VALUE_UNKNOWN_REQUESTOR_EMAIL = 'unknown@unknown.com'
    VALUE_UNKNOWN_TITLE           = 'Unknown Title'

    attr_accessor :access_token
    attr_accessor :account_id
    attr_accessor :authentication
    attr_accessor :bearer
    attr_accessor :bearer_basic
    attr_accessor :client_id
    attr_accessor :client_secret
    attr_accessor :its_app_id
    attr_accessor :msg_handler
    attr_accessor :responses
    attr_accessor :responsible_group_id
    attr_accessor :tdx_ticket_id
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
                                             "" ], bold_puts: true if teamdynamix_service_debug_verbose
      msg_handler ||= MSG_HANDLER_DEBUG_ONLY
      @msg_handler = msg_handler
      msg_handler.msg_debug_bold [ msg_handler.here, msg_handler.called_from ] if msg_handler.debug_verbose
      # msg_handler.msg_debug_bold [ "Printed...#{puts 'and this'}" ] if msg_handler.debug_verbose
      # msg_handler.msg_debug_bold [ "Not printed...#{puts 'this either'}" ] if false
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
      @tdx_ticket_id  = nil
      @tdx_ticket_url = nil
      @tdx_url        = TeamdynamixIntegrationService.tdx_url
      @ulib_app_id    = TeamdynamixIntegrationService.ulib_app_id
      @account_id     = TeamdynamixIntegrationService.account_id
      @form_id        = TeamdynamixIntegrationService.form_id
      @service_id     = TeamdynamixIntegrationService.service_id
      @type_id        = TeamdynamixIntegrationService.type_id

      @responsible_group_id = TeamdynamixIntegrationService.responsible_group_id

      # data[KEY_STATUS_ID] = 1012 # TODO: config
      # data[KEY_PRIORITY_ID] = 20 # TODO: config
      # data[KEY_SOURCE_ID] = 8 # TODO: config
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

    def add_tdx_ticket_link_to( curation_concern:, tdx_ticket_url: )
      note = build_curation_notes_admin_link( tdx_ticket_url: tdx_ticket_url )
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
      build_bearer_basic
      headers = build_headers( auth: bearer_basic, content_type: 'application/x-www-form-urlencoded' )
      parms = '/um/it/oauth2/token?scope=tdxticket&grant_type=client_credentials'
      status, body = post( connection: build_connection( uri: tdx_rest_url, headers: headers ),
                            parms: parms )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                msg_handler.called_from,
                                "status=#{status}",
                                "body=#{body.pretty_inspect}" ] if msg_handler.debug_verbose
      rv=body['access_token']
      msg_handler.msg_debug_bold [ msg_handler.here,
                                msg_handler.called_from,
                                "access_token=#{rv}",
                                "" ] if msg_handler.debug_verbose
      rv
    end

    def build_authentication
      rv = "#{client_id}:#{client_secret}"
      msg_handler.msg_verbose "authentication=#{rv}"
      rv
    end

    def build_bearer
      rv = "Bearer #{access_token}"
      msg_handler.msg_debug_bold [ msg_handler.here,
                               msg_handler.called_from,
                               "bearer=#{rv}",
                               "" ] if msg_handler.debug_verbose
      # msg_handler.msg_verbose "bearer=#{rv}"
      rv
    end

    def build_bearer_basic
      rv = "Bearer Basic #{Base64.strict_encode64(authentication)}"
      msg_handler.msg_debug_bold [ msg_handler.here,
                                msg_handler.called_from,
                                "bearer_basic=#{rv}",
                                "" ] if msg_handler.debug_verbose
      # msg_handler.msg_verbose "bearer_basic=#{rv}"
      rv
    end

    def build_connection( uri:, headers: {} )
      return Faraday.new(uri, headers: headers) if headers.present?
      return Faraday.new(uri)
    end

    def build_curation_notes_admin_link( tdx_ticket_url: )
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
      msg_handler.msg_debug_bold [ "data=#{rv.pretty_inspect}" ] if msg_handler.debug_verbose
      return rv
    end

    def build_headers( accept: APPLICATION_JSON, auth:, content_type: TEXT_PLAIN, charset: nil )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                msg_handler.called_from,
                                "accept=#{accept}",
                                "auth=#{auth}",
                                "content_type=#{content_type}",
                                "charset=#{charset}",
                                "" ] if msg_handler.debug_verbose
      # msg_handler.msg_verbose "auth=#{auth}"
      rv = {}
      rv['Content-Type'] = content_type if content_type.present?
      rv['X-IBM-Client-Id'] = @client_id
      rv['Accept'] = accept if accept.present?
      rv['Authorization'] = auth if auth.present?
      rv['charset'] = charset if charset.present?
      msg_handler.msg_debug_bold [ msg_handler.here,
                                msg_handler.called_from,
                                "headers=#{rv.pretty_inspect}" ]  if msg_handler.debug_verbose
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
      # Title: [Depositor last name] _ [First two words of deposit] _ [deposit ID]
      # - e.g., Nasser_BootAcceleration_n583xv03w
      title = build_title( curation_concern: curation_concern )
      last_name = build_title_last_name( curation_concern: curation_concern )
      rv = "#{last_name}_#{title}_#{curation_concern.id}"
      return rv
    end

    def build_tdx_create_ticket_fields_with( curation_concern:, fields: {} )
      fields ||= {}
      fields[KEY_DESCRIPTION] = build_description_from( curation_concern: curation_concern )
      fields[KEY_IS_RICH_HTML] = true
      fields[KEY_ATTRIBUTES] = build_tdx_custom_attributes( curation_concern: curation_concern )
      msg_handler.msg_debug_bold [ "build_tdx_create_ticket_fields_with rv=#{fields.pretty_inspect}",
                                   "" ] if msg_handler.debug_verbose
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

    def build_tdx_data( data: {},
                        account_id: @account_id,
                        form_id: @form_id,
                        service_id: @service_id,
                        type_id: @type_id )
      data ||= {}
      data[KEY_ACCOUNT_ID] = account_id if account_id.present?
      data["TypeID"] = type_id if type_id.present?
      data["ServiceID"] = service_id if service_id.present?
      data["FormID"] = form_id if form_id.present?
      rv = data
      msg_handler.msg_debug_bold [ "build_tdx_data rv=#{ rv.pretty_inspect }" ] if msg_handler.debug_verbose
      return rv
    end

    def build_tdx_ticket_url( ticket_id: )
      # empty ticket_id is okay
      rv = "#{tdx_url}#{ulib_app_id}/Tickets/TicketDet?TicketID=#{ticket_id}"
      # msg_handler.msg_verbose "build_tdx_ticket_url rv=#{rv}"
      return rv
    end

    def connection?
      status, _body = group_search
      return 200 == status
    end

    def creator_for( curation_concern: )
      rv = Array( curation_concern.creator ).first
      return rv
    end

    def create_ticket( title:, fields: {}, requestor_email: )
      msg_handler.msg_debug_bold [ msg_handler.here,
                               msg_handler.called_from,
                               "" ] if msg_handler.debug_verbose
      fields ||= {}
      build_access_token
      build_bearer
      parms="/um/it/#{ulib_app_id}/tickets"
      headers=build_headers( auth: bearer,
                             accept: APPLICATION_JSON,
                             content_type: APPLICATION_JSON )
      data=build_tdx_data
      data[KEY_STATUS_ID] = 1012 # TODO: config
      data[KEY_PRIORITY_ID] = 20 # TODO: config
      data[KEY_SOURCE_ID] = 8 # TODO: config
      data[KEY_RESPONSIBLE_GROUP_ID] = responsible_group_id
      # data[KEY_REQUESTOR_NAME] = "???" # skip
      data[KEY_TITLE] = title
      data[KEY_REQUESTOR_EMAIL] = requestor_email
      data.merge! fields
      msg_handler.msg_debug_bold [ msg_handler.here,
                               msg_handler.called_from,
                               "uri=#{tdx_rest_url}",
                               "headers=#{headers.pretty_inspect}",
                               "parms=#{parms.pretty_inspect}",
                               "data=#{data.pretty_inspect}",
                               "" ] if msg_handler.debug_verbose
      status, body = post( connection: build_connection( uri: tdx_rest_url, headers: headers ),
                           parms: parms,
                           data: data )
      msg_handler.msg_debug_bold [ msg_handler.here,
                               msg_handler.called_from,
                               "status=#{status}",
                               "body=#{body.pretty_inspect}",
                               "" ] if msg_handler.debug_verbose
      return status, body
    end

    def create_ticket_for( curation_concern:,
                           description: VALUE_UNKNOWN_DESCRIPTION,
                           title: VALUE_UNKNOWN_TITLE,
                           user_email: nil )

      requestor_email = user_email
      if curation_concern.present?
        title = build_title_for( curation_concern: curation_concern )
        fields = build_tdx_create_ticket_fields_with( curation_concern: curation_concern )
        requestor_email ||= requestor_email_for( curation_concern: curation_concern )
      else
        title ||= VALUE_UNKNOWN_TITLE
        description ||= VALUE_UNKNOWN_DESCRIPTION
        fields = { KEY_DESCRIPTION => description }
        requestor_email ||= VALUE_UNKNOWN_REQUESTOR_EMAIL
      end
      status, body = create_ticket( title: title, fields: fields, requestor_email: requestor_email )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                   msg_handler.called_from,
                                   "status=#{status}",
                                   "body=#{body.pretty_inspect}",
                                   "" ] if msg_handler.debug_verbose
       if status == 200
        # body is parsed into a hash
        @tdx_ticket_id = body[KEY_ID]
        rv = build_tdx_ticket_url( ticket_id: @tdx_ticket_id )
        add_tdx_ticket_link_to( curation_concern: curation_concern, tdx_ticket_url: rv )
        @tdx_ticket_url = rv
        status2, body2 = update_ticket_if_needed( ticket_id: @tdx_ticket_id )
        msg_handler.msg_debug_bold [ msg_handler.here,
                                     msg_handler.called_from,
                                     "status2=#{status2}",
                                     "body2=#{body2.pretty_inspect}",
                                     "" ] if msg_handler.debug_verbose
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

    def get( connection:, parms: )
      responses << connection.get( parms )
      status, body = response_status_body
      return status, body
    end

    def get_ticket( ticket_id: )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "ticket_id=#{ticket_id}",
                                             "" ] if msg_handler.debug_verbose
      build_access_token
      build_bearer
#       curl --location --request GET 'https://apigw-tst.it.umich.edu/um/it/31/tickets/425' \
# --header 'Accept: application/json' \
# --header 'Authorization: Bearer <access_token>' \
# --header 'x-ibm-client-id: application_client_id'
      parms="/um/it/#{ulib_app_id}/tickets/#{ticket_id}"
      headers=build_headers( auth: bearer, accept: APPLICATION_JSON )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "uri=#{tdx_rest_url}",
                                             "headers=#{headers.pretty_inspect}",
                                             "" ] if msg_handler.debug_verbose

      status, body = get( connection: build_connection( uri: tdx_rest_url, headers: headers ), parms: parms )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "status=#{status}",
                                             "body=#{body.pretty_inspect}",
                                             "" ] if msg_handler.debug_verbose
      return status, body
    end

    def get_ticket_body( ticket_id: )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "ticket_id=#{ticket_id}",
                                             "" ] if msg_handler.debug_verbose
      status, body = get_ticket( ticket_id: ticket_id )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "ticket_id=#{ticket_id}",
                                             "status=#{status}",
                                             "body=#{body.pretty_inspect}",
                                             "" ] if msg_handler.debug_verbose
      rv = {}
      rv = body if 200 == status
      return rv
    end

    def group_search( name_like: DEFAULT_GROUP_SEARCH_NAME_LIKE )
      parms = '/um/it/groups/search'
      headers = build_headers( auth: bearer,
                               accept: APPLICATION_JSON,
                               content_type: TEXT_PLAIN )
      data = build_data( data: { "IsActive" => true, "NameLike" => name_like } )
      status, body = post( connection: build_connection( uri: tdx_rest_url, headers: headers ),
                           parms: parms,
                           data: data )
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

    def post( connection:, parms:, data: nil )
      if data.present?
        data = JSON.dump( data ) unless data.is_a? String
        msg_handler.msg_debug_bold [ msg_handler.here,
                                     msg_handler.called_from,
                                    "data=#{data.pretty_inspect}",
                                     "" ] if msg_handler.debug_verbose
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

    def reset_description_for( curation_concern: )
      msg_handler.msg_debug_bold [ msg_handler.here,
                               msg_handler.called_from,
                               "curation_concern.id=#{curation_concern.id}",
                               "" ] if msg_handler.debug_verbose
      ticket_id = ticket_id_from_curation_notes_admin( curation_concern: curation_concern )
      return if ticket_id.blank?
      description = build_description_from( curation_concern: curation_concern )
      update_ticket( ticket_id: ticket_id, description: description, description_replace: true )
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
      msg_handler.msg_debug_bold [ "response=#{response.pretty_inspect}",
                                   "response&.status=#{response&.status}",
                                   "response&.body=#{response&.body.pretty_inspect}",
                                   "" ] if msg_handler.debug_verbose
      return '' unless response&.body.present?
      rv = JSON.parse( response.body )
      msg_handler.msg_debug_bold [ "response_parse_body rv=#{rv.pretty_inspect}" ] if msg_handler.debug_verbose
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
      msg_handler.msg_debug_bold [ "#{key}=#{rv.pretty_inspect}" ] if msg_handler.debug_verbose
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

    def ticket_body_for( curation_concern: )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if msg_handler.debug_verbose
      search_text = build_title_for( curation_concern: curation_concern )
      status, body = ticket_search( search_text: search_text )
      rv = {}
      rv = body[0] if 200 == status && body.is_a?( Array ) && body.size > 0
      return rv
    end

    def ticket_body_from_ticket_id( ticket_id: )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "ticket_id=#{ticket_id}",
                                             "" ] if msg_handler.debug_verbose
      status, body = ticket_search( ticket_id: ticket_id, max_results: 1 )
      rv = {}
      rv = body[0] if 200 == status && body.is_a?( Array ) && body.size > 0
      return rv
    end

    def ticket_id_from_curation_notes_admin( curation_concern: )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if msg_handler.debug_verbose
      return nil unless curation_concern.respond_to? :curation_notes_admin
      prefix = Regexp.escape admin_note_ticket_prefix
      url = Regexp.escape build_tdx_ticket_url( ticket_id: '' )
      search_re = /^.*#{prefix}#{url}(\d+).*$/
      curation_concern.curation_notes_admin.each do |note|
        if note =~ search_re
          ticket_id = Regexp.last_match(1)
          return ticket_id
        end
      end
      return nil
    end

    def ticket_search( ticket_id: nil, search_text: nil,  max_results: 10 )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "ticket_id=#{ticket_id}",
                                             "search_text=#{search_text}",
                                             "max_results=#{max_results}",
                                             "" ] if msg_handler.debug_verbose
      build_access_token
      build_bearer
      parms="/um/it/#{ulib_app_id}/ticketsearch"
      headers=build_headers( auth: bearer, content_type: APPLICATION_JSON )
      data=build_tdx_data
      data['MaxResults'] = max_results
      data['TicketID'] = ticket_id if ticket_id.present?
      data['SearchText'] = search_text if search_text.present?
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "uri=#{tdx_rest_url}",
                                             "headers=#{headers.pretty_inspect}",
                                             "parms=#{parms.pretty_inspect}",
                                             "data=#{data.pretty_inspect}",
                                             "" ] if msg_handler.debug_verbose
      status, body = post( connection: build_connection( uri: tdx_rest_url, headers: headers ),
                           parms: parms,
                           data: data )
      # body should be an array
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "status=#{status}",
                                             "body=#{body.pretty_inspect}",
                                             "" ] if msg_handler.debug_verbose
      return status, body
    end

    def ticket_search_by_cc_id( curation_concern: )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if msg_handler.debug_verbose
      search_text = curation_concern.id
      status, body = ticket_search( search_text: search_text )
      rv = {}
      rv = body[0] if 200 == status && body.is_a?( Array ) && body.size > 0
      return rv
    end

    def update_ticket_needed( ticket_id:, ticket_body: nil, description: nil, force_update: false )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "ticket_id=#{ticket_id}",
                                             "ticket_body.present?=#{ticket_body.present?}",
                                             "description=#{description}",
                                             "force_update=#{force_update}",
                                             "" ] if msg_handler.debug_verbose
      return true if force_update || description.present?
      ticket_body ||= ticket_body_from_ticket_id( ticket_id: ticket_id )
      msg_handler.msg_debug_bold [ msg_handler.here,
                           msg_handler.called_from,
                           "account_id=#{account_id}",
                           "ticket_body[KEY_ACCOUNT_ID] == account_id=#{ticket_body[KEY_ACCOUNT_ID] == account_id}",
                           "" ] if msg_handler.debug_verbose
      return true unless ticket_body[KEY_ACCOUNT_ID] == account_id
      msg_handler.msg_debug_bold [ msg_handler.here,
         msg_handler.called_from,
         "responsible_group_id=#{responsible_group_id}",
         "ticket_body[KEY_RESPONSIBLE_GROUP_ID] == responsible_group_id=#{ticket_body[KEY_RESPONSIBLE_GROUP_ID] == responsible_group_id}",
         "" ] if msg_handler.debug_verbose
      return true unless ticket_body[KEY_RESPONSIBLE_GROUP_ID] == responsible_group_id
      return false
    end

    def update_ticket( ticket_id:, ticket_body: nil, description: '', description_replace: false )
      description ||= ''
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "ticket_id=#{ticket_id}",
                                             "ticket_body.present?=#{ticket_body.present?}",
                                             "description=#{description}",
                                             "description_replace=#{description_replace}",
                                             "" ] if msg_handler.debug_verbose
      ticket_body ||= get_ticket_body( ticket_id: ticket_id )
      msg_handler.msg_error_if?( ticket_body.blank?, msg: "update_ticket_if_needed ticket_body is nil" )
      return nil, {} if ticket_body.blank?
      priority_id = ticket_body[KEY_PRIORITY_ID]
      requestor_uid = ticket_body[KEY_REQUESTOR_UID]
      status_id = ticket_body[KEY_STATUS_ID]
      title = ticket_body[KEY_TITLE]
      new_description = ''
      new_description = ticket_body[KEY_DESCRIPTION] unless description_replace
      new_description = "#{new_description}#{description}"
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "new_description=#{new_description}",
                                             "" ] if msg_handler.debug_verbose
      fields = {}
      fields[KEY_DESCRIPTION] = new_description
      fields[KEY_IS_RICH_HTML] = true
      status, body = update_ticket_with( ticket_id: ticket_id,
                                         account_id: account_id,
                                         priority_id: priority_id,
                                         requestor_uid: requestor_uid,
                                         responsible_group_id: responsible_group_id,
                                         status_id: status_id,
                                         title: title,
                                         fields: fields )
      return status, body
    end

    def update_ticket_if_needed( ticket_id:, description: '', description_replace: false, force_update: false )
      description ||= ''
      msg_handler.msg_debug_bold [ msg_handler.here,
                                   msg_handler.called_from,
                                   "ticket_id=#{ticket_id}",
                                   "description=#{description}",
                                   "description_replace=#{description_replace}",
                                   "force_update=#{force_update}",
                                   "" ] if msg_handler.debug_verbose
      ticket_body = get_ticket_body( ticket_id: ticket_id )
      return nil, {} unless update_ticket_needed( ticket_id: ticket_id,
                                                  ticket_body: ticket_body,
                                                  description: description,
                                                  force_update: force_update )
      msg_handler.msg_error_if?( ticket_body.blank?, msg: "update_ticket_if_needed ticket_body is nil" )
      return update_ticket( ticket_id: ticket_id,
                            ticket_body: ticket_body,
                            description: description,
                            description_replace: description_replace )
    end

    def update_ticket_with( ticket_id:,
                            account_id:,
                            priority_id:,
                            requestor_uid:,
                            responsible_group_id:,
                            status_id:,
                            title:,
                            fields: {} )

      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "ticket_id=#{ticket_id}",
                                             "account_id=#{account_id}",
                                             "priority_id=#{priority_id}",
                                             "requestor_uid=#{requestor_uid}",
                                             "responsible_group_id=#{responsible_group_id}",
                                             "status_id=#{status_id}",
                                             "title=#{title}",
                                             "fields=#{fields.pretty_inspect}",
                                             "" ] if msg_handler.debug_verbose
      fields ||= {}
      build_access_token
      build_bearer
      parms="/um/it/#{ulib_app_id}/tickets/#{ticket_id}"
      headers=build_headers( auth: bearer,
                             accept: APPLICATION_JSON,
                             content_type: APPLICATION_JSON,
                             charset: 'utf-8' )
      data=build_tdx_data( account_id: account_id )
      data[KEY_ACCOUNT_ID] = account_id
      data[KEY_PRIORITY_ID] = priority_id
      data[KEY_REQUESTOR_UID] = requestor_uid
      data[KEY_RESPONSIBLE_GROUP_ID] = responsible_group_id
      data[KEY_STATUS_ID] = status_id
      data[KEY_TITLE] = title
      data.merge! fields
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "uri=#{tdx_rest_url}",
                                             "headers=#{headers.pretty_inspect}",
                                             "parms=#{parms.pretty_inspect}",
                                             "data=#{data.pretty_inspect}",
                                             "" ] if msg_handler.debug_verbose
      status, body = post( connection: build_connection( uri: tdx_rest_url, headers: headers ),
                           parms: parms,
                           data: data )
      msg_handler.msg_debug_bold [ msg_handler.here,
                                             msg_handler.called_from,
                                             "status=#{status}",
                                             "body=#{body.pretty_inspect}",
                                             "" ] if msg_handler.debug_verbose
      return status, body
    end

  end

end
