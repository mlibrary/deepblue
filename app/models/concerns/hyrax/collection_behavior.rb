# frozen_string_literal: true

require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/models/concerns/hyrax/collection_behavior.rb" )

module Hyrax

  # monkey patch Hyrax::CollectionBehavior
  # monkey patch methods that don't specify row count to return from search_with_conditions.
  # The default value for row count leads to errors for works with large numbers of files.
  module CollectionBehavior
    include ::Deepblue::WorkflowEventBehavior

    # Compute the sum of each file in the collection using Solr to
    # avoid having to access Fedora
    #
    # @return [Fixnum] size of collection in bytes
    # @raise [RuntimeError] unsaved record does not exist in solr
    def bytes
      return 0 if member_object_ids.empty?

      raise "Collection must be saved to query for bytes" if new_record?

      # One query per member_id because Solr is not a relational database
      member_object_ids.collect { |work_id| size_for_work(work_id) }.sum
    end

    # Use this query to get the ids of the member objects (since the containment
    # association has been flipped)
    def member_object_ids
      return [] unless id
      ::PersistHelper.search_with_conditions("member_of_collection_ids_ssim:#{id}", rows: 1000 ).map(&:id)
    end

    # Calculate the size of all the files in the work
    # @param work_id [String] identifer for a work
    # @return [Integer] the size in bytes
    def size_for_work(work_id)
      argz = { fl: "id, #{file_size_field}",
               fq: "{!join from=#{member_ids_field} to=id}id:#{work_id}",
               rows: 10_000 }
      files = ::FileSet.search_with_conditions({}, argz)
      files.reduce(0) { |sum, f| sum + f[file_size_field].to_i }
    end

    # Field name to look up when locating the size of each file in Solr.
    # Override for your own installation if using something different
    def file_size_field
      :file_size_lts
    end

  end

end
