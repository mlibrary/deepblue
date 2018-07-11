# frozen_string_literal: true

module Deepblue
  module FileSetMetadata
    extend ActiveSupport::Concern

    included do

      property :file_size, predicate: ::RDF::Vocab::DC.SizeOrDuration, multiple: false

      property :prior_identifier, predicate: ActiveFedora::RDF::Fcrepo::Model.altIds, multiple: true do |index|
        index.as :stored_searchable
      end

      # TODO: can't use the same predicate twice
      # property :total_file_size_human_readable, predicate: ::RDF::Vocab::DC.SizeOrDuration, multiple: false

    end

  end
end
