# frozen_string_literal: true

module PersistHelper

  def self.all
    ::ActiveFedora::Base.all
  end

  def self.find( id, use_valkyrie: false )
    if use_valkyrie
      ::Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: id, use_valkyrie: use_valkyrie)
    else
      ::ActiveFedora::Base.find(id)
    end
  end

  def self.find_solr( id, fail_if_not_found: true )
    if fail_if_not_found
      return ::SolrDocument.find( id )
    else
      begin
        return ::SolrDocument.find( id )
      rescue ::Blacklight::Exceptions::RecordNotFound => _ignore_and_fall_through
      end
    end
    return nil
  end

  def self.find_many( ids, use_valkyrie: false )
    if use_valkyrie
      ::Hyrax.custom_queries.find_many_by_alternate_ids(alternate_ids: ids, use_valkyrie: use_valkyrie)
    else
      ::ActiveFedora::Base.find(ids)
    end
  end

  # returns nil Ldp::Gone or Hyrax::ObjectNotFoundError
  def self.find_or_nil( id )
    PersistHelper.find( id )
  rescue Ldp::Gone
    nil
  rescue ::Hyrax::ObjectNotFoundError
    nil
  rescue ::ActiveFedora::ObjectNotFoundError
    nil
  end

  # Allows the user to find out if an id has been used in the system and then been deleted
  # @param uri id in fedora that may or may not have been deleted
  def self.gone?( uri, use_valkyrie: false )
    ::ActiveFedora::Base.find( uri )
    false
  rescue Ldp::Gone
    true
  rescue ::Hyrax::ObjectNotFoundError
    false
  end

  def self.id_to_uri( id )
    ::Hyrax::Base.id_to_uri( id )
  end

  def self.search_by_id(id, opts = {})
    ActiveFedora::Base.search_by_id(id, opts)
  end

  def self.search_with_conditions( conditions, opts = {} )
    ::ActiveFedora::Base.search_with_conditions( conditions, opts )
  end

  def self.uri_to_id( uri )
    ::Hyrax::Base.uri_to_id( uri )
  end

  def self.where( values )
    ::ActiveFedora::Base.where( values )
  end


  # TODO: alias this?
  def self.find_curation_concern( id, use_valkyrie: false )
    find( id, use_valkyrie: use_valkyrie )
  end

  def member_of_collection_by_id(id)
    where("member_of_collection_ids_ssim:#{id}")
  end

  def self.uncached(&block)
    ::Hyrax::Base.uncached(&block)
  end

  def self.file_sets_for(curation_concern)
    Hyrax.custom_queries.find_child_filesets(resource: curation_concern)
  end

end
