# frozen_string_literal: true

require_relative '../services/deepblue/deleted_works_from_log'

class ProvenanceLogController < ApplicationController
  include ProvenanceLogControllerBehavior

  class_attribute :presenter_class
  self.presenter_class = ProvenanceLogPresenter

  attr_accessor :id, :id_msg, :id_invalid, :id_deleted
  attr_accessor :find_id
  attr_accessor :deleted_ids, :deleted_id_to_key_values_map

  def show
    raise CanCan::AccessDenied unless current_ability.admin?
    @id = params[:id]
    @id_deleted = false
    @id_invalid = false
    @id_msg = ''
    id_check
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "" ]
    provenance_log_entries_refresh( id: id ) if id_valid? || id_deleted
    @presenter = presenter_class.new( controller: self )
    render 'provenance_log/provenance_log'
  end

  def id_check
    return if id.blank?
    ActiveFedora::Base.find( id )
  rescue Ldp::Gone => g
    @id_msg = "deleted"
    @id_deleted = true
  rescue ActiveFedora::ObjectNotFoundError => e2
    @id_msg = "invalid"
    @id_invalid = true
  end

  def id_valid?
    return false if id.blank?
    return false if ( id_deleted || id_invalid )
    true
  end

  def log_zip_download
    require 'zip'
    require 'tempfile'
    raise CanCan::AccessDenied unless current_ability.admin?

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ]

    tmp_dir = ENV['TMPDIR'] || "/tmp"
    tmp_dir = Pathname.new tmp_dir
    Deepblue::LoggingHelper.bold_debug [ "zip_log_download begin", "tmp_dir=#{tmp_dir}" ]

    target_dir = tmp_dir
    Deepblue::LoggingHelper.bold_debug [ "zip_log_download", "target_dir=#{target_dir}" ]
    Dir.mkdir( target_dir ) unless Dir.exist?( target_dir )
    base_file_name = "provenance_#{Rails.env}.log"
    src_file_name = Pathname.new Rails.root.join( 'log', base_file_name )
    target_zipfile = target_dir.join "#{base_file_name}.zip"
    Deepblue::LoggingHelper.bold_debug [ "zip_log_download", "target_zipfile=#{target_zipfile}" ]
    File.delete target_zipfile if File.exist? target_zipfile
    Deepblue::LoggingHelper.debug "Download Zip begin copy to folder #{target_dir}"
    Deepblue::LoggingHelper.bold_debug [ "zip_log_download", "begin zip of src_file_name=#{src_file_name}" ]
    Zip::File.open( target_zipfile.to_s, Zip::File::CREATE ) do |zipfile|
      zipfile.add( base_file_name, src_file_name )
    end
    Deepblue::LoggingHelper.bold_debug [ "zip_log_download", "download complete target_dir=#{target_dir}" ]
    send_file target_zipfile.to_s
  end

  def find
    raise CanCan::AccessDenied unless current_ability.admin?
    @find_id = params[:find_id]
    @id = find_id
    @id_deleted = false
    @id_invalid = false
    @id_msg = ''
    id_check
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "find_id=#{find_id}",
                                           "id=#{id}",
                                           "" ]
    provenance_log_entries_refresh( id: id ) if id_valid? || id_deleted
    @presenter = presenter_class.new( controller: self )
    render 'provenance_log/provenance_log'
  end

  def deleted_works
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ]
    runner = ::Deepblue::DeletedWorksFromLog.new( input: ::Deepblue::ProvenanceLogService.provenance_log_path )
    runner.run
    @deleted_ids = runner.deleted_ids
    @deleted_id_to_key_values_map = runner.deleted_id_to_key_values_map
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "deleted_ids=#{deleted_ids}",
    #                                        "deleted_id_to_key_values_map=#{deleted_id_to_key_values_map}",
    #                                        "" ]
    @presenter = presenter_class.new( controller: self )
    render 'provenance_log/provenance_log'
  end

end
