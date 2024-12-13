# frozen_string_literal: true
# Reviewed: hyrax4
# Updated: hyrax5

# monkey override:
# require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/models/concerns/hyrax/collection_behavior.rb" )
#
# module Hyrax
#
#   # monkey patch Hyrax::CollectionBehavior
#   # monkey patch methods that don't specify row count to return from search_with_conditions.
#   # The default value for row count leads to errors for works with large numbers of files.
#   module CollectionBehavior
#     include ::Deepblue::WorkflowEventBehavior
#
#     # monkey to keep
#     # Compute the sum of each file in the collection using Solr to
#     # avoid having to access Fedora
#     #
#     # @return [Fixnum] size of collection in bytes
#     # @raise [RuntimeError] unsaved record does not exist in solr
#     def bytes
#       return 0 if member_object_ids.empty?
#
#       raise "Collection must be saved to query for bytes" if new_record?
#
#       # One query per member_id because Solr is not a relational database
#       member_object_ids.collect { |work_id| size_for_work(work_id) }.sum
#     end
#
#     # use the hyrax v3 version of #member_object_ids
#     # # Use this query to get the ids of the member objects (since the containment
#     # # association has been flipped)
#     # def member_object_ids
#     #   return [] unless id
#     #   ::PersistHelper.search_with_conditions("member_of_collection_ids_ssim:#{id}", rows: 1000 ).map(&:id)
#     # end
#
#     # monkey to add
#     # Calculate the size of all the files in the work
#     # @param work_id [String] identifer for a work
#     # @return [Integer] the size in bytes
#     def size_for_work(work_id)
#       argz = { fl: "id, #{file_size_field}",
#                fq: "{!join from=#{member_ids_field} to=id}id:#{work_id}",
#                rows: 10_000 }
#       files = ::FileSet.search_with_conditions({}, argz)
#       files.reduce(0) { |sum, f| sum + f[file_size_field].to_i }
#     end
#
#     # monkey to add
#     # Field name to look up when locating the size of each file in Solr.
#     # Override for your own installation if using something different
#     def file_size_field
#       :file_size_lts
#     end
#
#   end
#
# end

module Hyrax
  module CollectionBehavior
    extend ActiveSupport::Concern
    include Hydra::AccessControls::WithAccessRight
    include Hydra::WithDepositor # for access to apply_depositor_metadata
    include Hyrax::CoreMetadata
    include Hydra::Works::CollectionBehavior
    include Hyrax::Noid
    include Hyrax::HumanReadableType
    include Hyrax::HasRepresentative
    include Hyrax::Permissions
    include ::Deepblue::WorkflowEventBehavior

    included do
      validates_with HasOneTitleValidator
      after_destroy :destroy_permission_template

      self.indexer = Hyrax::CollectionIndexer

      class_attribute :index_collection_type_gid_as, instance_writer: false
      self.index_collection_type_gid_as = [:symbol]

      property :collection_type_gid, predicate: ::RDF::Vocab::SCHEMA.additionalType, multiple: false do |index|
        index.as(*index_collection_type_gid_as)
      end

      # validates that collection_type_gid is present
      validates :collection_type_gid, presence: true

      # Need to define here in order to override setter defined by ActiveTriples
      def collection_type_gid=(new_collection_type_gid, force: false)
        new_collection_type_gid = new_collection_type_gid&.to_s
        raise "Can't modify collection type of this collection" if !force && persisted? && !collection_type_gid_was.nil? && collection_type_gid_was != new_collection_type_gid
        new_collection_type = Hyrax::CollectionType.find_by_gid!(new_collection_type_gid)
        super(new_collection_type_gid)
        @collection_type = new_collection_type
        collection_type_gid
      end
    end

    delegate(*Hyrax::CollectionType.settings_attributes, to: :collection_type)
    # ActiveSupport::Deprecation.deprecate_methods(self, *Hyrax::CollectionType.settings_attributes)
    # monkey to keep
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

    # use the hyrax v3 version of #member_object_ids
    # # Use this query to get the ids of the member objects (since the containment
    # # association has been flipped)
    # def member_object_ids
    #   return [] unless id
    #   ::PersistHelper.search_with_conditions("member_of_collection_ids_ssim:#{id}", rows: 1000 ).map(&:id)
    # end

    # monkey to add
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

    # monkey to add
    # Field name to look up when locating the size of each file in Solr.
    # Override for your own installation if using something different
    def file_size_field
      :file_size_lts
    end

    # Get the collection_type when accessed
    def collection_type
      # Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
      #                    "Instead, use Hyrax::CollectionType.for(collection: collection).")
      @collection_type ||= Hyrax::CollectionType.find_by_gid!(collection_type_gid)
    end

    def collection_type=(new_collection_type)
      self.collection_type_gid = new_collection_type.to_global_id
    end

    # @return [Enumerable<ActiveFedora::Base>] an enumerable over the children of this collection
    def member_objects
      ActiveFedora::Base.where("member_of_collection_ids_ssim:#{id}")
    end

    # Use this query to get the ids of the member objects (since the containment
    # association has been flipped)
    def member_object_ids
      return [] unless id
      member_objects.map(&:id)
    end

    def to_s
      title.present? ? title.join(' | ') : 'No Title'
    end

    module ClassMethods
      # This governs which partial to draw when you render this type of object
      def _to_partial_path # :nodoc:
        @_to_partial_path ||= begin
                                element = ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.demodulize(name))
                                collection = ActiveSupport::Inflector.tableize(name)
                                "hyrax/#{collection}/#{element}"
                              end
      end
    end

    # @api public
    # Retrieve the permission template for this collection.
    # @return [Hyrax::PermissionTemplate]
    # @raise [ActiveRecord::RecordNotFound]
    def permission_template
      Hyrax::PermissionTemplate.find_by!(source_id: id)
    end

    private

    # Solr field name works use to index member ids
    def member_ids_field
      "member_ids_ssim"
    end

    def destroy_permission_template
      permission_template.destroy
    rescue ActiveRecord::RecordNotFound
      true
    end
  end
end
