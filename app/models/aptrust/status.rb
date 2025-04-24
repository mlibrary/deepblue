# frozen_string_literal: true

require_relative '../application_record'

class Aptrust::Status < ApplicationRecord

  self.table_name = "aptrust_statuses"

  mattr_accessor :aptrust_status_debug_verbose, default: false

  def self.csv_row( record )
    rv = if record.blank?
           [ 'id',
             'timestamp',
             'event',
             'event_note',
             'noid',
             'created_at',
             'updated_at' ]
         else
           record = Array( record ).first
           [ record.id,
             record.timestamp,
             record.event,
             record.event_note,
             record.noid,
             record.created_at,
             record.updated_at ]
         end
    return rv
  end

  def self.for_curation_concern( cc: )
    return nil unless cc.present?
    where( noid: cc.id )
  end

  def self.for_id( noid: )
    return nil unless noid.present?
    where( noid: noid )
  end

  def self.has_status?( cc: nil, noid: nil, event: nil )
    status = []
    status = for_curation_concern( cc: cc ) if cc.present?
    status = for_id( noid: noid ) if noid.present?
    return false if status.blank?
    return true if event.blank?
    return status.first.event == event
  end

  def self.status( cc: nil, noid: nil )
    status = []
    status = for_curation_concern( cc: cc ) if cc.present?
    status = for_id( noid: noid ) if noid.present?
    return '' if status.blank?
    return status.first.event
  end

  def type
    return "DataSet"
  end

  def self.update_note( noid:, note:, append: true )
    r = for_id( noid: noid )
    return unless r.present?
    r = r.first
    event_note = r.event_note
    event_note ||= ''
    event_note = '' unless append
    event_note += ';' if event_note.present? if append
    event_note += note
    r.event_note = event_note
    r.save!
  end

end
