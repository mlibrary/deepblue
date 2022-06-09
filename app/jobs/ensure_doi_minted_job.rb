# frozen_string_literal: true

class EnsureDoiMintedJob < ::Deepblue::DeepblueJob

  mattr_accessor :ensure_doi_minted_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.ensure_doi_minted_job_debug_verbose

  queue_as :default

  EVENT = "ensure doi minted"

  def perform( id, *args )
    debug_verbose = ensure_doi_minted_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "args=#{args}",
                                           "" ] if debug_verbose
    initialize_options_from( *args, debug_verbose: debug_verbose )
    log( event: EVENT, hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    msg_handler = ::Deepblue::MessageHandler.new( msg_queue: job_msg_queue, task: task, verbose: verbose )
    ::Deepblue::DoiMintingService.ensure_doi_minted( id: id,
                                                     msg_handler: msg_handler,
                                                     task: task,
                                                     debug_verbose: debug_verbose )
    email_all_targets( task_name: EVENT,
                       event: EVENT ,
                       body: job_msg_queue.join("\n"),
                       debug_verbose: ensure_doi_minted_job_debug_verbose )
    job_finished

  rescue Exception => e # rubocop:disable Lint/RescueException
    email_all_targets( task_name: EVENT,
                       event: EVENT,
                       body: job_msg_queue.join("\n") + e.message + "\n" + e.backtrace.join("\n"),
                       debug_verbose: ensure_doi_minted_job_debug_verbose )
    job_status_register( exception: e, args: [ id, args ] )
    raise e

  end

end
