# frozen_string_literal: true

class EnsureDoiMintedJob < ::Deepblue::DeepblueJob

  mattr_accessor :ensure_doi_minted_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.ensure_doi_minted_job_debug_verbose

  queue_as :default

  EVENT = "ensure doi minted"

  # def perform( id:, current_user:, **args )
  # hyrax4 / ruby3 upgrade
  def perform( *args )
    args = [{}] if args.nil? || args[0].nil?
    id = args[0][:id]
    current_user = args[0][:current_user]
    args = args[0][:args]
    args ||= {}
    debug_verbose = ensure_doi_minted_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "current_user=#{current_user}",
                                           "args=#{args}",
                                           "" ] if debug_verbose
    initialize_options_from( args: args, id: id, debug_verbose: debug_verbose )
    allowed = hostname_allowed?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "hostname_allowed=#{allowed}",
                                           "" ] if debug_verbose
    log( event: EVENT, hostname_allowed: allowed )
    return job_finished unless allowed
    ::Deepblue::DoiMintingService.ensure_doi_minted( id: id,
                                                     current_user: current_user,
                                                     msg_handler: msg_handler,
                                                     debug_verbose: debug_verbose )
    email_all_targets( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: [ id, args ] )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
