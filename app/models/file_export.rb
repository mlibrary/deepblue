# frozen_string_literal: true

require_relative './application_record'

class FileExport < ApplicationRecord

  self.table_name = "file_exports"

  def self.all_for( export_work: )
    FileExport.where( file_sys_exports_id: export_work.id )
  end

  def self.csv_row( record )
    rv = if record.blank?
           [ 'id',
             'export_type',
             'export_noid',
             'noid',
             'export_status',
             'export_status_timestamp',
             'base_noid_path',
             'checksum_value',
             'checksum_algorithm',
             'checksum_validated',
             'export_file_name',
             'file_sys_exports_id',
             'note',
             'created_at',
             'updated_at'
           ]
         else
           record = Array( record ).first
           [ record.id,
             record.export_type,
             record.export_noid,
             record.noid,
             record.export_status,
             record.export_status_timestamp,
             record.base_noid_path,
             record.checksum_value,
             record.checksum_algorithm,
             record.checksum_validated,
             record.export_file_name,
             record.file_sys_exports_id,
             record.note,
             record.created_at,
             record.updated_at
           ]

         end
    return rv
  end

  def self.export_status_for( fs: nil, noid: nil )
    rv = []
    rv = for_file_set( fs: cc ) if fs.present?
    rv = for_id( noid: noid ) if noid.present?
    return '' if rv.blank?
    return rv.first.event
  end

  def self.find_or_create( file_sys_export:, noid:, export_status: nil )
    record = FileExport.find_or_create_by( file_sys_exports_id: file_sys_export.id, noid: noid ) do |create|
      export_status ||= FileSysExportC::STATUS_EXPORT_NEEDED
      create.file_sys_exports_id     = file_sys_export.id # is this necessary?
      create.noid                    = noid
      create.export_type             = file_sys_export.export_type
      create.export_noid             = file_sys_export.noid
      create.export_status           = export_status
      create.base_noid_path          = FileSysExportService.pair_path( noid: file_sys_export.noid )
      # create.checksum_value          = fs.checksum_value
      # create.checksum_algorithm      = fs.checksum_algorithm
      create.export_status_timestamp = DateTime.now
    end
    return record
  end

  def self.find_or_create_for_fs( file_sys_export:, fs:, export_status: nil )
    record = FileExport.find_or_create_by( file_sys_exports_id: file_sys_export.id, noid: fs.id ) do |create|
      export_status ||= FileSysExportC::STATUS_EXPORT_NEEDED
      create.file_sys_exports_id     = file_sys_export.id # is this necessary?
      create.noid                    = fs.id
      create.export_type             = file_sys_export.export_type
      create.export_noid             = file_sys_export.noid
      create.export_status           = export_status
      create.base_noid_path          = FileSysExportService.pair_path( noid: file_sys_export.noid )
      create.checksum_value          = fs.checksum_value
      create.checksum_algorithm      = fs.checksum_algorithm
      create.export_status_timestamp = DateTime.now
    end
    return record
  end

  def self.for_export_status( export_status: )
    FileExport.where( export_status: export_status )
  end

  def self.for_file_set( fs: )
    return nil unless fs.present?
    FileExport.where( noid: fs.id )
  end

  def self.for_id( noid: )
    return nil unless noid.present?
    FileExport.where( noid: noid )
  end

  def self.for_file_sys_export( file_sys_export: )
    FileExport.where( file_sys_exports_id: file_sys_export.id )
  end

  # def self.for_most_recent_event( noid:, event: )
  #   FileExport.where( noid: noid, event: event ).order( updated_at: :desc )
  # end

  def self.for_export_status_between( begin_date:, end_date: )
    FileExport.where( [ 'export_status_timestamp >= ? AND export_status_timestamp <= ?', begin_date, end_date ] ).order( export_status_timestamp: :desc )
  end

  def self.for_update_between( begin_date:, end_date: )
    FileExport.where( [ 'updated_at >= ? AND updated_at <= ?', begin_date, end_date ] ).order( updated_at: :desc )
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

  def export_file_path
    rv = export_file_name
    rv ||= ""
    return rv if base_noid_path.blank?
    rv = File.join( base_noid_path, rv )
    return rv
  end

  # def status( status, with_note: nil )
  #   export_status = status
  #   export_status_timestamp = DateTime.now
  #   note = with_note if with_note.present?
  # end

  # def status!( status, with_note: nil )
  #   puts "FileExport.status!( #{status}, #{with_note} )"
  #   export_status = status
  #   export_status_timestamp = DateTime.now
  #   note = with_note if with_note.present?
  #   rv = save
  #   puts "rv=#{rv}"
  #   return rv
  # end

end
