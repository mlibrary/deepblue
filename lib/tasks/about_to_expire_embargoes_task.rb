# frozen_string_literal: true

module Deepblue

  require 'tasks/abstract_task'
  require_relative '../../app/helpers/hyrax/embargo_helper'
  require_relative '../../app/services/deepblue/about_to_expire_embargoes_service'

  class AboutToExpireEmbargoesTask < AbstractTask
    include ::Hyrax::EmbargoHelper

    def initialize( options: {} )
      super( options: options )
    end

    def run
      email_owner = task_options_value( key: 'email_owner', default_value: true )
      task_msg "email_owner=#{email_owner}" if @verbose
      expiration_lead_days = task_options_value( key: 'expiration_lead_days' )
      task_msg "expiration_lead_days=#{expiration_lead_days}" if @verbose
      skip_file_sets = task_options_value( key: 'skip_file_sets', default_value: true )
      task_msg "@skip_file_sets=#{skip_file_sets}" if @verbose
      test_mode = task_options_value( key: 'test_mode', default_value: false )
      task_msg "test_mode=#{test_mode}" if @verbose
      AboutToExpireEmbargoesService.new( email_owner: email_owner,
                                         expiration_lead_days: expiration_lead_days,
                                         skip_file_sets: skip_file_sets,
                                         test_mode: test_mode,
                                         to_console: true,
                                         verbose: @verbose ).run
    end

  end

end
