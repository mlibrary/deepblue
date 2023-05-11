# frozen_string_literal: true

# bundle exec rake deepblue:run_job['{"job_class":"HeartBeat"\,"verbose":true}']
class ListArgumentsJob < ::Deepblue::DeepblueJob

  mattr_accessor :list_arguments_job_debug_verbose, default: false

  def perform( *args )
    job_start( email_init: false )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args.pretty_inspect}",
                                           "" ], bold_puts: true if list_arguments_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "methods:" ] + methods.sort, bold_puts: true if list_arguments_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "arguments=#{arguments.pretty_inspect}",
                                           "" ], bold_puts: true if list_arguments_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "as_json=#{as_json.pretty_inspect}",
                                           "" ], bold_puts: true if list_arguments_job_debug_verbose
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    raise e
  end

end
