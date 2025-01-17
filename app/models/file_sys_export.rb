# frozen_string_literal: true

class FileSysExport < ApplicationRecord

  self.table_name = "file_sys_exports"

  mattr_accessor :file_sys_export_debug_verbose, default: false

  def self.csv_row( record )
    rv = if record.blank?
           [ 'export_type',
             'noid',
             'published',
             'export_status',
             'export_status_timestamp',
             'base_noid_path',
             'note',
             'created_at',
             'updated_at'
           ]
         else
           record = Array( record ).first
           [ record.export_type,
             record.noid,
             record.published,
             record.export_status,
             record.export_status_timestamp,
             record.base_noid_path,
             record.note,
             record.created_at,
             record.updated_at
           ]

         end
    return rv
  end

  def self.export_status_for( cc: nil, noid: nil )
    rv = []
    rv = for_curation_concern( cc: cc ) if cc.present?
    rv = for_id( noid: noid ) if noid.present?
    return '' if rv.blank?
    return rv.first.event
  end

  def self.find_or_create( export_type:, export_status: nil, noid:, published: false )
    record = FileSysExport.find_or_create_by( export_type: export_type, noid: noid ) do |create|
      export_status ||= FileSysExportC::STATUS_EXPORT_NEEDED
      create.export_type    = export_type
      create.noid           = noid
      create.export_status  = export_status
      create.base_noid_path = FileSysExportService.pair_path( noid: noid )
      create.published      = published
      create.export_status_timestamp = DateTime.now
    end
    return record
  end

  def self.find_or_create_from_cc( cc:, export_type:, export_status: nil )
    find_or_create( export_type: export_type, export_status: export_status, noid: cc.id, published: cc.published? )
  end

  def self.for_curation_concern( cc: )
    return nil unless cc.present?
    FileSysExport.where( noid: cc.id )
  end

  def self.for_export_status( export_status: )
    FileSysExport.where( export_status: export_status )
  end

  def self.for_export_type( export_type: )
    FileSysExport.where( export_type: export_type )
  end

  def self.for_id( noid: )
    return nil unless noid.present?
    FileSysExport.where( noid: noid )
  end

  def self.for_noid( noid: )
    return nil unless noid.present?
    FileSysExport.where( noid: noid )
  end

  def self.has_status?( cc: nil, noid: nil, export_status: nil )
    # return false if export_status.blank?
    rv = []
    noid = cc.id if cc.present?
    # puts "FileSysExport.has_status? noid=#{noid}"
    rv = for_id( noid: noid ) if noid.present?
    return false if rv.blank?
    # puts ">>>>>>>> FileSysExport.has_status? rv=#{rv}"
    return true if export_status.nil?
    return rv.first.export_status == export_status
  end

  def self.note_update( noid:, note:, append: true )
    r = for_id( noid: noid )
    return unless r.present?
    r = r.first
    r_note = r.note
    r_note ||= ''
    r_note = '' unless append
    r_note += ';' if r_note.present? if append
    r_note += note
    r.note = r_note
    r.save!
  end

  def status( status, with_note: nil )
    export_status = status
    export_status_timestamp = DateTime.now
    note = with_note if with_note.present?
  end

  def status!( status, with_note: nil )
    export_status = status
    export_status_timestamp = DateTime.now
    note = with_note if with_note.present?
    self.save!
  end

end
