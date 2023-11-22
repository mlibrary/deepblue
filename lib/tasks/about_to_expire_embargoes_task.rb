# frozen_string_literal: true

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_task'
  require_relative '../../app/helpers/hyrax/embargo_helper'
  require_relative '../../app/services/deepblue/about_to_expire_embargoes_service'

  class AboutToExpireEmbargoesTask < AbstractTask
    include ::Hyrax::EmbargoHelper

    def initialize( options: {} )
      super( options: options )
    end

    def run
      email_owner = task_options_value( key: 'email_owner', default_value: true )
      msg_handler.msg_verbose "email_owner=#{email_owner}"
      expiration_lead_days = task_options_value( key: 'expiration_lead_days' )
      msg_handler.msg_verbose "expiration_lead_days=#{expiration_lead_days}"
      skip_file_sets = task_options_value( key: 'skip_file_sets', default_value: true )
      msg_handler.msg_verbose "@skip_file_sets=#{skip_file_sets}"
      test_mode = task_options_value( key: 'test_mode', default_value: false )
      msg_handler.msg_verbose "test_mode=#{test_mode}"
      service = AboutToExpireEmbargoesService.new( email_owner: email_owner,
                                         expiration_lead_days: expiration_lead_days,
                                         skip_file_sets: skip_file_sets,
                                         test_mode: test_mode,
                                         # to_console: true,
                                         # verbose: verbose,
                                         msg_handler: msg_handler )
      service.run
    end

  end

end
