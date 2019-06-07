# frozen_string_literal: true

module Deepblue

  require 'jira-ruby'

  module JiraHelper
    extend ActionView::Helpers::TranslationHelper

    def self.jira_enabled
      DeepBlueDocs::Application.config.jira_integration_enabled
    end

    def self.jira_manager_issue_type
      DeepBlueDocs::Application.config.jira_manager_issue_type
    end

    def self.jira_manager_project_key
      DeepBlueDocs::Application.config.jira_manager_project_key
    end

    def self.jira_test_mode
      DeepBlueDocs::Application.config.jira_test_mode
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
                                             "" ]

      # Issue type: Data deposit
      #
      # Status: New
      #
      # Summary: [Depositor last name] _ [First two words of deposit] _ [deposit ID] - e.g., Nasser_BootAcceleration_n583xv03w
      #
      # Requester/contact: "Creator", "Contact information" fields in DBD - e.g., Meurer, William wmeurer@med.umich.edu
      #
      # Unique Identifier: Deposit ID (from deposit URL) - e.g., n583xv03w
      #
      # URL in Deep Blue Data: Deposit URL - e.g., https://deepblue.lib.umich.edu/data/concern/data_sets/4x51hj04n
      #
      # Description: "Title of deposit" - e.g., Effect of financial incentives on head CT use dataset"
      #
      # Discipline: "Discipline" field in DBD - e.g., Health sciences
      #
      summary_title = summary_title( curation_concern: curation_concern )
      summary_last_name = summary_last_name( curation_concern: curation_concern )
      summary = "#{summary_last_name}_#{summary_title}_#{curation_concern.id}"
      url = ::Deepblue::EmailHelper.data_set_url( data_set: curation_concern )
      description = "Requester/contact: #{Array( curation_concern.creator ).first}, #{curation_concern.authoremail}\n\n" +
                    "Unique Identifier: #{curation_concern.id}\n\n" +
                    "URL in Deep Blue Data: #{url}\n\n" +
                    "#{Array( curation_concern.title ).first}\n\n" +
                    "Discipline: #{Array( curation_concern.subject_discipline ).first}"
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "summary=#{summary}",
                                             "description=#{description}",
                                             "" ]
      jira_url = JiraHelper.new_ticket( summary: summary, description: description )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "jira_url=#{jira_url}",
                                             "" ]

      return if jira_url.nil?
      return unless curation_concern.respond_to? :curation_notes_admin
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "curation_concern.curation_notes_admin=#{curation_concern.curation_notes_admin}",
                                             "" ]
      curation_concern.date_modified = DateTime.now # touch it so it will save updated attributes
      notes = curation_concern.curation_notes_admin
      notes = [] if notes.nil?
      curation_concern.curation_notes_admin = notes << "Jira ticket: #{jira_url}"
      curation_concern.save!
    end

    def self.new_ticket( summary:,
                         project_key: jira_manager_project_key,
                         issue_type: jira_manager_issue_type,
                         description: )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "summary=#{summary}",
                                             "project_key=#{project_key}",
                                             "issue_type=#{issue_type}",
                                             "description=#{description}",
                                             "jira_enabled=#{jira_enabled}",
                                             "" ]
      return nil unless jira_enabled
      client_options = {
          :username     => Settings.jira.username,
          :password     => Settings.jira.password,
          :site         => Settings.jira.site_url,
          # :site         => 'https://tools.lib.umich.edu',
          :context_path => '/jira',
          :auth_type    => :basic
      }
      save_options = {
          "fields" => {
              "summary"     => summary,
              "project"     => { "key" => project_key },
              "issuetype"   => { "name" => issue_type },
              "description" => description,
          }
      }
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "client_options=#{client_options}",
                                             "save_options=#{save_options}",
                                             "" ]

      return "https://test.jira.url/#{project_key}" if jira_test_mode
      # return nil if jira_test_mode

      client = JIRA::Client.new( client_options )
      issue = client.Issue.build
      issue.save( save_options )
      # print "Issue GUI URL: "
      # puts "#{client.options[:site]}#{client.options[:context_path]}/browse/#{issue.key}"
      # print "Issue API URL: "
      # puts issue.self
      url = ticket_url( client: client, issue: issue )
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             "url=#{url}",
                                             "" ]
      return url
    end

    def self.ticket_url( client:, issue: )
      "#{client.options[:site]}#{client.options[:context_path]}/browse/#{issue.key}"
    end

  end

end
