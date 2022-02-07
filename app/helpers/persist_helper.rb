# frozen_string_literal: true

module PersistHelper

  def self.all
    ::ActiveFedora::Base.all
  end

  def self.find( id )
    ::ActiveFedora::Base.find( id )
  end

  # returns nil Ldp::Gone or ActiveFedora::ObjectNotFoundError
  def self.find_or_nil( id )
    PersistHelper.find( id )
  rescue Ldp::Gone
    nil
  rescue ::ActiveFedora::ObjectNotFoundError
    nil
  end

  # Allows the user to find out if an id has been used in the system and then been deleted
  # @param uri id in fedora that may or may not have been deleted
  def self.gone?( uri )
    ::ActiveFedora::Base.find( uri )
    false
  rescue Ldp::Gone
    true
  rescue ::ActiveFedora::ObjectNotFoundError
    false
  end

  def self.id_to_uri( id )
    ::ActiveFedora::Base.id_to_uri( id )
  end

  def self.search_with_conditions( conditions, opts = {} )
    ::ActiveFedora::Base.search_with_conditions( conditions, opts )
  end

  def self.uri_to_id( uri )
    ::ActiveFedora::Base.uri_to_id( uri )
  end

  def self.where( values )
    ::ActiveFedora::Base.where( values )
  end

end
