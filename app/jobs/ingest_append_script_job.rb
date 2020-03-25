# frozen_string_literal: true

class IngestAppendScriptJob < ::Hyrax::ApplicationJob
  include JobHelper
  queue_as ::Deepblue::IngestIntegrationService.ingest_append_queue_name

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "" ]
    options = {}
    args.each { |key,value| options[key] = value }
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           "options=#{options}",
                                           Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ]
    # verbose = job_options_value(options, key: 'verbose', default_value: false )
    # ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    # hostnames = job_options_value(options, key: 'hostnames', default_value: [], verbose: verbose )
    # hostname = ::DeepBlueDocs::Application.config.hostname
    # return unless hostnames.include? hostname
    # ::DeepBlueDocs::Application.config.scheduler_heartbeat_email_targets.each do |email_target|
    #   heartbeat_email( email_target: email_target, hostname: hostname )
    # end
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
