# frozen_string_literal: true

class Provenance < ApplicationRecord

  mattr_accessor :provenance_debug_verbose, default: Rails.configuration.provenance_debug_verbose

  serialize :key_values, JSON

  def self.for_id( cc_id: )
    Provenance.where( cc_id: cc_id )
  end

  def self.for_id_date_range( cc_id:, begin_date:, end_date: )
    Provenance.where(['timestamp >= ? AND timestamp <= ?', begin_date, end_date])
              .where(cc_id: cc_id)
              .order(timestamp: :desc)
  end

  def self.for_timestamp_event( timestamp:, event: )
    Provenance.where( timestamp: timestamp, event: event )
  end

end
