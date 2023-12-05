# frozen_string_literal: true

class Aptrust::Status < ApplicationRecord

  mattr_accessor :aptrust_status_debug_verbose, default: false

  def self.for_id( noid: )
    where( noid: noid )
  end

end
