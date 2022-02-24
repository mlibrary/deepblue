# frozen_string_literal: true

class DataSetIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Uncomment this block if you want to add custom indexing behavior:
  # def generate_solr_document
  #  super.tap do |solr_doc|
  #    solr_doc['my_custom_field_ssim'] = object.my_custom_property
  #  end
  # end

  def generate_solr_document
    super.tap do |solr_doc|
      # ### same as
      # solr_doc[Solrizer.solr_name('member_ids', :symbol)] = object.member_ids
      # solr_doc[Solrizer.solr_name('member_of_collections', :symbol)] = object.member_of_collections.map(&:first_title)
      # solr_doc[Solrizer.solr_name('member_of_collection_ids', :symbol)] = object.member_of_collections.map(&:id)
      # ### this:
      # solr_doc['member_ids_ssim'] = object.member_ids
      # solr_doc['member_of_collections_ssim']    = object.member_of_collections.map(&:first_title)
      # solr_doc['member_of_collection_ids_ssim'] = object.member_of_collections.map(&:id)

      solr_doc[Solrizer.solr_name('creator_ordered', :stored_searchable)] = object.creator_ordered
      solr_doc[Solrizer.solr_name('doi', :symbol)] = object.doi

      # this causes referenced_by to be displayed as a single string, not a list of values
      # value = Array( object.referenced_by ).join( " " )
      # solr_doc[Solrizer.solr_name('referenced_by', :stored_searchable)] = value

      # So that title sort can be done ...
      value = Array( object.title ).join( " " )
      solr_doc[Solrizer.solr_name('title', :stored_searchable)] = value
      solr_doc[Solrizer.solr_name('title', :stored_sortable)] = value

      solr_doc[Solrizer.solr_name('tombstone', :symbol)] = object.tombstone
      # solr_doc[Solrizer.solr_name('total_file_size', Hyrax::FileSetIndexer::STORED_LONG)] = object.total_file_size
      solr_doc[Solrizer.solr_name('total_file_size', Hyrax::FileSetIndexer::STORED_LONG)] = object.size_of_work

      # ### same as
      # admin_set_label = object.admin_set.to_s
      # solr_doc[Solrizer.solr_name('admin_set', :facetable)] = admin_set_label
      # solr_doc[Solrizer.solr_name('admin_set', :stored_searchable)] = admin_set_label
      # ### this:
      # admin_set_label = object.admin_set.to_s
      # solr_doc['admin_set_sim']   = admin_set_label
      # solr_doc['admin_set_tesim'] = admin_set_label
    end
  end

end
