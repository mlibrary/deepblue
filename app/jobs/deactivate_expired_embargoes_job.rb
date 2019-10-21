# frozen_string_literal: true

require_relative '../services/deepblue/deactivate_expired_embargoes_service'

class DeactivateExpiredEmbargoesJob < ::Hyrax::ApplicationJob
  include JobHelper
  queue_as :scheduler

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "args=#{args}",
                                           Deepblue::LoggingHelper.obj_class( 'args', args ),
                                           "" ]
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name,  event: "deactivate_expired_embargoes" )
    options = {}
    args.each { |key,value| options[key] = value }
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           "options=#{options}",
                                           Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ]
    verbose = job_options_value(options, key: 'verbose', default_value: false )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    email_owner = job_options_value(options, key: 'email_owner', default_value: true )
    ::Deepblue::LoggingHelper.debug "email_owner=#{email_owner}" if verbose
    skip_file_sets = job_options_value(options, key: 'skip_file_sets', default_value: true )
    ::Deepblue::LoggingHelper.debug "@skip_file_sets=#{skip_file_sets}" if verbose
    test_mode = job_options_value(options, key: 'test_mode', default_value: false )
    ::Deepblue::LoggingHelper.debug "test_mode=#{test_mode}" if verbose
    ::Deepblue::DeactivateExpiredEmbargoesService.new( email_owner: email_owner,
                                                       skip_file_sets: skip_file_sets,
                                                       test_mode: test_mode,
                                                       verbose: verbose ).run
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
