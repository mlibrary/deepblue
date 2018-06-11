# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

DeepBlueDocs::Application.config.after_initialize do
  # Rails.logger.info "Initializing provenance logging..."
  # STDOUT.puts "Initializing provenance logging..."
  require 'provenance_persistence'
  ActiveFedora::Persistence.prepend( ::Deepblue::ProvenancePersistenceExt )
end
