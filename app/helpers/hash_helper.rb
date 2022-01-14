# frozen_string_literal: true

module HashHelper

  mattr_accessor :hash_helper_debug_verbose, default: false

  def self.get( hash, key, default = nil )
    return {} if hash.nil?
    value = hash[key]
    return default if value.nil?
    return value
  end

end
