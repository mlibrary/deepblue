# frozen_string_literal: true

namespace :deepblue do

  require_relative '../../app/helpers/deepblue/jira_helper'

  # bundle exec rake deepblue:submit_test_jira_ticket
  # bundle exec rake deepblue:submit_test_jira_ticket['{"verbose":true\,"reporter_email":"test_dbd_depositor@umich.test"}']
  # bundle exec rake deepblue:submit_test_jira_ticket['{"verbose":true\,"deposit_id":"87654321"\,"deposit_url":"https://testing.deepblue.lib.umich.edu/data/data_sets/87654321"\,"description":"A Test Jira Ticket Description"\,"discipline":"Other"\,"deposit_id":"87654321"\,"reporter":"test_dbd_depositor"\,"reporter_email":"test_dbd_depositor@umich.test"\,"summary":"The test summary, and thus, testing test is it."}']
  desc 'Submit test jira ticket'
  task :submit_test_jira_ticket, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::SubmitTestJiraTicket.new( options: options )
    task.run
  end

end

module Deepblue

  require 'tasks/abstract_task'

  class SubmitTestJiraTicket < AbstractTask

    def initialize( options: {} )
      super( options: options )
      @deposit_id = TaskHelper.task_options_value( @options, key: 'deposit_id', default_value: "87654321" )
      @deposit_url = TaskHelper.task_options_value( @options,
                                                    key: 'deposit_url',
                                                    default_value: "https://testing.deepblue.lib.umich.edu/data/data_sets/87654321" )
      @description = TaskHelper.task_options_value( @options,
                                                    key: 'description',
                                                    default_value: "A Test Jira Ticket Description" )
      @discipline = TaskHelper.task_options_value( @options, key: 'discipline', default_value: "Other" )
      @reporter = TaskHelper.task_options_value( @options, key: 'reporter', default_value: "test_dbd_depositor" )
      @reporter_email = TaskHelper.task_options_value( @options,
                                                       key: 'reporter_email',
                                                       default_value: "test_dbd_depositor@umich.test" )
      @summary = TaskHelper.task_options_value( @options,
                                                key: 'summary',
                                                default_value: "The test summary, and thus, testing test is it." )
    end

    def run
      submit_test_jira_ticket
    end

    protected

      def submit_test_jira_ticket
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "@deposit_id=#{@deposit_id}",
                                               "@deposit_url=#{@deposit_url}",
                                               "@description=#{@description}",
                                               "@discipline=#{@discipline}",
                                               "@reporter=#{@reporter}",
                                               "@reporter_email=#{@reporter_email}",
                                               "@summary=#{@summary}",
                                               "" ], bold_puts: @verbose
        client = JiraHelper.jira_client( jira_is_enabled: true, bold_puts: @verbose )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "client&.to_json=#{client&.to_json}",
                                               "" ], bold_puts: @verbose
        description = "#{@description}\nAt: #{DateTime.now}"
        url = JiraHelper.jira_new_ticket( client: client,
                                    deposit_id: @deposit_id,
                                    deposit_url: @deposit_url,
                                    description: description,
                                    discipline: @discipline,
                                    reporter: @reporter,
                                    reporter_email: @reporter_email,
                                    summary: @summary,
                                    bold_puts: @verbose )
        if url.present?
          puts "Jira ticket url:"
          puts url
        else
          puts "Failed to generate jira ticket."
        end
      end

  end

end
