# frozen_string_literal: true

class RegisterDoiJob < ::Deepblue::DeepblueJob

  # queue_as Hyrax.config.ingest_queue_name
  queue_as :doi_minting

  ##
  # @param model [ActiveFedora::Base]
  # @param registrar [String] Note this is a string and not a symbol because ActiveJob cannot serialize a symbol
  # @param registrar_opts [Hash]
  #def perform( id:,
  #             current_user: nil,
  #             force_doi_minting: false,
  #             debug_verbose: ::Deepblue::DoiMintingService.register_doi_job_debug_verbose,
  #             registrar: nil,
  #             registrar_opts: {} )
  def perform( *args )
    args = [{}] if args.nil? || args[0].nil?
    id = args[0][:id]
    current_user = args[0][:current_user]
    force_doi_minting = args[0][:force_doi_minting]
    force_doi_minting ||= false
    debug_verbose = args[0][:debug_verbose]
    debug_verbose ||= ::Deepblue::DoiMintingService.register_doi_job_debug_verbose
    registrar = args[0][:registrar]
    registrar_opts = args[0][:registrar_opts]
    registrar_opts ||= {}

    initialize_no_args_hash( id: id, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "current_user=#{current_user}",
                                           "force_doi_minting=#{force_doi_minting}",
                                           "registrar=#{registrar}",
                                           "registrar_opts=#{registrar_opts}",
                                           "" ] if debug_verbose
    model = PersistHelper.find id
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "model.class.name=#{model.class.name}",
                                           "id=#{id}",
                                           "model&.doi=#{model&.doi}",
                                           "" ] if debug_verbose
    ::Deepblue::DoiMintingService.registrar_mint_doi( curation_concern: model,
                                                      current_user: current_user,
                                                      force_doi_minting: force_doi_minting,
                                                      debug_verbose: debug_verbose,
                                                      registrar: registrar,
                                                      registrar_opts: registrar_opts,
                                                      msg_handler: msg_handler )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    args = { id: id,
             current_user: current_user.pretty_inspect,
             registrar: registrar.pretty_inspect,
             registrar_opts: registrar_opts.pretty_inspect,
             debug_verbose: debug_verbose }
    job_status_register( exception: e, rails_log: true, args: args )
    email_failure( task_name: task_name, task_args: args, exception: e, event: event_name )
    raise e
  end

end
