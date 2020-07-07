# frozen_string_literal: true

module Deepblue

  require 'jira-ruby'

  module JiraHelper
    extend ActionView::Helpers::TranslationHelper

    FIELD_NAME_CONTACT_INFO = "customfield_11315".freeze
    FIELD_NAME_CREATOR = "customfield_11304".freeze
    FIELD_NAME_DEPOSIT_ID = "customfield_11303".freeze
    FIELD_NAME_DEPOSIT_URL = "customfield_11305".freeze
    FIELD_NAME_DESCRIPTION = "description".freeze
    FIELD_NAME_DISCIPLINE = "customfield_11309".freeze
    FIELD_NAME_REPORTER = "reporter".freeze
    FIELD_NAME_STATUS = "customfield_12000".freeze
    FIELD_NAME_SUMMARY = "summary".freeze

    @@_setup_ran = false

    @@jira_allow_create_users
    @@jira_field_values_discipline_map
    @@jira_helper_debug_verbose
    @@jira_integration_hostnames
    @@jira_integration_hostnames_prod
    @@jira_integration_enabled
    @@jira_manager_project_key
    @@jira_manager_issue_type
    @@jira_rest_url
    @@jira_rest_api_url
    @@jira_rest_create_users_url
    @@jira_test_mode
    @@jira_url

    mattr_accessor  :jira_allow_create_users,
                    :jira_field_values_discipline_map,
                    :jira_helper_debug_verbose,
                    :jira_integration_hostnames,
                    :jira_integration_hostnames_prod,
                    :jira_integration_enabled,
                    :jira_manager_project_key,
                    :jira_manager_issue_type,
                    :jira_rest_url,
                    :jira_rest_api_url,
                    :jira_rest_create_users_url,
                    :jira_test_mode,
                    :jira_url

    def self.setup
      yield self if @@_setup_ran == false
      @@_setup_ran = true
    end

    def self.jira_enabled
      JiraHelper.jira_integration_enabled
    end

    def self.jira_client( client: nil )
      return nil unless jira_enabled
      return nil if jira_test_mode
      return client unless client.nil?
      # TODO: catch errors
      client = JIRA::Client.new( jira_client_options )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "client.to_json=#{client.to_json}",
                                              "" ] ) if jira_helper_debug_verbose
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

    def self.jira_create_user( email:, client: nil )
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
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "user_options=#{user_options}",
                                              "path=#{path}",
                                              "" ] ) if jira_helper_debug_verbose
      post_rv = client.post( path, user_options.to_json )
      rv = post_rv.body.blank?
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "post_rv=#{post_rv}",
                                              "rv=#{rv}",
                                              "" ] ) if jira_helper_debug_verbose
      return rv
    end

    def self.jira_user_exists?( user:, client: nil )
      return true unless jira_enabled
      hash = jira_user_as_hash( user: user, client: client )
      return false unless hash.present?
      hash.size > 0
    end

    def self.jira_user_as_hash( user:, client: nil )
      return {} unless jira_enabled
      client = jira_client( client: client )
      path = "#{client.options[:rest_base_path]}/user/search?username=#{user}"
      get_rv = client.get(path)
      body = get_rv.body
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "jira_user_as_hash( user: #{user} )",
                                              "path=#{path}",
                                              "get_rv=#{get_rv}",
                                              "body=#{body}",
                                              "" ] ) if jira_helper_debug_verbose
      rv = if body.blank?
             {}
           else
             arr = JSON.parse body
             arr.first
           end
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "rv=#{rv}",
                                              "" ] ) if jira_helper_debug_verbose
      return rv
    end

    def self.reporter( user: nil, client: nil )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "reporter( user: #{user} )",
                                              "" ] ) if jira_helper_debug_verbose
      return { name: user } unless jira_enabled
      return { name: user } if jira_test_mode
      return {} if user.nil?
      client = jira_client( client: client )
      hash = jira_user_as_hash( user: user, client: client )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "hash=#{hash}",
                                              "" ] ) if jira_helper_debug_verbose
      return hash if hash.present?
      jira_create_user( email: user, client: client )
      jira_user_as_hash( user: user, client: client )
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

    def self.jira_ticket_for_create( curation_concern: )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "curation_concern.id=#{curation_concern.id}",
                                             "" ] if jira_helper_debug_verbose

      # Issue type: Data deposit
      #
      # * issue type field name: "issuetype"
      #
      # Status: New
      #
      # * status field name: "customfield_12000"
      #
      # Summary: [Depositor last name] _ [First two words of deposit] _ [deposit ID] - e.g., Nasser_BootAcceleration_n583xv03w
      #
      # * summary field name: "summary"
      #
      # Requester/contact: "Creator", "Contact information" fields in DBD - e.g., Meurer, William wmeurer@med.umich.edu
      #
      # * creator field name: "customfield_11304"
      # * contact information field name: "customfield_11315"
      #
      # Unique Identifier: Deposit ID (from deposit URL) - e.g., n583xv03w
      #
      # * unique identifier field name: "customfield_11303"
      #
      # URL in Deep Blue Data: Deposit URL - e.g., https://deepblue.lib.umich.edu/data/concern/data_sets/4x51hj04n
      #
      # * deposit url field name: "customfield_11305"
      #
      # Description: "Title of deposit" - e.g., Effect of financial incentives on head CT use dataset"
      #
      # * description field name: "description"
      #
      # Discipline: "Discipline" field in DBD - e.g., Health sciences
      #
      # * discipline field name: "customfield_11309"
      #
      # customer request type: "customfield_10001" => "requestType"
      #
      summary_title = summary_title( curation_concern: curation_concern )
      summary_last_name = summary_last_name( curation_concern: curation_concern )
      summary = "#{summary_last_name}_#{summary_title}_#{curation_concern.id}"

      contact_info = curation_concern.authoremail
      creator = Array( curation_concern.creator ).first
      deposit_id = curation_concern.id
      deposit_url = ::Deepblue::EmailHelper.curation_concern_url( curation_concern: curation_concern )
      discipline = Array( curation_concern.subject_discipline ).first
      description = Array( curation_concern.title ).join("\n") + "\n\nby #{creator}"
      client = jira_client( client: client )
      reporter = reporter( user: curation_concern.depositor, client: client )

      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "summary=#{summary}",
                                             "reporter=#{reporter}",
                                             "description=#{description}",
                                             "" ] if jira_helper_debug_verbose
      jira_url = JiraHelper.new_ticket( client: client,
                                        contact_info: contact_info,
                                        deposit_id: deposit_id,
                                        deposit_url: deposit_url,
                                        description: description,
                                        discipline: discipline,
                                        reporter: reporter,
                                        summary: summary )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "jira_url=#{jira_url}",
                                             "" ] if jira_helper_debug_verbose

      return if jira_url.nil?
      return unless curation_concern.respond_to? :curation_notes_admin
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "curation_concern.curation_notes_admin=#{curation_concern.curation_notes_admin}",
                                             "" ] if jira_helper_debug_verbose
      curation_concern.date_modified = DateTime.now # touch it so it will save updated attributes
      notes = curation_concern.curation_notes_admin
      notes = [] if notes.nil?
      curation_concern.curation_notes_admin = notes << "Jira ticket: #{jira_url}"
      curation_concern.save!
    end

    def self.build_customer_request_type( client:, issue: )
      issue_id = issue.id if issue.respond_to? :id
      issue_key = issue.key if issue.respond_to? :key
      jira_url = "#{client.options[:site]}#{client.options[:context_path]}/"
      rv = {}
      rv["customfield_10001"] =
          {
            "_links": {
              "jiraRest": "#{jira_url}rest/api/2/issue/#{issue_id}",
              "web": "#{jira_url}servicedesk/customer/portal/19/#{issue_key}",
              "self": "#{jira_url}rest/servicedeskapi/request/#{issue_id}"
            },
            "requestType" => {
              "id" => "174",
              "_links" => {
                "self" => "#{jira_url}rest/servicedeskapi/servicedesk/19/requesttype/174"
              },
              "name" => "Data Deposit",
              "description" => "",
              "helpText" => "",
              "serviceDeskId" => "19",
              "groupIds" => [ "37" ],
              "icon" => {
                "id" => "10522",
                "_links" => {
                  "iconUrls" => {
                    "48x48" => "#{jira_url}secure/viewavatar?avatarType=SD_REQTYPE&size=large&avatarId=10522",
                    "24x24" => "#{jira_url}secure/viewavatar?avatarType=SD_REQTYPE&size=small&avatarId=10522",
                    "16x16" => "#{jira_url}secure/viewavatar?avatarType=SD_REQTYPE&size=xsmall&avatarId=10522",
                    "32x32" => "#{jira_url}secure/viewavatar?avatarType=SD_REQTYPE&size=medium&avatarId=10522"
                  }
                }
              }
            },
            "currentStatus" => nil
          }
      return rv
    end

    def self.new_ticket( client: nil,
                         project_key: jira_manager_project_key,
                         issue_type: jira_manager_issue_type,
                         contact_info:,
                         deposit_id:,
                         deposit_url:,
                         description:,
                         discipline:,
                         reporter:,
                         summary: )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "summary=#{summary}",
                                             "project_key=#{project_key}",
                                             "issue_type=#{issue_type}",
                                             "description=#{description}",
                                             "reporter=#{reporter}",
                                             "jira_enabled=#{jira_enabled}",
                                             "" ] if jira_helper_debug_verbose
      return nil unless jira_enabled
      save_options = {
          "fields" => {
              "project"     => { "key" => project_key },
              "issuetype"   => { "name" => issue_type },
              FIELD_NAME_CONTACT_INFO => contact_info,
              FIELD_NAME_DEPOSIT_ID => deposit_id,
              FIELD_NAME_DEPOSIT_URL => deposit_url,
              FIELD_NAME_DESCRIPTION => description,
              FIELD_NAME_DISCIPLINE => discipline,
              FIELD_NAME_SUMMARY => summary }
      }
      if reporter.present?
        save_options["fields"].merge!( { FIELD_NAME_REPORTER => reporter } )
      end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "save_options=#{save_options}",
                                             "" ] if jira_helper_debug_verbose

      return "https://test.jira.url/#{project_key}" if jira_test_mode
      # return nil if jira_test_mode

      client = jira_client( client: client )
      # issue = client.Issue.build
      # rv = issue.save( save_options )
      build_options = {
          "fields" => {
              FIELD_NAME_SUMMARY => summary,
              "project"     => { "key" => project_key },
              "issuetype"   => { "name" => issue_type },
              FIELD_NAME_DESCRIPTION => description }
      }
      if reporter.present?
        build_options["fields"].merge!( { FIELD_NAME_REPORTER => reporter } )
      end
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "build_options=#{build_options}",
                                             "" ] if jira_helper_debug_verbose
      issue = client.Issue.build
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             # "client.to_json=#{client.to_json}",
                                             "issue=#{issue}",
                                             "issue&.to_json=#{issue&.to_json}",
                                             "" ] if jira_helper_debug_verbose
      rv = issue.save( build_options )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             # "client.to_json=#{client.to_json}",
                                             "issue.save( #{build_options} ) rv=#{rv}",
                                             "issue.attrs=#{issue.attrs}",
                                             "" ] ) unless rv
      sopts = { "fields" => { FIELD_NAME_CONTACT_INFO => contact_info } }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                             "" ] ) unless rv
      sopts = { "fields" => { FIELD_NAME_DEPOSIT_ID => deposit_id } }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ] ) unless rv
      sopts = { "fields" => { FIELD_NAME_DEPOSIT_URL => deposit_url } }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ] ) unless rv
      sopts = { "fields" => { FIELD_NAME_DISCIPLINE => jira_field_values_discipline_map[discipline] } }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ] ) unless rv
      sopts = { "fields" => build_customer_request_type( client: client, issue: issue ) }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ] ) unless rv
      # if rv is false, the save failed.
      url = ticket_url( client: client, issue: issue )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ] if jira_helper_debug_verbose
      return url
    end

    def self.ticket_url( client:, issue: )
      client = jira_client( client: client )
      issue_key = issue.key if issue.respond_to? :key
      "#{client.options[:site]}#{client.options[:context_path]}/browse/#{issue_key}"
    end

  end

end
