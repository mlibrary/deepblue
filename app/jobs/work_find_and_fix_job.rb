# frozen_string_literal: true

class WorkFindAndFixJob < ::Deepblue::DeepblueJob

  mattr_accessor :work_find_and_fix_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.work_find_and_fix_job_debug_verbose

  queue_as :default

  EVENT = "work find and fix"

  def perform( id, *args )
    debug_verbose = work_find_and_fix_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "args=#{args}",
                                           "" ] if debug_verbose
    initialize_options_from( *args, debug_verbose: debug_verbose )
    log( event: EVENT, hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    job_status.main_cc_id = id
    msg_handler = ::Deepblue::MessageHandler.new( msg_queue: job_msg_queue,
                                                  to_console: task,
                                                  verbose: verbose,
                                                  debug_verbose: debug_verbose )
    ::Deepblue::FindAndFixService.work_find_and_fix( id: id,
                                                     msg_handler: msg_handler,
                                                     debug_verbose: debug_verbose )
    email_all_targets( task_name: EVENT,
                       event: EVENT,
                       body: job_msg_queue.join("\n"),
                       debug_verbose: debug_verbose )
    job_finished

  rescue Exception => e # rubocop:disable Lint/RescueException
    email_all_targets( task_name: EVENT,
                       event: EVENT,
                       body: job_msg_queue.join("\n") + e.message + "\n" + e.backtrace.join("\n"),
                       debug_verbose: debug_verbose )
    job_status_register( exception: e, args: [ id, args ] )
    raise e

  end

end
