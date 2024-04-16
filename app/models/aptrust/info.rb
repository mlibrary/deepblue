# frozen_string_literal: true

require_relative '../application_record'

class Aptrust::Info < ApplicationRecord

  self.table_name = "aptrust_infos"

  mattr_accessor :aptrust_info_debug_verbose, default: false

  serialize :results, JSON

  def self.for_id( noid: )
    where( noid: noid )
  end

end
