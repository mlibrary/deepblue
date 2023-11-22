# frozen_string_literal: true

namespace :deepblue do

  # bundle exec rake deepblue:deactivate_expired_embargoes['{"test_mode":true}']
  # bundle exec rake deepblue:deactivate_expired_embargoes['{"test_mode":true\,"verbose":true}']
  # bundle exec rake deepblue:deactivate_expired_embargoes['{"skip_file_sets":false\,"test_mode":true}']
  desc 'Deactivate expired embargoes.'
  task :deactivate_expired_embargoes, %i[ options ] => :environment do |_task, args|
    args.with_defaults( options: '{}' )
    options = args[:options]
    task = Deepblue::DeactivateExpiredEmbargoesTask.new( options: options )
    task.run
  end

end

module Deepblue

  require_relative '../../app/tasks/deepblue/abstract_task'
  require_relative '../../app/helpers/hyrax/embargo_helper'
  require_relative '../../app/services/deepblue/deactivate_expired_embargoes_service'

  class DeactivateExpiredEmbargoesTask < AbstractTask
    include ::Hyrax::EmbargoHelper

    def initialize( options: {} )
      super( options: options )
    end

    def run
      email_owner = task_options_value( key: 'email_owner', default_value: true )
      msg_handler.msg_verbose "email_owner=#{email_owner}"
      skip_file_sets = task_options_value( key: 'skip_file_sets', default_value: true )
      msg_handler.msg_verbose "@skip_file_sets=#{skip_file_sets}"
      test_mode = task_options_value( key: 'test_mode', default_value: false )
      msg_handler.msg_verbose "test_mode=#{test_mode}"
      DeactivateExpiredEmbargoesService.new( email_owner: email_owner,
                                             skip_file_sets: skip_file_sets,
                                             test_mode: test_mode,
                                             to_console: true,
                                             verbose: @verbose ).run
    end

  end

end
