# frozen_string_literal: true

module Umrdr
  module UmrdrWorkMetadata
    extend ActiveSupport::Concern

    included do

      property :authoremail, predicate: ::RDF::Vocab::FOAF.mbox, multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :creator_ordered, predicate: ::RDF::Vocab::MODS.name, multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :curation_notes_admin, predicate: ::RDF::Vocab::MODS.note, multiple: true do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :curation_notes_admin_ordered, predicate: ::RDF::URI.new('https://deepblue.lib.umich.edu/data/help.help#curation_notes_admin_ordered'), multiple: true do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :curation_notes_user, predicate: ::RDF::Vocab::MODS.note, multiple: true do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :curation_notes_user_ordered, predicate: ::RDF::URI.new('https://deepblue.lib.umich.edu/data/help.help#curation_notes_user_ordered'), multiple: true do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :date_coverage, predicate: ::RDF::Vocab::DC.temporal, multiple: false do |index|
        index.type :text
        index.as :stored_searchable, :facetable
      end

      property :description_ordered, predicate: ::RDF::URI.new('https://deepblue.lib.umich.edu/data/help.help#description_ordered'), multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :doi, predicate: ::RDF::Vocab::Identifiers.doi, multiple: false

      property :fundedby, predicate: ::RDF::Vocab::DISCO.fundedBy, multiple: true do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :fundedby_other, predicate: ::RDF::URI.new('https://deepblue.lib.umich.edu/data/help.help#fundedby_other'), multiple: true do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :grantnumber, predicate: ::RDF::URI.new('http://purl.org/cerif/frapo/hasGrantNumber'), multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :hdl, predicate: ::RDF::Vocab::Identifiers.hdl, multiple: false

      property :referenced_by, predicate: ::RDF::Vocab::DC.isReferencedBy, multiple: true do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :referenced_by_ordered, predicate: ::RDF::URI.new('https://deepblue.lib.umich.edu/data/help.help#referenced_by_ordered'), multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end
      
      property :rights_license_other, predicate: ::RDF::Vocab::DC.rights, multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :keyword_ordered, predicate: ::RDF::URI.new('https://deepblue.lib.umich.edu/data/help.help#keyword_ordered'), multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :language_ordered, predicate: ::RDF::URI.new('https://deepblue.lib.umich.edu/data/help.help#language_ordered'), multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :methodology, predicate: ::RDF::URI.new('http://www.ddialliance.org/Specification/DDI-Lifecycle/3.2/XMLSchema/FieldLevelDocumentation/schemas/datacollection_xsd/elements/DataCollectionMethodology.html'), multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :subject_discipline, predicate: ::RDF::Vocab::MODS.subject, multiple: true do |index|
        index.type :text
        index.as :stored_searchable, :facetable
      end

      property :title_ordered, predicate: ::RDF::URI.new('https://deepblue.lib.umich.edu/data/help.help#title_ordered'), multiple: false do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :tombstone, predicate: ::RDF::Vocab::DC.provenance, multiple: true do |index|
        index.type :text
        index.as :stored_searchable
      end

      property :total_file_size, predicate: ::RDF::Vocab::DC.SizeOrDuration, multiple: false

      # TODO: can't use the same predicate twice
      # property :total_file_size_human_readable, predicate: ::RDF::Vocab::DC.SizeOrDuration, multiple: false

    end

  end
end
