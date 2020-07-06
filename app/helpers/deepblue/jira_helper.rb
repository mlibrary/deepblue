# frozen_string_literal: true

module Deepblue

  require 'jira-ruby'

  module JiraHelper
    extend ActionView::Helpers::TranslationHelper

    JIRA_HELPER_DEBUG_VERBOSE = true

    FIELD_NAME_CONTACT_INFO = "customfield_11315".freeze
    FIELD_NAME_CREATOR = "customfield_11304".freeze
    FIELD_NAME_DEPOSIT_ID = "customfield_11303".freeze
    FIELD_NAME_DEPOSIT_URL = "customfield_11305".freeze
    FIELD_NAME_DESCRIPTION = "description".freeze
    FIELD_NAME_DISCIPLINE = "customfield_11309".freeze
    FIELD_NAME_REPORTER = "reporter".freeze
    FIELD_NAME_STATUS = "customfield_12000".freeze
    FIELD_NAME_SUMMARY = "summary".freeze

    FIELD_VALUES_DISCIPLINE_MAP = {
        "Arts" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/11303",
            "value" => "Arts",
            "id" => "11303"
        }],
        "Business" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/10820",
            "value" => "Business",
            "id" => "10820"
        }],
        "Engineering" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/10821",
            "value" => "Engineering",
            "id" => "10821"
        }],
        "General Information Sources" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/11304",
            "value" => "General Information Sources",
            "id" => "11304"
        }],
        "Government, Politics, and Law" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/11305",
            "value" => "Government, Politics, and Law",
            "id" => "11305"
        }],
        "Health Sciences" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/10822",
            "value" => "Health Sciences",
            "id" => "10822"
        }],
        "Humanities" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/11306",
            "value" => "Humanities",
            "id" => "11306"
        }],
        "International Studies" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/11307",
            "value" => "International Studies",
            "id" => "11307"
        }],
        "News and Current Events" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/11308",
            "value" => "News and Current Events",
            "id" => "11308"
        }],
        "Science" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/10824",
            "value" => "Science",
            "id" => "10824"
        }],
        "Social Sciences" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/10825",
            "value" => "Social Sciences",
            "id" => "10825"
        }],
        "Other" =>
        [{
            # "self" => "https://tools.lib.umich.edu/jira/rest/api/2/customFieldOption/10823",
            "value" => "Other",
            "id" => "10823"
        }]
    }.freeze

    CUSTOM_REQUEST_TYPE_DATA_DEPOSIT = {
        "customfield_10001" => {
          "requestType" => {
            "id" => "174",
            "_links" => {
                "self" => "https://tools.lib.umich.edu/jira/rest/servicedeskapi/servicedesk/19/requesttype/174"
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
                    "48x48" => "https://tools.lib.umich.edu/jira/secure/viewavatar?avatarType=SD_REQTYPE&size=large&avatarId=10522",
                    "24x24" => "https://tools.lib.umich.edu/jira/secure/viewavatar?avatarType=SD_REQTYPE&size=small&avatarId=10522",
                    "16x16" => "https://tools.lib.umich.edu/jira/secure/viewavatar?avatarType=SD_REQTYPE&size=xsmall&avatarId=10522",
                    "32x32" => "https://tools.lib.umich.edu/jira/secure/viewavatar?avatarType=SD_REQTYPE&size=medium&avatarId=10522"
                  }
                }
              }
            },
          }
        }.freeze

    @@_setup_ran = false

    @@jira_integration_hostnames
    @@jira_integration_hostnames_prod
    @@jira_integration_enabled
    @@jira_test_mode
    @@jira_allow_create_users
    @@jira_manager_project_key
    @@jira_manager_issue_type

    mattr_accessor  :jira_integration_hostnames,
                    :jira_integration_hostnames_prod,
                    :jira_integration_enabled,
                    :jira_test_mode,
                    :jira_allow_create_users,
                    :jira_manager_project_key,
                    :jira_manager_issue_type

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
                                              "" ] ) if JIRA_HELPER_DEBUG_VERBOSE
      return client
    end

    def self.jira_client_options
      return {
          :username     => Settings.jira.username,
          :password     => Settings.jira.password,
          :site         => Settings.jira.site_url,
          # :site         => 'https://tools.lib.umich.edu',
          :context_path => '/jira',
          :auth_type    => :basic
      }
    end

    def self.jira_comment_add
      # https://tools.lib.umich.edu/jira/plugins/servlet/restbrowser#/resource/api-2-issue-issueidorkey-comment/POST
      # https://tools.lib.umich.edu/jira/rest/api/2/issue/{issueIdOrKey}/comment
      # post
      # {
      #   "body": "the body of the comment",
      #   "visibility": {
      #     "type": "role",
      #     "value": "Users"
      #   }
      # }
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
      path = 'https://tools.lib.umich.edu/jira/rest/mlibrary/1.0/users'
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "user_options=#{user_options}",
                                              "path=#{path}",
                                              "" ] ) if JIRA_HELPER_DEBUG_VERBOSE
      post_rv = client.post( path, user_options.to_json )
      rv = post_rv.body.blank?
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "post_rv=#{post_rv}",
                                              "rv=#{rv}",
                                              "" ] ) if JIRA_HELPER_DEBUG_VERBOSE
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
                                              "" ] ) if JIRA_HELPER_DEBUG_VERBOSE
      rv = if body.blank?
             {}
           else
             arr = JSON.parse body
             arr.first
           end
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "rv=#{rv}",
                                              "" ] ) if JIRA_HELPER_DEBUG_VERBOSE
      return rv
    end

    def self.reporter( user: nil, client: nil )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "reporter( user: #{user} )",
                                              "" ] ) if JIRA_HELPER_DEBUG_VERBOSE
      return { name: user } unless jira_enabled
      return { name: user } if jira_test_mode
      return {} if user.nil?
      client = jira_client( client: client )
      hash = jira_user_as_hash( user: user, client: client )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "hash=#{hash}",
                                              "" ] ) if JIRA_HELPER_DEBUG_VERBOSE
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
                                             "" ] if JIRA_HELPER_DEBUG_VERBOSE

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
      # # # TODO: new field
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
                                             "" ] if JIRA_HELPER_DEBUG_VERBOSE
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
                                             "" ] if JIRA_HELPER_DEBUG_VERBOSE

      return if jira_url.nil?
      return unless curation_concern.respond_to? :curation_notes_admin
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "curation_concern.curation_notes_admin=#{curation_concern.curation_notes_admin}",
                                             "" ] if JIRA_HELPER_DEBUG_VERBOSE
      curation_concern.date_modified = DateTime.now # touch it so it will save updated attributes
      notes = curation_concern.curation_notes_admin
      notes = [] if notes.nil?
      curation_concern.curation_notes_admin = notes << "Jira ticket: #{jira_url}"
      curation_concern.save!
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
                                             "" ] if JIRA_HELPER_DEBUG_VERBOSE
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
                                             "" ] if JIRA_HELPER_DEBUG_VERBOSE

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
                                             "" ] if JIRA_HELPER_DEBUG_VERBOSE
      issue = client.Issue.build
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             # "client.to_json=#{client.to_json}",
                                             "issue=#{issue}",
                                             "issue&.to_json=#{issue&.to_json}",
                                             "" ] if JIRA_HELPER_DEBUG_VERBOSE
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
      sopts = { "fields" => CUSTOM_REQUEST_TYPE_DATA_DEPOSIT }
      rv = issue.save( sopts )
      ::Deepblue::LoggingHelper.bold_debug( [ Deepblue::LoggingHelper.here,
                                              Deepblue::LoggingHelper.called_from,
                                              "issue.save( #{sopts} ) rv=#{rv}",
                                              "issue.attrs=#{issue.attrs}",
                                              "" ] ) unless rv
      sopts = { "fields" => { FIELD_NAME_DISCIPLINE => FIELD_VALUES_DISCIPLINE_MAP[discipline] } }
      # if rv is false, the save failed.
      url = ticket_url( client: client, issue: issue )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ] if JIRA_HELPER_DEBUG_VERBOSE
      return url
    end

    def self.ticket_url( client:, issue: )
      issue_key = issue.key if issue.respond_to? :key
      "#{client.options[:site]}#{client.options[:context_path]}/browse/#{issue_key}"
    end

  end

end
