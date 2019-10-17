# frozen_string_literal: true

class UserStatImporterJob < ::Hyrax::ApplicationJob
  queue_as :scheduler

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "" ]
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "user stat importer" )
    options = {}
    args.each { |key,value| options[key] = value }
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           "options=#{options}",
                                           Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ]
    verbose = jop_options_value( options, key: 'verbose', default_value: false )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    logging = jop_options_value( options, key: 'logging', default_value: false )
    ::Deepblue::LoggingHelper.debug "logging=#{logging}" if verbose
    hostnames = jop_options_value( options, key: 'hostnames', default_value: [] )
    ::Deepblue::LoggingHelper.debug "hostnames=#{hostnames}" if verbose
    hostname = ::DeepBlueDocs::Application.config.hostname
    return unless hostnames.include? hostname
    test = jop_options_value( options, key: 'test', default_value: true )
    ::Deepblue::LoggingHelper.debug "test=#{test}" if verbose
    return unless test
    importer = Hyrax::UserStatImporter.new( verbose: verbose, logging: logging )
    importer.import
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
