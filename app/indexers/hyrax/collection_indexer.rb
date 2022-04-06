module Hyrax
  class CollectionIndexer < Hydra::PCDM::CollectionIndexer
    include Hyrax::IndexesThumbnails

    STORED_LONG = Solrizer::Descriptor.new(:long, :stored)

    self.thumbnail_path_service = Hyrax::CollectionThumbnailPathService

    # @yield [Hash] calls the yielded block with the solr document
    # @return [Hash] the solr document WITH all changes
    def generate_solr_document
      super.tap do |solr_doc|
        # Makes Collections show under the "Collections" tab
        solr_doc['generic_type_sim'] = ["Collection"]
        solr_doc['visibility_ssi'] = object.visibility

        # So that title sort can be done ...
        solr_doc['title_sort_ssi'] = Array(object.title).first.downcase unless object.title.blank?

        object.in_collections.each do |col|
          (solr_doc['member_of_collection_ids_ssim'] ||= []) << col.id
          (solr_doc['member_of_collections_ssim'] ||= []) << col.to_s
        end
      end
    end
  end
end
