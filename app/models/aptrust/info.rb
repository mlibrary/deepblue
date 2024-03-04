# frozen_string_literal: true

class Aptrust::Info < ApplicationRecord

  mattr_accessor :aptrust_info_debug_verbose, default: false

  serialize :results, JSON

  def self.for_id( noid: )
    where( noid: noid )
  end

end
