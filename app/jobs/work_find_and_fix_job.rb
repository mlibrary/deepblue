# frozen_string_literal: true

class WorkFindAndFixJob < ::Deepblue::DeepblueJob

  mattr_accessor :work_find_and_fix_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.work_find_and_fix_job_debug_verbose

  queue_as :default

  EVENT = "work find and fix"

  # def perform( id:, **args )
  # hyrax4 / ruby3 upgrade
  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "args.class.name=#{args.class.name}",
                                           "args=#{args}",
                                           "" ] if work_find_and_fix_job_debug_verbose
    args = [{}] if args.nil? || args[0].nil?
    if args.is_a? Array
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                             "args.class.name=#{args.class.name}",
                                             "args=#{args}",
                                             "args[0].class.name=#{args[0].class.name}",
                                             "args[0]=#{args[0]}",
                                             "" ] if work_find_and_fix_job_debug_verbose
      if args[0].is_a? Hash
        args = args[0]
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                               "args.class.name=#{args.class.name}",
                                               "args=#{args}",
                                               "args[:id]=#{args[:id]}",
                                               "" ] if work_find_and_fix_job_debug_verbose
        id = args[:id]
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                             "id=#{id}",
                                             "" ] if work_find_and_fix_job_debug_verbose
      end
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "args.class.name=#{args.class.name}",
                                           "args=#{args}",
                                           "" ] if work_find_and_fix_job_debug_verbose
    args ||= {}
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here, ::Deepblue::LoggingHelper.called_from,
                                           "args.class.name=#{args.class.name}",
                                           "args=#{args}",
                                           "id=#{id}",
                                           "" ] if work_find_and_fix_job_debug_verbose
    #initialize_options_from( args: args, id: id, debug_verbose: work_find_and_fix_job_debug_verbose )
    initialize_options_from( args: args, debug_verbose: work_find_and_fix_job_debug_verbose )
    log( event: EVENT, hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    ::Deepblue::FindAndFixService.work_find_and_fix( id: @id, msg_handler: msg_handler )
    email_all_targets( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: [ id, args ] )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
