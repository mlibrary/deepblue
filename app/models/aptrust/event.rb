# frozen_string_literal: true

require_relative '../application_record'

class Aptrust::Event < ApplicationRecord

  self.table_name = "aptrust_events"

  mattr_accessor :aptrust_event_debug_verbose, default: false

  def self.csv_row( record )
    rv = if record.blank?
           [ 'id',
             'timestamp',
             'event',
             'event_note',
             'noid',
             'created_at',
             'updated_at',
             'aptrust_status_id',
             'service' ]
         else
           record = Array( record ).first
           [ record.id,
             record.timestamp,
             record.event,
             record.event_note,
             record.noid,
             record.created_at,
             record.updated_at,
             record.aptrust_status_id,
             record.service ]
         end
    return rv
  end

  def self.for_id( noid: )
    where( noid: noid )
  end

  def self.for_status( status: )
    where( aptrust_status_id: status.id )
  end

  def self.for_most_recent_event( noid:, event: )
    where( noid: noid, event: event ).order( updated_at: :desc )
  end

  def self.for_update_between( begin_date:, end_date: )
    where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] ).order( updated_at: :desc )
  end

end
