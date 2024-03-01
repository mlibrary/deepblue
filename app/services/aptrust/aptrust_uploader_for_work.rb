# frozen_string_literal: true

require_relative './aptrust'
require_relative './aptrust_config'

class Aptrust::AptrustUploaderForWork < Aptrust::AptrustUploader

  mattr_accessor :aptrust_uploader_for_work_debug_verbose, default: false

  mattr_accessor :deposit_context,  default: ::Aptrust::AptrustIntegrationService.deposit_context
  mattr_accessor :local_repository, default: ::Aptrust::AptrustIntegrationService.local_repository
  mattr_accessor :bag_description,  default: ::Aptrust::AptrustIntegrationService.dbd_bag_description

  def self.dbd_bag_description( work: )
    # "Bag of a #{work.class.name} hosted at deepblue.lib.umich.edu/data/"
    description = bag_description.dup
    description.gsub!( '%work_type%', work.class.name )
    description.gsub!( '%hostname%', "#{Rails.configuration.hostname}/data/" )
    return description
  end

  def self.dbd_bag_id_type( work: )
    return 'DataSet.' if work.blank?
    return "#{work.model_name.name}."
  end

  def self.dbd_export_dir
    hostname = dbd_hostname_short
    rv = ::Aptrust::AptrustIntegrationService.export_dir
    if rv.blank? && 'local' == hostname
      rv = './data/aptrust_export/'
    elsif rv.blank?
      rv = '/deepbluedata-prep/aptrust_export/'
    end
    Dir.mkdir( rv ) unless Dir.exist? rv
    return rv
  end

  def self.dbd_hostname_short( hostname: nil )
    hostname ||= Rails.configuration.hostname
    return 'local' if hostname =~ /local/
    "".index( "." )
    index = hostname.index( "." )
    return hostname[0..(index-1)] if index && index > 1
    return hostname
  end

  def self.dbd_working_dir
    hostname = dbd_hostname_short
    rv = ::Aptrust::AptrustIntegrationService.working_dir
    if rv.blank? && 'local' == hostname
      rv = './data/aptrust_work/'
    elsif rv.blank?
      rv = rv.blank? && '/deepbluedata-prep/aptrust_work/'
    end
    Dir.mkdir( rv ) unless Dir.exist? rv
    return rv
  end

  def self.init_id( id: nil, work: nil )
    return id if id.present?
    return work.id
  end

  def self.init_work( id: nil, work: nil )
    return work if work.present?
    rv = DataSet.find id
    return rv
  end

  attr_accessor :work
  attr_accessor :exported_file_set_files

  def initialize( aptrust_config: nil,
                  cleanup_after_deposit:        ::Aptrust::AptrustUploader.cleanup_after_deposit,
                  cleanup_before_deposit:       ::Aptrust::AptrustUploader.cleanup_before_deposit,
                  cleanup_bag:                  ::Aptrust::AptrustUploader.cleanup_bag,
                  cleanup_bag_data:             ::Aptrust::AptrustUploader.cleanup_bag_data,
                  clear_status:                 ::Aptrust::AptrustUploader.clear_status,
                  export_file_sets:              true,
                  export_file_sets_filter_date:  nil,
                  export_file_sets_filter_event: nil,
                  work:                          nil,
                  msg_handler:                   nil,
                  debug_verbose:                 aptrust_uploader_for_work_debug_verbose )

    bag_id_type = ::Aptrust::AptrustUploaderForWork.dbd_bag_id_type( work: work )
    super( object_id:                     work.id,
           msg_handler:                   msg_handler,
           debug_verbose:                 debug_verbose,
           aptrust_info:                  ::Aptrust::AptrustInfoFromWork.new( work: work, aptrust_config: aptrust_config ),
           bag_id_type:                   bag_id_type,
           cleanup_after_deposit:         cleanup_after_deposit,
           cleanup_before_deposit:        cleanup_before_deposit,
           cleanup_bag:                   cleanup_bag,
           cleanup_bag_data:              cleanup_bag_data,
           clear_status:                  clear_status,
           export_dir:                    ::Aptrust::AptrustUploaderForWork.dbd_export_dir,
           export_file_sets:              export_file_sets,
           export_file_sets_filter_date:  export_file_sets_filter_date,
           export_file_sets_filter_event: export_file_sets_filter_event,
           working_dir:                   ::Aptrust::AptrustUploaderForWork.dbd_working_dir,
           bi_description:                ::Aptrust::AptrustUploaderForWork.dbd_bag_description( work: work ) )

    @work = work
    @export_by_closure = ->(target_dir) { export_data_work( target_dir: target_dir ) }
  end

  def allow_deposit?
    super # TODO: check size
    # return false unless monograph.is_a?(Sighrax::Monograph)
  end

  def aptrust_info_work
    @aptrust_info ||= ::Aptrust::AptrustInfoFromWork.new( work:             work,
                                                          aptrust_config:   aptrust_config,
                                                          access:           ai_access,
                                                          creator:          ai_creator,
                                                          description:      ai_description,
                                                          item_description: ai_item_description,
                                                          storage_option:   ai_storage_option,
                                                          title:            ai_title ).build
  end

  def aptrust_info_work_write
    aptrust_info_work
    aptrust_info_write( aptrust_info: aptrust_info )
  end

  def cleanup_bag_data_files
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_bag_data=#{cleanup_bag_data}",
                             "" ] if debug_verbose
    return [] unless cleanup_bag_data
    return [] unless Dir.exist? bag.bag_dir
    files = exported_file_set_files
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "exported_file_set_files.size=#{exported_file_set_files.size}" ] if debug_verbose
    return files
  end

  def export_do_copy?( target_dir, target_file_name ) # TODO: check file size?
    prep_file_name = target_file_name( target_dir, target_file_name )
    do_copy = true
    if File.exist? prep_file_name
      #::Deepblue::LoggingHelper.debug "skipping copy because #{prep_file_name} already exists"
      do_copy = false
    end
    do_copy
  end

  def target_file_name( dir, filename, ext = '' ) # TODO: review
    return Pathname.new( filename + ext ) if dir.nil?
    if dir.is_a? String
      rv = File.join dir, filename + ext
    else
      rv = dir.join( filename + ext )
    end
    return rv
  end

  def export_work_files( target_dir: )
    work.metadata_report( dir: target_dir, filename_pre: 'w_' )
    export_file_sets_filter_date = export_file_sets_filter_date_init
    pop = ::Deepblue::YamlPopulate.new( populate_type: 'work',
                                        options: { mode:                     'bag',
                                                   export_files:              export_file_sets,
                                                   export_files_filter_date:  export_file_sets_filter_date,
                                                   target_dir:                target_dir } )
    @exported_file_set_files = pop.yaml_bag_work( id: work.id, work: work )
    # export provenance log
    entries = ::Deepblue::ProvenanceLogService.entries( work.id, refresh: true )
    prov_file = File.join( target_dir, "w_#{work.id}_provenance.log" )
    ::Deepblue::ProvenanceLogService.write_entries( prov_file, entries )
  end

  def export_file_sets_filter_date_init
    return export_file_sets_filter_date if export_file_sets_filter_date.present?
    return nil if export_file_sets_filter_event
    records = ::Aptrust::Event.for_most_recent_event( noid: work.id, event: export_file_sets_filter_event )
    record = Array( records ).first
    return nil unless record.present?
    return record.updated_at
  end

  def export_work_files2( target_dir: )
    work.metadata_report( dir: target_dir, filename_pre: 'w_' )
    # TODO: import script?
    # TODO: work.import_script( dir: target_dir )
    file_sets = work.file_sets
    do_copy_predicate = ->(target_file_name, _target_file) { export_do_copy?( target_dir, target_file_name ) }
    ::Deepblue::ExportFilesHelper.export_file_sets( target_dir: target_dir,
                                                    file_sets: file_sets,
                                                    log_prefix: '',
                                                    do_export_predicate: do_copy_predicate ) do |target_file_name, target_file|
    end
  end

  def export_data_work( target_dir: )
    path = Pathname.new target_dir
    export_work_files( target_dir: path )
  end

end
