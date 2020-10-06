# frozen_string_literal: true

class AbstractRakeTaskJob < ::Hyrax::ApplicationJob

  ABSTRACT_RAKE_TASK_JOB_DEBUG_VERBOSE = ::Deepblue::JobTaskHelper.abstract_rake_task_job_debug_verbose

  include JobHelper

  attr_accessor :email_results_to,
                :hostname,
                :hostnames,
                :job_delay,
                :options,
                :timestamp_begin,
                :timestamp_end,
                :verbose

  def default_value_is( value, default_value )
    return value if value.present?
    default_value
  end

  def email_results( exec_str:, rv: )
    ::Deepblue::JobTaskHelper.email_results( exec_str: exec_str, rv: rv )
  end

  def initialize_from_args( *args )
    @timestamp_begin = DateTime.now
    @options = {}
    args.each { |key,value| @options[key] = value }
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "timestamp_begin=#{timestamp_begin}",
                                           "options=#{options}",
                                           "" ] if ABSTRACT_RAKE_TASK_JOB_DEBUG_VERBOSE
    @verbose = job_options_value( options,
                                  key: 'verbose',
                                  default_value: default_value_is( verbose, false ) )
    @job_delay = job_options_value( options,
                                  key: 'job_delay',
                                  default_value: default_value_is( job_delay, 0 ),
                                  verbose: verbose )
    ::Deepblue::LoggingHelper.debug "verbose=#{verbose}" if verbose
    @email_results_to = job_options_value( options,
                                           key: 'email_results_to',
                                           default_value: default_value_is( email_results_to, [] ),
                                           verbose: verbose )
    @hostnames = job_options_value( options,
                                    key: 'hostnames',
                                    default_value: default_value_is( hostnames, [] ),
                                    verbose: verbose )
    return true if hostnames.blank?
    @hostname = ::DeepBlueDocs::Application.config.hostname
    hostnames.include? hostname
  end

  def run_job_delay
    return if job_delay.blank?
    return if 0 >= job_delay
    Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                         "sleeping #{job_delay} seconds",
                                         "" ] if verbose || ABSTRACT_RAKE_TASK_JOB_DEBUG_VERBOSE
    sleep job_delay
  end

end
