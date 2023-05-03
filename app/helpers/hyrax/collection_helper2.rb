# frozen_string_literal: true

module Hyrax

  module CollectionHelper2

    mattr_accessor :hyrax_collection_helper2_debug_verbose, default: false

    def self.member_subcollections_docs( results )
      verbose = true || hyrax_collection_helper2_debug_verbose
      docs = results.documents
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "results.class.name=#{results.class.name}",
                                             "docs.class.name=#{docs.class.name}",
                                             # "docs=#{docs.pretty_inspect}",
                                             "" ] if verbose
      return docs if docs.blank?
      ordered_docs = []
      if Rails.configuration.collection_members_sort_by_title
        ordered_docs = docs.sort! { |a, b| a.title.join(' ') <=> b.title.join(' ') }
      else
        # use the order found in member_collection_ids
        # member_collection_ids # map results docs into a hash using id --> collection
        # walk through member_collection_ids, remove collection with corresponding id from hash, if not null, add to array
        # if there is anything left in the hash, add them to the array
        docs_as_hash = {}
        docs.each { |r| docs_as_hash[r.id] = r }
        member_collection_ids.each do |id|
          if docs_as_hash.key? id
            ordered_docs << docs_as_hash[id]
            docs_as_hash.delete r.id
          end
        end
        docs_as_hash.values.each { |r| ordered_docs << r } unless docs_as_hash.empty?
      end
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             # "ordered_docs=#{ordered_docs.pretty_inspect}",
                                             "" ] if verbose
      return ordered_docs
    end

  end

end
