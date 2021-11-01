# frozen_string_literal: true

class RegisterDoiJob < ::Deepblue::DeepblueJob

  # queue_as Hyrax.config.ingest_queue_name
  queue_as :doi_minting

  ##
  # @param model [ActiveFedora::Base]
  # @param registrar [String] Note this is a string and not a symbol because ActiveJob cannot serialize a symbol
  # @param registrar_opts [Hash]
  def perform(model,
              current_user: nil,
              debug_verbose: ::Deepblue::DoiMintingService.register_doi_job_debug_verbose,
              registrar: Hyrax.config.identifier_registrars.keys.first,
              registrar_opts: {})

    initialize_no_args_hash( debug_verbose: debug_verbose )
    id = model&.id
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "model.class.name=#{model.class.name}",
                                           "model&.id=#{model&.id}",
                                           "model&.doi=#{model&.doi}",
                                           "current_user=#{current_user}",
                                           "registrar=#{registrar}",
                                           "registrar_opts=#{registrar_opts}",
                                           "" ] if debug_verbose
    ::Deepblue::DoiMintingService.registrar_mint_doi( curation_concern: model,
                                                      current_user: current_user,
                                                      registrar: registrar,
                                                      registrar_opts: registrar_opts )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "RegisterDoiJob.perform(#{model&.id}, #{e.class}: #{e.message} at #{e.backtrace[0]}"
    raise
  end

end
