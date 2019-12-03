# frozen_string_literal: true

require_relative '../services/deepblue/works_reporter'

class WorksReportJob < ::Hyrax::ApplicationJob
  include JobHelper
  queue_as :scheduler

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "" ]
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: "works report job" )
    options = {}
    args.each { |key,value| options[key] = value }
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           "options=#{options}",
                                           Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ]
    quiet = job_options_value( options, key: 'quiet', default_value: false, verbose: true )
    if quiet
      verbose = false
    else
      verbose = job_options_value( options, key: 'verbose', default_value: false )
      ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    end
    hostnames = job_options_value( options, key: 'hostnames', default_value: [], verbose: verbose )
    hostname = ::DeepBlueDocs::Application.config.hostname
    return unless hostnames.include? hostname
    test = job_options_value( options, key: 'test', default_value: true, verbose: verbose )
    if quiet
      echo_to_stdout = false
      options['to_console'] = false
    else
      echo_to_stdout = job_options_value( options, key: 'echo_to_stdout', default_value: false, verbose: verbose )
      logging = job_options_value( options, key: 'logging', default_value: false, verbose: verbose )
      to_console = job_options_value( options, key: 'to_console', verbose: verbose )
      options['to_console'] = echo_to_stdout if echo_to_stdout.present? && to_console.blank?
    end
    reporter = Deepblue::WorksReporter.new( options: options )
    reporter.run
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end
