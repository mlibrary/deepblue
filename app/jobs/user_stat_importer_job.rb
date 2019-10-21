# frozen_string_literal: true

class UserStatImporterJob < ::Hyrax::ApplicationJob
  include JobHelper
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
    verbose = job_options_value(options, key: 'verbose', default_value: false )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    hostnames = job_options_value(options, key: 'hostnames', default_value: [], verbose: verbose )
    hostname = ::DeepBlueDocs::Application.config.hostname
    return unless hostnames.include? hostname
    test = job_options_value(options, key: 'test', default_value: true, verbose: verbose )
    echo_to_stdout = job_options_value(options, key: 'echo_to_stdout', default_value: false, verbose: verbose )
    logging = job_options_value(options, key: 'logging', default_value: false, verbose: verbose )
    number_of_retries = job_options_value(options, key: 'number_of_retries', default_value: nil, verbose: verbose )
    delay_secs = job_options_value(options, key: 'delay_secs', default_value: nil, verbose: verbose )
    importer = Hyrax::UserStatImporter.new( echo_to_stdout: echo_to_stdout,
                                            verbose: verbose,
                                            delay_secs: delay_secs,
                                            logging: logging,
                                            number_of_retries: number_of_retries,
                                            test: test )
    importer.import
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
