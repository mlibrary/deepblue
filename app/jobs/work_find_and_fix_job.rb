# frozen_string_literal: true

class WorkFindAndFixJob < ::Deepblue::DeepblueJob

  mattr_accessor :work_find_and_fix_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.work_find_and_fix_job_debug_verbose

  queue_as :default

  EVENT = "work find and fix"

  def perform( id:, **args )
    initialize_options_from( args: args, id: id, debug_verbose: work_find_and_fix_job_debug_verbose )
    log( event: EVENT, hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    ::Deepblue::FindAndFixService.work_find_and_fix( id: id, msg_handler: msg_handler )
    email_all_targets( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: [ id, args ] )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
