# frozen_string_literal: true

class RegisterDoiJob < ::Deepblue::DeepblueJob
  queue_as Hyrax.config.ingest_queue_name

  ##
  # @param model [ActiveFedora::Base]
  # @param registrar [String] Note this is a string and not a symbol because ActiveJob cannot serialize a symbol
  # @param registrar_opts [Hash]
  def perform(model, registrar: Hyrax.config.identifier_registrars.keys.first, registrar_opts: {})
    Hyrax::Identifier::Dispatcher.for(registrar.to_sym,
                                      **registrar_opts).assign_for_single_value!(object: model,
                                                                    attribute: :doi)
  end

end
