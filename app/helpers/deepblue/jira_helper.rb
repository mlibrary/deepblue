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

    def self.new_ticket( summary:,
                         project_key: jira_manager_project_key,
                         issue_type: jira_manager_issue_type,
                         description: )
      return nil unless jira_enabled
      ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                             Deepblue::LoggingHelper.called_from,
                                             Deepblue::LoggingHelper.obj_class( 'class', self ),
                                             "summary=#{summary}",
                                             "project_key=#{project_key}",
                                             "issue_type=#{issue_type}",
                                             "description=#{description}",
                                             "" ]
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

      return nil if jira_test_mode

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
