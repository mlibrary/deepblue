# frozen_string_literal: true

require_relative '../services/deepblue/deleted_works_from_log'

class ProvenanceLogController < ApplicationController

  mattr_accessor :provenance_log_controller_debug_verbose,
                 default: Rails.configuration.provenance_log_controller_debug_verbose

  include Hyrax::Admin::UsersControllerBehavior
  include ProvenanceLogControllerBehavior
  include BeginEndDateControllerBehavior

  class_attribute :presenter_class
  self.presenter_class = ProvenanceLogPresenter

  attr_accessor :deleted_ids, :deleted_id_to_key_values_map
  attr_accessor :find_id
  attr_accessor :find_user_id
  attr_accessor :id, :id_msg, :id_invalid, :id_deleted
  attr_accessor :works_by_user_id_ids, :works_by_user_id_to_key_values_map

  def begin_date_default
    nil
  end

  def end_date_default
    nil
  end

  def presenter_debug_verbose
    provenance_log_controller_debug_verbose
  end

  def show
    debug_verbose = provenance_log_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    begin_end_date_init_from_parms( debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> Show <<<",
                                           "params[:id]=#{params[:id]}",
                                           "params[:find_id]=#{params[:find_id]}",
                                           "params[:find_user_id]=#{params[:find_user_id]}",
                                           "" ] if debug_verbose
    if params[:find_user_id].present?
      show_works_by_user_id
    else
      show_rest
    end
  end

  def show_rest
    debug_verbose = provenance_log_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    begin_end_date_init_from_parms( debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> Show <<<",
                                           "params[:id]=#{params[:id]}",
                                           "params[:find_id]=#{params[:find_id]}",
                                           "params[:find_user_id]=#{params[:find_user_id]}",
                                           "" ] if debug_verbose

    @id = params[:id]
    @id_deleted = false
    @id_invalid = false
    @id_msg = ''
    id_check
    log_entries_refresh
    @find_id = params[:find_id]
    @find_id ||= @id
    @presenter = presenter_class.new( controller: self )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> Show -- About to render <<<",
                                           "begin_date=#{begin_date}",
                                           "" ] if debug_verbose
    render 'provenance_log/provenance_log'
  end

  def deleted_works
    debug_verbose = provenance_log_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if debug_verbose
    runner = ::Deepblue::DeletedWorksFromLog.new( input: ::Deepblue::ProvenanceLogService.provenance_log_path )
    runner.run
    @deleted_ids = runner.deleted_ids
    @deleted_id_to_key_values_map = runner.deleted_id_to_key_values_map
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "deleted_ids=#{deleted_ids}",
    #                                        "deleted_id_to_key_values_map=#{deleted_id_to_key_values_map}",
    #                                        "" ] if provenance_log_controller_debug_verbose
    @presenter = presenter_class.new( controller: self )
    render 'provenance_log/provenance_log'
  end

  def find
    debug_verbose = provenance_log_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    begin_end_date_init_from_parms( debug_verbose: debug_verbose )
    @find_id = params[:find_id]
    @find_user_id = params[:find_user_id]
    @id = find_id
    @id_deleted = false
    @id_invalid = false
    @id_msg = ''
    id_check
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> Find <<<",
                                           "find_id=#{find_id}",
                                           "id=#{id}",
                                           "" ] if debug_verbose
    log_entries_refresh
    @presenter = presenter_class.new( controller: self )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> Find -- About to render <<<",
                                           "begin_date=#{begin_date}",
                                           "" ] if debug_verbose
    render 'provenance_log/provenance_log'
  end

  def id_check
    return if id.blank?
    ::PersistHelper.find( id )
  rescue Ldp::Gone => g
    @id_msg = "deleted"
    @id_deleted = true
  rescue Hyrax::ObjectNotFoundError => e2
    @id_msg = "invalid"
    @id_invalid = true
  rescue ::ActiveFedora::ObjectNotFoundError => e3
    @id_msg = "invalid"
    @id_invalid = true
  end

  def id_valid?
    return false if id.blank?
    return false if ( id_deleted || id_invalid )
    true
  end

  def log_entries
    @log_entries ||= log_entries_init
  end

  def log_entries_init
    debug_verbose = provenance_log_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "" ] if debug_verbose
    return nil unless ( id_valid? || id_deleted )
    rv = ::Deepblue::ProvenanceLogService.entries( id, debug_verbose: debug_verbose )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "rv&.size=#{rv&.size}",
                                           "" ] if debug_verbose
    return rv
  end

  def log_entries_refresh
    debug_verbose = provenance_log_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "" ] if debug_verbose
    return nil unless ( id_valid? || id_deleted )
    rv = provenance_log_entries_refresh( id: id,
                                         begin_date: begin_date,
                                         end_date: end_date,
                                         debug_verbose: debug_verbose )
    return rv unless rv.present?
    @log_entries = rv
    set_begin_end_dates_from_provenance_log_entries if params_begin_date.blank? || params_end_date.blank?
    return rv
  end

  def log_zip_download
    debug_verbose = provenance_log_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    require 'zip'
    require 'tempfile'

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if provenance_log_controller_debug_verbose

    tmp_dir = ENV['TMPDIR'] || "/tmp"
    tmp_dir = Pathname.new tmp_dir
    ::Deepblue::LoggingHelper.bold_debug [ "zip_log_download begin", "tmp_dir=#{tmp_dir}" ] if debug_verbose

    target_dir = tmp_dir
    ::Deepblue::LoggingHelper.bold_debug [ "zip_log_download", "target_dir=#{target_dir}" ] if debug_verbose
    Dir.mkdir( target_dir ) unless Dir.exist?( target_dir )
    base_file_name = "provenance_#{Rails.env}.log"
    src_file_name = Pathname.new Rails.root.join( 'log', base_file_name )
    target_zipfile = target_dir.join "#{base_file_name}.zip"
    ::Deepblue::LoggingHelper.bold_debug [ "zip_log_download", "target_zipfile=#{target_zipfile}" ] if debug_verbose
    File.delete target_zipfile if File.exist? target_zipfile
    ::Deepblue::LoggingHelper.debug "Download Zip begin copy to folder #{target_dir}"
    ::Deepblue::LoggingHelper.bold_debug [ "zip_log_download", "begin zip of src_file_name=#{src_file_name}" ] if debug_verbose
    Zip::File.open( target_zipfile.to_s, Zip::File::CREATE ) do |zipfile|
      zipfile.add( base_file_name, src_file_name )
    end
    ::Deepblue::LoggingHelper.bold_debug [ "zip_log_download", "download complete target_dir=#{target_dir}" ] if debug_verbose
    send_file target_zipfile.to_s
  end

  def set_begin_end_dates_from_provenance_log_entries
    return if params_begin_date.present? || params_end_date.present?
    set_begin_end_dates_from( entries: log_entries )
  end

  def set_begin_end_dates_from( entries: )
    debug_verbose = provenance_log_controller_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "entries&.size=#{entries&.size}",
                                           "" ] if debug_verbose
    return if entries.blank?
    first_entry = entries.first
    last_entry = entries.last
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "first_entry=#{first_entry}",
                                           "first_entry.class.name=#{first_entry.class.name}",
                                           "last_entry=#{last_entry}",
                                           "last_entry.class.name=#{last_entry.class.name}",
                                           "" ] if debug_verbose
    if first_entry.present? && begin_date.blank?
      t = ::Deepblue::ProvenanceLogService.timestamp( entry: first_entry )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "first_entry timestamp=#{t}",
                                             "" ] if debug_verbose
      @begin_date = t
    end
    if last_entry.present? && end_date.blank?
      t = ::Deepblue::ProvenanceLogService.timestamp( entry: last_entry )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "last_entry timestamp=#{t}",
                                             "" ] if debug_verbose
      @end_date = t
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "begin_date=#{begin_date}",
                                           "end_date=#{end_date}",
                                           "" ] if debug_verbose
  end

  def works_by_user_id
    debug_verbose = provenance_log_controller_debug_verbose
    raise CanCan::AccessDenied unless current_ability.admin?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           ">>> Works by User ID <<<",
                                           "params[:find_user_id]=#{params[:find_user_id]}",
                                           "" ] if debug_verbose
    show_works_by_user_id
  end

  def show_works_by_user_id
    debug_verbose = provenance_log_controller_debug_verbose
    begin_end_date_init_from_parms( debug_verbose: debug_verbose )
    email = params[:find_user_id]
    email ||= current_user.email.to_s
    email = "#{email}@umich.edu" unless email.index( '@' ).present?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "email=#{email}",
                                           "" ] if debug_verbose
    # TODO: add a date range filter if begin end dates are set
    if begin_date.present? && end_date.present?
      filter = ::Deepblue::DateLogFilter.new( begin_timestamp: begin_date, end_timestamp: end_date )
      runner = ::Deepblue::WorksByUserIdWorksFromLog.new( email: email,
                                                          filter: filter,
                                                          input: ::Deepblue::ProvenanceLogService.provenance_log_path,
                                                          options: { max_lines_extracted: -1 } )
    else
      runner = ::Deepblue::WorksByUserIdWorksFromLog.new( email: email,
                                                          input: ::Deepblue::ProvenanceLogService.provenance_log_path,
                                                          options: { max_lines_extracted: -1 } )
    end
    runner.run
    @works_by_user_id_ids = runner.works_by_user_id_ids
    @works_by_user_id_to_key_values_map = runner.works_by_user_id_to_key_values_map
    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "works_by_user_id_ids=#{works_by_user_id_ids}",
    #                                        "works_by_user_id_to_key_values_map=#{works_by_user_id_to_key_values_map}",
    #                                        "" ] if provenance_log_controller_debug_verbose
    set_begin_end_dates_from( entries: runner.lines_extracted ) if params_begin_date.blank? || params_end_date.blank?
    @presenter = presenter_class.new( controller: self )
    render 'provenance_log/provenance_log'
  end

end
