# frozen_string_literal: true

module Deepblue

  require 'jira-ruby' # https://github.com/sumoheavy/jira-ruby

  module JiraHelper
    extend ActionView::Helpers::TranslationHelper

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

    FIELD_NAME_CONTACT_INFO = "customfield_11315".freeze unless const_defined? :FIELD_NAME_CONTACT_INFO
    FIELD_NAME_CREATOR = "customfield_11304".freeze unless const_defined? :FIELD_NAME_CREATOR
    FIELD_NAME_DEPOSIT_ID = "customfield_11303".freeze unless const_defined? :FIELD_NAME_DEPOSIT_ID
    FIELD_NAME_DEPOSIT_URL = "customfield_11305".freeze unless const_defined? :FIELD_NAME_DEPOSIT_URL
    FIELD_NAME_DESCRIPTION = "description".freeze unless const_defined? :FIELD_NAME_DESCRIPTION
    FIELD_NAME_DISCIPLINE = "customfield_11309".freeze unless const_defined? :FIELD_NAME_DISCIPLINE
    FIELD_NAME_REPORTER = "reporter".freeze unless const_defined? :FIELD_NAME_REPORTER
    FIELD_NAME_STATUS = "customfield_12000".freeze unless const_defined? :FIELD_NAME_STATUS
    FIELD_NAME_SUMMARY = "summary".freeze unless const_defined? :FIELD_NAME_SUMMARY

    mattr_accessor :jira_allow_add_comment
    mattr_accessor :jira_allow_create_users
    mattr_accessor :jira_field_values_discipline_map
    mattr_accessor :jira_helper_debug_verbose
    mattr_accessor :jira_integration_hostnames
    mattr_accessor :jira_integration_hostnames_prod
    mattr_accessor :jira_integration_enabled
    mattr_accessor :jira_manager_project_key
    mattr_accessor :jira_manager_issue_type
    mattr_accessor :jira_rest_url
    mattr_accessor :jira_rest_api_url
    mattr_accessor :jira_rest_create_users_url
    mattr_accessor :jira_test_mode
    mattr_accessor :jira_url
    mattr_accessor :jira_use_authoremail_as_requester, default: false

    def self.jira_add_comment( curation_concern:, event:, comment: )
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "jira_enabled=#{jira_enabled}",
                                              "jira_allow_add_comment=#{jira_allow_add_comment}",
                                              "" ] ) if jira_helper_debug_verbose
      return unless jira_enabled
      return unless jira_allow_add_comment
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "curation_concern.id=#{curation_concern.id}",
                                              "curation_concern.curation_notes_admin=#{curation_concern.curation_notes_admin}",
                                              "" ] ) if jira_helper_debug_verbose
      # jira url is stored:
      curation_concern.curation_notes_admin.each do |note|
        ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                "note=#{note}",
                                                "" ] ) if jira_helper_debug_verbose
        if note =~ /^\s*Jira ticket: https?:[^\s]+(DBHELP\-\d+).*$/
          issue_key = Regexp.last_match(1)
          ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                  "issue_key=#{issue_key}",
                                                  "" ] ) if jira_helper_debug_verbose
          if comment.blank?
            comment = event
          else
            comment = "#{event}\n\n#{comment}"
          end
          return jira_service_desk_request_comment( issue_key: issue_key, comment: comment )
        end
      end
      return false
    end

    def self.jira_build_summary_for( curation_concern: )
      summary_title = summary_title( curation_concern: curation_concern )
      summary_last_name = summary_last_name( curation_concern: curation_concern )
      rv = "#{summary_last_name}_#{summary_title}_#{curation_concern.id}"
      return rv
    end

    def self.jira_client( client: nil, jira_is_enabled: jira_enabled, is_verbose: false )
      return client if client.present?
      return client unless jira_is_enabled
      return client if jira_test_mode && !jira_is_enabled
      # TODO: catch errors
      client = JIRA::Client.new( jira_client_options )
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "client.to_json=#{client.to_json}",
                                              "" ],
                                            bold_puts: is_verbose ) if is_verbose || jira_helper_debug_verbose
      return client
    end

    def self.jira_client_options
      return {
          :username     => Settings.jira.username,
          :password     => Settings.jira.password,
          :site         => Settings.jira.site_url,
          :context_path => '/jira',
          :auth_type    => :basic
      }
    end

    # return true if the create user was successful
    def self.jira_create_user( email:, client: nil, is_verbose: false, delay_after_create: 10 )
      return false unless jira_enabled
      return false unless jira_allow_create_users
      return false if email.blank?
      client = jira_client( client: client )
      if email =~ /^([^@]+)@.+$/
        username = Regexp.last_match(1)
      end
      return false if username.blank?
      user_options = { "username" => username, "emailAddress" => email, "displayName" => email }
      path = jira_rest_create_users_url
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "user_options=#{user_options}",
                                              "path=#{path}",
                                              "" ],
                                            bold_puts: is_verbose ) if is_verbose || jira_helper_debug_verbose
      post_rv = client.post( path, user_options.to_json )
      jira_debug_verbose_for_client_response( client: client, response: post_rv, is_verbose: is_verbose )
      rv = "200" == post_rv.code
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "post_rv=#{post_rv}",
                                              "post_rv.code.class.name=#{post_rv.code.class.name}",
                                              "post_rv.code=#{post_rv.code}",
                                              "rv=#{rv}",
                                              "" ],
                                            bold_puts: is_verbose ) if is_verbose || jira_helper_debug_verbose
      sleep delay_after_create if rv && ( delay_after_create > 0 )
      return rv
    end

    def self.jira_debug_verbose_for_client_response( client:, response:, is_verbose: )
      return if !( is_verbose || jira_helper_debug_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "client&.to_json=#{client&.to_json}",
                                             "response.class.name=#{response.class.name}",
                                             "response&.code=#{response.code}",
                                             "response&.code_type=#{response&.code_type}",
                                             "response&.header=#{response&.header}",
                                             "response&.error_type=#{response&.error_type}",
                                             "response&.content_length=#{response&.content_length}",
                                             "response&.content_type=#{response&.content_type}",
                                             "response&.message=#{response&.message}",
                                             # "response.methods.sort=#{response.methods.sort.join("\n")}",
                                             "" ],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      return unless response.respond_to? :content_type
      case response.content_type
      when "text/html"
        ::Deepblue::LoggingHelper.bold_debug [ "",
                                               "response.body=",
                                               "\n#{::Deepblue::LoggingHelper.strip_html_for_debug_dump(response.body)}",
                                               "" ],
                                             bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      when "application/json"
        ::Deepblue::LoggingHelper.bold_debug [ "",
                                               "response.body.to_json=",
                                               "\n#{::Deepblue::LoggingHelper.strip_html_for_debug_dump(response.body.to_json)}",
                                               "" ],
                                             bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      else
        ::Deepblue::LoggingHelper.bold_debug [ "",
                                               "response.body=",
                                               "\n#{response.body}",
                                               "" ],
                                             bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      end
    end

    def self.jira_enabled
      JiraHelper.jira_integration_enabled
    end

    def self.jira_new_ticket( client: nil,
                              deposit_id:,
                              deposit_url:,
                              description:,
                              discipline:,
                              requester:,
                              requester_email:,
                              summary:,
                              msg_queue: nil,
                              is_verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "return if client.blank? #{client.blank?} && !jira_enabled=#{!jira_enabled}",
                                             "deposit_id=#{deposit_id}",
                                             "deposit_url=#{deposit_url}",
                                             "description=#{description}",
                                             "discipline=#{discipline}",
                                             "requester=#{requester}",
                                             "requester_email=#{requester_email}",
                                             "summary=#{summary}",
                                             "jira_enabled=#{jira_enabled}",
                                             "" ],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose

      if client.blank? && !jira_enabled
        msg_queue << "jira client is blank and jira is not enabled" unless msg_queue.nil?
        return nil
      end

      summary = summary.gsub( /\n/, ' ' ) if summary.present?
      # requester is a structure, we need to pass requester_email, but since raiseOnBehalfOf and requestParticipants
      # don't seem to do anything, we'll skip it
      issue = jira_service_desk_request_new_ticket( client: client, summary: summary, is_verbose: is_verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "summary=#{summary}",
                                             "description=#{description}",
                                             "requester=#{requester}",
                                             "requester_email=#{requester_email}",
                                             "issue.present?=#{issue.present?}",
                                             "" ],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      return nil unless issue.present?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "issue.attrs=#{issue.attrs}",
                                             "" ],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose

      # TODO: test issue for validity

      jira_new_ticket_add_fields( client: client,
                                  issue: issue,
                                  deposit_id: deposit_id,
                                  deposit_url: deposit_url,
                                  description: description,
                                  discipline: discipline,
                                  requester: requester,
                                  requester_email: requester_email,
                                  is_verbose: is_verbose )

      url = ticket_url( client: client, issue: issue )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      return url
    end

    def self.jira_new_ticket_add_fields( client:,
                                         issue:,
                                         deposit_id:,
                                         deposit_url:,
                                         description:,
                                         discipline:,
                                         merge_updates: false,
                                         requester:,
                                         requester_email:,
                                         is_verbose: false )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "return if client.blank? #{client.blank?} && !jira_enabled=#{!jira_enabled}",
                                             "deposit_id=#{deposit_id}",
                                             "deposit_url=#{deposit_url}",
                                             "description=#{description}",
                                             "discipline=#{discipline}",
                                             "requester=#{requester}",
                                             "requester_email=#{requester_email}",
                                             "merge_updates=#{merge_updates}",
                                             "" ],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      return nil if client.blank? && !jira_enabled
      # Do one by one so we know what fails
      sopts = { "fields" => { FIELD_NAME_DESCRIPTION => description } }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ],
                                            bold_puts: is_verbose ) unless rv
      if requester.present?
        sopts = { "fields" => { FIELD_NAME_REPORTER => requester } }
        rv = issue.save( sopts )
        ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                ::Deepblue::LoggingHelper.called_from,
                                                "issue.save( #{sopts} ) rv=#{rv}",
                                                "issue.attrs=#{issue.attrs}",
                                                "" ],
                                              bold_puts: is_verbose ) unless rv
      end
      sopts = { "fields" => { FIELD_NAME_CONTACT_INFO => requester_email } }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ],
                                            bold_puts: is_verbose ) unless rv
      sopts = { "fields" => { FIELD_NAME_DEPOSIT_ID => deposit_id } }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ],
                                            bold_puts: is_verbose ) unless rv
      sopts = { "fields" => { FIELD_NAME_DEPOSIT_URL => deposit_url } }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ],
                                            bold_puts: is_verbose ) unless rv
      sopts = { "fields" => { FIELD_NAME_DISCIPLINE => jira_field_values_discipline_map[discipline] } }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ],
                                            bold_puts: is_verbose ) unless rv
      return issue
    end

    def self.jira_requester( client: nil, user: nil, is_verbose: false, delay_after_create_user: 0 )
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "jira_requester( user: #{user} )",
                                              "delay_after_create_user=#{delay_after_create_user}",
                                              "" ] ) if jira_helper_debug_verbose
      return { name: user } unless jira_enabled
      return { name: user } if jira_test_mode
      return {} if user.nil?
      client = jira_client( client: client )
      hash = jira_user_as_hash( user: user, client: client, is_verbose: is_verbose )
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "hash=#{hash}",
                                              "" ] ) if jira_helper_debug_verbose
      return hash if hash.present?
      if jira_create_user( client: client,
                           email: user,
                           is_verbose: is_verbose,
                           delay_after_create: delay_after_create_user )
        ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                ::Deepblue::LoggingHelper.called_from,
                                                "try jira_user_as_hash after successful create user",
                                                "" ] ) if jira_helper_debug_verbose
        hash = jira_user_as_hash( user: user, client: client, is_verbose: is_verbose )
        ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                                ::Deepblue::LoggingHelper.called_from,
                                                "hash=#{hash}",
                                                "" ] ) if jira_helper_debug_verbose
        return hash if hash.present?
      end
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "failed to find or create user, returning nil",
                                              "" ] ) if jira_helper_debug_verbose
      return nil
    end

    def self.jira_service_desk_request_comment( client: nil,
                                                issue_key:,
                                                comment:,
                                                public_comment: true,
                                                is_verbose: false )

      # raiseOnBehalfOf and requestParticipants don't seem to do anything
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "return if client.blank? #{client.blank?} && !jira_enabled=#{!jira_enabled}",
                                             "issue_key=#{issue_key}",
                                             "comment=#{comment}",
                                             "public_comment=#{public_comment}",
                                             "" ],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      return nil if client.blank? && !jira_enabled
      data = {
          "body": comment,
          "public": public_comment,
      }
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             "data=#{data}",
                                             "" ],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      uri = "#{JiraHelper.jira_rest_url}servicedeskapi/request/#{issue_key}/comment"
      uri_parsed = URI.parse( uri )
      request = Net::HTTP::Post.new( uri_parsed )
      request.basic_auth( Settings.jira.username, Settings.jira.password )
      request.content_type = "application/json"
      request.body = JSON.dump( data )
      req_options = { use_ssl: uri_parsed.scheme == "https" }
      response = Net::HTTP.start( uri_parsed.hostname, uri_parsed.port, req_options) do |http|
        http.request( request )
      end
      status = response.code
      return true if '201' == status
      jira_debug_verbose_for_client_response( client: client, response: response, is_verbose: is_verbose )
      return false
    end

    def self.jira_service_desk_request_new_ticket( client: nil, summary:, is_verbose: false )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "return if client.blank? #{client.blank?} && !jira_enabled=#{!jira_enabled}",
                                             "client&.to_json=#{client&.to_json}",
                                             "summary=#{summary}",
                                             "" ],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      return nil if client.blank? && !jira_enabled
      data = {
          "serviceDeskId": "19", # TODO: move to config
          "requestTypeId": "174", # TODO: move to config
          "requestFieldValues": { "summary": summary }
      }
      # # raiseOnBehalfOf and requestParticipants don't seem to do anything
      # data.merge!( { "raiseOnBehalfOf": requester_email } ) if requester_email.present?
      # data.merge!( { "requestParticipants": [ requester_email ] } ) if requester_email.present?
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             "data=#{data}",
                                             "" ], bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      uri = "#{JiraHelper.jira_rest_url}servicedeskapi/request"
      uri_parsed = URI.parse( uri )
      request = Net::HTTP::Post.new( uri_parsed )
      request.basic_auth( Settings.jira.username, Settings.jira.password )
      request.content_type = "application/json"
      request.body = JSON.dump( data )
      req_options = { use_ssl: uri_parsed.scheme == "https" }
      response = Net::HTTP.start( uri_parsed.hostname, uri_parsed.port, req_options) do |http|
        http.request( request )
      end
      jira_debug_verbose_for_client_response( client: client, response: response, is_verbose: is_verbose )
      if '400' == response.code && 'application/json' == response.content_type
        json = JSON.parse( response.body )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "json[\"errorMessage\"]=#{json["errorMessage"]}",
                                               "" ],
                                             bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
        if json["errorMessage"].starts_with?( "Sorry, but the following usernames could not be added as participant to this request:" )
          # retry without the user
          return jira_service_desk_request_new_ticket( client: client, summary: summary, is_verbose: is_verbose )
        end
      end

      return nil if [ '400', '401' ].include? response.code
      json = JSON.parse( response.body )
      issueKey = json["issueKey"]
      client = jira_client( client: client )
      issue = client.Issue.find( issueKey )
      return issue
    rescue JIRA::HTTPError => e
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "e.class.name=#{e.class.name}",
                                             "e.message=#{e.message}",
                                             "" ] + e.backtrace[0..20],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
      return nil
    rescue JSON::ParserError => e2
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "client&.to_json=#{client&.to_json}",
                                             "e2.class.name=#{e2.class.name}",
                                             "" ] + e2.backtrace[0..20],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      Rails.logger.error "#{e2.class.name} at #{e2.backtrace[0]}"
      return nil
    rescue Exception => e3
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "e3.class.name=#{e3.class.name}",
                                             "e3.message=#{e3.message}",
                                             "" ] + e3.backtrace[0..20],
                                           bold_puts: is_verbose if is_verbose || jira_helper_debug_verbose
      Rails.logger.error "#{e3.class} #{e3.message} at #{e3.backtrace[0]}"
      return nil
    end

    def self.jira_ticket_curation_notes_admin_contains( curation_concern:, search_value: )
      return false unless curation_concern.respond_to? :curation_notes_admin
      note_str = curation_concern.curation_notes_admin.join(" ")
      if search_value.is_a? String
        return note_str.include? search_value
      elsif search_value.is_a? Regexp
        rv = note_str =~ search_value
        return !rv.nil?
      end
      return false
    end

    def self.jira_ticket_for_create( client: nil,
                                     curation_concern:,
                                     check_admin_notes_for_existing_jira_ticket: true,
                                     is_verbose: false,
                                     msg_queue: nil )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "check_admin_notes_for_existing_jira_ticket=#{check_admin_notes_for_existing_jira_ticket}",
                                             "is_verbose=#{is_verbose}",
                                             "msg_queue=#{msg_queue}",
                                             "" ] if jira_helper_debug_verbose

      curation_admin_note_jira_ticket_prefix = "Jira ticket: "
      if check_admin_notes_for_existing_jira_ticket
        if jira_ticket_curation_notes_admin_contains( curation_concern: curation_concern,
                                                        search_value: curation_admin_note_jira_ticket_prefix )
          msg_queue << "curation concern admin notes already contains jira ticket" unless msg_queue.nil?
          return
        end
      end

      # Issue type: Data deposit
      # * issue type field name: "issuetype"
      # Status: New
      # * status field name: "customfield_12000"
      # Summary: [Depositor last name] _ [First two words of deposit] _ [deposit ID] - e.g., Nasser_BootAcceleration_n583xv03w
      # * summary field name: "summary"
      # Requester/contact: "Creator", "Contact information" fields in DBD - e.g., Meurer, William wmeurer@med.umich.edu
      # * creator field name: "customfield_11304"
      # * contact information field name: "customfield_11315"
      # Unique Identifier: Deposit ID (from deposit URL) - e.g., n583xv03w
      # * unique identifier field name: "customfield_11303"
      # URL in Deep Blue Data: Deposit URL - e.g., https://deepblue.lib.umich.edu/data/concern/data_sets/4x51hj04n
      # * deposit url field name: "customfield_11305"
      # Description: "Title of deposit" - e.g., Effect of financial incentives on head CT use dataset"
      # * description field name: "description"
      # Discipline: "Discipline" field in DBD - e.g., Health sciences
      # * discipline field name: "customfield_11309"
      # customer request type: "customfield_10001" => "requestType"

      # contact_info = curation_concern.authoremail
      creator = Array( curation_concern.creator ).first
      deposit_id = curation_concern.id
      deposit_url = ::Deepblue::EmailHelper.curation_concern_url( curation_concern: curation_concern )
      discipline = Array( curation_concern.subject_discipline ).first
      description = Array( curation_concern.title ).join("\n") + "\n\nby #{creator}"
      client = jira_client( client: client )
      if jira_use_authoremail_as_requester
        user = curation_concern.authoremail
      else
        user = curation_concern.depositor
      end
      # TODO: make delay_after_create_user a config parameter
      requester = jira_requester( user: user, client: client, is_verbose: is_verbose, delay_after_create_user: 60 )
      requester_email = curation_concern.depositor
      summary = jira_build_summary_for( curation_concern: curation_concern )

      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             ::Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "summary=#{summary}",
                                             "requester=#{requester}",
                                             "requester_email=#{requester_email}",
                                             "description=#{description}",
                                             "" ] if jira_helper_debug_verbose
      jira_url = JiraHelper.jira_new_ticket( client: client,
                                             deposit_id: deposit_id,
                                             deposit_url: deposit_url,
                                             description: description,
                                             discipline: discipline,
                                             requester: requester,
                                             requester_email: requester_email,
                                             summary: summary )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "jira_url=#{jira_url}",
                                             "" ] if jira_helper_debug_verbose

      if jira_url.nil?
        msg_queue << "jira_url is nil - failed to create jira ticket" unless msg_queue.nil?
        return
      end
      unless curation_concern.respond_to? :add_curation_note_admin
        msg_queue << "curation concern #{curation_concern.id} does not respond to :add_curation_note_admin" unless msg_queue.nil?
      else
        curation_concern.add_curation_note_admin( note: "#{curation_admin_note_jira_ticket_prefix}#{jira_url}" )
      end
    end

    def self.jira_user_as_hash( user:, client: nil, is_verbose: false )
      return {} unless jira_enabled
      client = jira_client( client: client )
      path = "#{client.options[:rest_base_path]}/user/search?username=#{user}&includeInactive=true"
      response = client.get(path)
      jira_debug_verbose_for_client_response( client: client, response: response, is_verbose: is_verbose )
      get_rv = response
      body = get_rv.body
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "jira_user_as_hash( user: #{user} )",
                                              "path=#{path}",
                                              "get_rv=#{get_rv}",
                                              "body=#{body}",
                                              "" ] ) if is_verbose || jira_helper_debug_verbose
      rv = if body.blank?
             {}
           else
             arr = JSON.parse body
             arr.first
           end
      ::Deepblue::LoggingHelper.bold_debug( [ ::Deepblue::LoggingHelper.here,
                                              ::Deepblue::LoggingHelper.called_from,
                                              "rv=#{rv}",
                                              "" ] ) if is_verbose || jira_helper_debug_verbose
      return rv
    end

    def self.jira_user_exists?( user:, client: nil, is_verbose: false )
      return true unless jira_enabled
      hash = jira_user_as_hash( user: user, client: client, is_verbose: is_verbose )
      return false unless hash.present?
      hash.size > 0
    end

    def self.summary_last_name( curation_concern: )
      name = Array( curation_concern.creator ).first
      return "" if name.blank?
      match = name.match( /^([^,]+),.*$/ ) # first non-comma substring
      return match[1] if match
      match = name.match( /^.* ([^ ]+)$/ ) # last non-space substring
      return match[1] if match
      return name
    end

    def self.summary_description( curation_concern: )
      description = Array( curation_concern.description ).first
      return "" if description.blank?
      match = description.match( /^([^ ]+) +([^ ]+) [^ ].*$/ ) # three plus words
      return "#{match[1]}#{match[2]}" if match
      match = description.match( /^([^ ]+) +([^ ]+)$/ ) # two words
      return "#{match[1]}#{match[2]}" if match
      match = description.match( /^[^ ]+$/ ) # one word
      return description if match
      return description
    end

    def self.summary_title( curation_concern: )
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

    def self.ticket_url( client:, issue: )
      client = jira_client( client: client )
      issue_key = issue.key if issue.respond_to? :key
      "#{client.options[:site]}#{client.options[:context_path]}/browse/#{issue_key}"
    end

  end

end
