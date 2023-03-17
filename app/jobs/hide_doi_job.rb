# frozen_string_literal: true

class HideDoiJob < ::Deepblue::DeepblueJob

  # queue_as Hyrax.config.ingest_queue_name
  queue_as :doi_minting

  ##
  # @param model [ActiveFedora::Base]
  # @param registrar [String] Note this is a string and not a symbol because ActiveJob cannot serialize a symbol
  # @param registrar_opts [Hash]
  def perform( id:,
               current_user: nil,
               debug_verbose: ::Deepblue::DoiMintingService.hide_doi_job_debug_verbose,
               registrar: nil,
               registrar_opts: {} )

    initialize_no_args_hash( id: id, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "current_user=#{current_user}",
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
    ::Deepblue::DoiMintingService.registrar_hide_doi( curation_concern: model,
                                                      current_user: current_user,
                                                      debug_verbose: debug_verbose,
                                                      registrar: registrar,
                                                      registrar_opts: registrar_opts )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e,
                         rails_log: true,
                         args: { model: model,
                                 current_user: current_user,
                                 registrar: registrar,
                                 registrar_opts: registrar_opts,
                                 debug_verbose: debug_verbose } )
    email_failure( task_name: task_name, exception: e, event: event_name )
    raise e
  end

end
