# frozen_string_literal: true

module PersistHelper

  def self.find( id )
    ::ActiveFedora::Base.find( id )
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

  def self.where( values )
    ::ActiveFedora::Base.where( values )
  end

end
