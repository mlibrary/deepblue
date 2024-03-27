# frozen_string_literal: true

require_relative './aptrust'
require_relative './aptrust_config'

class Aptrust::AptrustUploaderForWork < Aptrust::AptrustUploader

  mattr_accessor :aptrust_uploader_for_work_debug_verbose, default: false

  mattr_accessor :deposit_context,  default: ::Aptrust::AptrustIntegrationService.deposit_context
  mattr_accessor :local_repository, default: ::Aptrust::AptrustIntegrationService.local_repository
  mattr_accessor :bag_description,  default: ::Aptrust::AptrustIntegrationService.dbd_bag_description
  mattr_accessor :validate_file_checksums, default: ::Aptrust::AptrustIntegrationService.dbd_validate_file_checksums

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
                  bag_max_total_file_size:      nil,
                  cleanup_after_deposit:        ::Aptrust::AptrustUploader.cleanup_after_deposit,
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
           bag_id_context:                deposit_context,
           bag_max_total_file_size:       bag_max_total_file_size,
           cleanup_after_deposit:         cleanup_after_deposit,
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

  def aptrust_info_work_write( bag: )
    aptrust_info_work
    aptrust_info_write( bag: bag, aptrust_info: aptrust_info )
  end

  def cleanup_bag_data_files( bag: )
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

  def email_error( error )
    # error is assumed to be an instance of ::Deepblue::ExportFilesChecksumMismatch at this point
    targets = [ 'fritx@umich.edu' ]
    task_name = self.class.name
    task_args = nil
    exception = error
    event_note = error&.message
    event = error.class.name.demodulize
    timestamp_begin = DateTime.now
    timestamp_end = timestamp_begin
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "targets=#{targets}",
                             "task_name=#{task_name}",
                             "task_args=#{task_args}",
                             # "msg_handler.msg_queue=#{msg_handler.msg_queue}",
                             "" ] if msg_handler.debug_verbose
    ::Deepblue::JobTaskHelper.email_failure( targets: targets,
                                             task_name: task_name,
                                             task_args: task_args,
                                             exception: exception,
                                             event: event,
                                             event_note: event_note,
                                             timestamp_begin: timestamp_begin,
                                             timestamp_end: timestamp_end,
                                             msg_handler: nil,
                                             debug_verbose: msg_handler.debug_verbose )
  end

  def export_data_resolve_error( error )
    super
    email_error( error ) if error.is_a? ::Deepblue::ExportFilesChecksumMismatch
  end

  def export_data_work( target_dir: )
    path = Pathname.new target_dir
    export_work_files( target_dir: path )
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

  def export_file_sets_filter_date_init
    return export_file_sets_filter_date if export_file_sets_filter_date.present?
    return nil if export_file_sets_filter_event
    records = ::Aptrust::Event.for_most_recent_event( noid: work.id, event: export_file_sets_filter_event )
    record = Array( records ).first
    return nil unless record.present?
    return record.updated_at
  end

  def export_work_files( target_dir: )
    work.metadata_report( dir: target_dir, filename_pre: 'w_' )
    export_file_sets_filter_date = export_file_sets_filter_date_init
    pop = ::Deepblue::YamlPopulate.new( populate_type: 'work',
                                        options: { mode:                     'bag',
                                                   collect_exported_file_set_files: true,
                                                   export_files:              export_file_sets,
                                                   export_files_filter_date:  export_file_sets_filter_date,
                                                   target_dir:                target_dir,
                                                   validate_file_checksums:   validate_file_checksums,
                                                   debug_verbose:             debug_verbose } )
    service = pop.yaml_bag_work( id: work.id, work: work )
    @exported_file_set_files = service.exported_file_set_files
    @export_errors = service.errors
    # export provenance log
    entries = ::Deepblue::ProvenanceLogService.entries( work.id, refresh: true )
    prov_file = File.join( target_dir, "w_#{work.id}_provenance.log" )
    ::Deepblue::ProvenanceLogService.write_entries( prov_file, entries )
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

end
