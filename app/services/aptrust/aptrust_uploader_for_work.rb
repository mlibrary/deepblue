# frozen_string_literal: true

require_relative './aptrust'
require_relative './aptrust_config'

class Aptrust::WorkTasks

  def self.upload( noid:,
                   note:                    nil,
                   bag_max_file_size:       nil,
                   bag_max_total_file_size: nil,
                   cleanup_after_deposit:   true,
                   cleanup_bag:             true,
                   cleanup_bag_data:        true,
                   multibag_parts_included: [],
                   track_status:            true,
                   zip_data_dir:            false,
                   debug_verbose:           false )

    puts note unless note.nil?
    msg_handler = ::Deepblue::MessageHandler.msg_handler_for( task: true, debug_verbose: debug_verbose )
    uploader = ::Aptrust::AptrustUploadWork.new( msg_handler:             msg_handler,
                                                 debug_verbose:           debug_verbose,
                                                 bag_max_file_size:       bag_max_file_size,
                                                 bag_max_total_file_size: bag_max_total_file_size,
                                                 cleanup_after_deposit:   cleanup_after_deposit,
                                                 cleanup_bag:             cleanup_bag,
                                                 cleanup_bag_data:        cleanup_bag_data,
                                                 multibag_parts_included: multibag_parts_included,
                                                 noid:                    noid,
                                                 track_status:            track_status,
                                                 zip_data_dir:            zip_data_dir )
    uploader.run;true
  end

end

class Aptrust::AptrustUploaderForWork < Aptrust::AptrustUploader

  mattr_accessor :aptrust_uploader_for_work_debug_verbose, default: false

  mattr_accessor :the_deposit_context,     default: ::Aptrust::AptrustIntegrationService.deposit_context
  mattr_accessor :local_repository,        default: ::Aptrust::AptrustIntegrationService.local_repository
  mattr_accessor :bag_description,         default: ::Aptrust::AptrustIntegrationService.dbd_bag_description
  mattr_accessor :validate_file_checksums, default: ::Aptrust::AptrustIntegrationService.dbd_validate_file_checksums

  def self.bag_id_init()
    return Aptrust.aptrust_identifier( template: bag_id_template,
                                       local_repository: bag_id_local_repository,
                                       context: bag_id_context,
                                       type: bag_id_type,
                                       noid: object_id )
  end

  def self.cleanup_for_work( noid:,
                             export_dir:    ::Aptrust::AptrustUploaderForWork.dbd_working_dir,
                             working_dir:   ::Aptrust::AptrustUploaderForWork.dbd_working_dir,
                             msg_handler:   ::Aptrust::NULL_MSG_HANDLER,
                             debug_verbose: aptrust_uploader_for_work_debug_verbose )

    aptrust_config = ::Aptrust::AptrustConfig.new
    bag_id_type = ::Aptrust::AptrustUploaderForWork.dbd_bag_id_type( work: nil )
    bag_id = Aptrust.aptrust_identifier( template: ::Aptrust::IDENTIFIER_TEMPLATE,
                                         local_repository: aptrust_config.local_repository,
                                         context: bag_id_context,
                                         type: bag_id_type,
                                         noid: noid )
    bag_dir = File.join( working_dir, bag_id )

    ::Aptrust::AptrustUploader.cleanup_tar_file( bag_dir: bag_dir,
                                                 export_dir: export_dir,
                                                 msg_handler: msg_handler,
                                                 debug_verbose: debug_verbose )

    ::Aptrust::AptrustUploader.cleanup_bag_dir( bag_dir: bag_dir,
                                                msg_handler: msg_handler,
                                                debug_verbose: debug_verbose )

  end

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
    rv = File.absolute_path rv
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
    rv = File.absolute_path rv
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

  @deposit_files = nil

  def initialize( aptrust_config:               nil,
                  bag_max_file_size:            nil,
                  bag_max_total_file_size:      nil,
                  cleanup_after_deposit:        ::Aptrust::AptrustUploader.cleanup_after_deposit,
                  cleanup_bag:                  ::Aptrust::AptrustUploader.cleanup_bag,
                  cleanup_bag_data:             ::Aptrust::AptrustUploader.cleanup_bag_data,
                  clear_status:                 ::Aptrust::AptrustUploader.clear_status,
                  event_start:                   nil,
                  event_stop:                    nil,
                  export_file_sets:              true,
                  export_file_sets_filter_date:  nil,
                  export_file_sets_filter_event: nil,
                  multibag_parts_included:       [],
                  track_status:                  true,
                  work:                          nil,
                  msg_handler:                   nil,
                  zip_data_dir:                  false,
                  debug_verbose:                 aptrust_uploader_for_work_debug_verbose )

    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "aptrust_config=#{aptrust_config}",
                             "bag_max_file_size=#{bag_max_file_size}",
                             "bag_max_total_file_size=#{bag_max_total_file_size}",
                             "cleanup_after_deposit=#{cleanup_after_deposit}",
                             "cleanup_bag=#{cleanup_bag}",
                             "cleanup_bag_data=#{cleanup_bag_data}",
                             "clear_status=#{clear_status}",
                             "export_file_sets=#{export_file_sets}",
                             "export_file_sets_filter_date=#{export_file_sets_filter_date}",
                             "export_file_sets_filter_event=#{export_file_sets_filter_event}",
                             "multibag_parts_included=#{multibag_parts_included}",
                             "track_status=#{track_status}",
                             "work=#{work}",
                             "zip_data_dir=#{zip_data_dir}",
                             "" ] if msg_handler.present? && debug_verbose
    bag_id_type = ::Aptrust::AptrustUploaderForWork.dbd_bag_id_type( work: work )
    aptrust_info = ::Aptrust::AptrustInfoFromWork.new( work: work, aptrust_config: aptrust_config )
    export_dir = ::Aptrust::AptrustUploaderForWork.dbd_export_dir
    working_dir = ::Aptrust::AptrustUploaderForWork.dbd_working_dir
    bi_description = ::Aptrust::AptrustUploaderForWork.dbd_bag_description( work: work )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "object_id=#{work.id}",
                             "aptrust_info=#{aptrust_info.pretty_inspect}",
                             "bag_id_type=#{bag_id_type}",
                             "the_deposit_context=#{the_deposit_context}",
                             "export_dir=#{export_dir}",
                             "working_dir=#{working_dir}",
                             "bi_description=#{bi_description}",
                             "" ] if msg_handler.present? && debug_verbose
    super( object_id:                     work.id,
           msg_handler:                   msg_handler,
           debug_verbose:                 debug_verbose,
           aptrust_info:                  aptrust_info,
           bag_id_type:                   bag_id_type,
           bag_id_context:                the_deposit_context,
           bag_max_file_size:             bag_max_file_size,
           bag_max_total_file_size:       bag_max_total_file_size,
           cleanup_after_deposit:         cleanup_after_deposit,
           cleanup_bag:                   cleanup_bag,
           cleanup_bag_data:              cleanup_bag_data,
           clear_status:                  clear_status,
           event_start:                   event_start,
           event_stop:                    event_stop,
           export_dir:                    export_dir,
           export_file_sets:              export_file_sets,
           export_file_sets_filter_date:  export_file_sets_filter_date,
           export_file_sets_filter_event: export_file_sets_filter_event,
           multibag_parts_included:       multibag_parts_included,
           working_dir:                   working_dir,
           bi_description:                bi_description,
           track_status:                  track_status,
           zip_data_dir:                  zip_data_dir )

    @work = work
    @export_by_closure = ->(target_dir, files) { export_data_work( target_dir: target_dir, files: files ) }
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

  def deposit_files
    @deposit_files ||= deposit_files_init()
    return @deposit_files
  end

  def deposit_files_init
    files = ::Aptrust::AptrustFileSetList.new() # ( debug: aptrust_upload_work_debug_verbose )
    files.add_all( file_sets: work.file_sets )
    msg_handler.msg_debug "deposit_files_init:"
    need_to_split = false
    msg_handler.msg_debug "bag_max_file_size: #{DeepblueHelper.human_readable_size_str(bag_max_file_size ) }"
    files.entries.each do |f|
      next unless f.size > bag_max_file_size
      msg_handler.msg_debug "split: #{f.id} - #{DeepblueHelper.human_readable_size_str( f.size ) }"
      need_to_split = true
      break
    end
    return files unless need_to_split
    files_with_splits = ::Aptrust::AptrustFileSetList.new()
    files.entries.each do |f|
      if f.size <= bag_max_file_size
        files_with_splits.add( file_set: f )
        next
      end
      msg_handler.msg_debug "split: #{f.id} - #{DeepblueHelper.human_readable_size_str( f.size ) }"
      split_size = (f.size / 10).to_int
      (0..9).each do |i|
        split_id = "#{f.id}_#{i}"
        split_name = "#{f.name}.#{i}"
        files_with_splits.add_split( id: split_id,
                                     id_orig: f.id,
                                     name: split_name,
                                     name_orig: f.name,
                                     size: split_size )
      end
      if msg_handler.debug_verbose
        files_with_splits.entries.each do |f|
          msg_handler.msg_debug "split: #{f.id} - #{f.name} - #{DeepblueHelper.human_readable_size_str( f.size ) }"
        end
      end
    end
    # return files
    files.clear
    return files_with_splits
  end

  def desposit_files_total_size()
    return deposit_files().total_file_sets_size
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

  def export_data_by_closure( data_dir, files )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "data_dir=#{data_dir}" ] if debug_verbose
    return if export_by_closure.nil?
    errors = []
    if files.is_a? Array
      file_set_ids = files
    elsif files.is_a? ::Aptrust::AptrustFileSetList
      file_set_ids = []
      files.entries.each do |f|
        if 0 == f.size
          errors << "#{f.id} file size is zero."
        end
        if f.split
          msg_handler.msg_debug "exclude export as split: #{f.id}"
        else
          file_set_ids << f.id
        end
      end
    else
      file_set_ids = []
    end
    if errors.present?
      export_failed( status: ::Aptrust::EVENT_EXPORT_FAILED, note: errors )
      return
    end
    super( data_dir, file_set_ids )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "data_dir=#{data_dir}" ] if debug_verbose
    if files.is_a? ::Aptrust::AptrustFileSetList
      files.entries.each do |f|
        if f.split
          msg_handler.msg_debug "Export as split: #{f.id}, orig_id=#{f.id_orig}, name_orig=#{f.name_orig}"
          data_dir_file = File.join data_dir, f.name
          msg_handler.msg_debug "data_dir_file: #{data_dir_file} -- exists? #{File.exist? data_dir_file}"
          next if File.exist? data_dir_file
          work_dir = File.dirname data_dir # bag directory
          msg_handler.msg_debug "work_dir: #{work_dir} -- exists? #{Dir.exist? work_dir}"
          work_dir = File.dirname work_dir # parent of bag directory
          msg_handler.msg_debug "work_dir: #{work_dir} -- exists? #{Dir.exist? work_dir}"
          split_dir = File.join work_dir, f.id_orig
          msg_handler.msg_debug "split_dir: #{split_dir} -- exists? #{Dir.exist? split_dir}"
          Dir.mkdir split_dir unless Dir.exist? split_dir
          split_name = "#{f.id_orig}_#{f.name}"
          split_file = File.join split_dir, split_name
          msg_handler.msg_debug "split_file: #{split_file} -- exists? #{File.exist? split_file}"
          if File.exist? split_file
            msg_handler.msg_debug "moving existing split file to data dir"
            FileUtils.mv( split_file, data_dir )
            next
          end
          msg_handler.msg_debug "split_dir: #{split_dir} -- exists? #{Dir.exist? split_dir}"
          files = [ f.id_orig ]
          export_data_work( target_dir: split_dir, files: files, split_export: true )
          unsplit_name = "#{f.id_orig}_#{f.name_orig}"
          unsplit_file = File.join split_dir, unsplit_name
          msg_handler.msg_debug "non_split_file: #{unsplit_file} -- exists? #{File.exist? unsplit_file}"
          export_split( file: unsplit_file )
          if msg_handler.debug_verbose
            split_files = export_split_file_names( file: unsplit_file )
            split_files.each do |file|
              file = File.join split_dir, file
              msg_handler.msg_debug "split_file: #{file} -- exists? #{File.exist? file}"
            end
          end
          msg_handler.msg_debug "moving new split file to data dir"
          msg_handler.msg_debug "mv #{split_file}"
          msg_handler.msg_debug "to #{data_dir}"
          FileUtils.mv( split_file, data_dir )
        end
      end
    end
  end

  def export_data_resolve_error( error )
    super
    email_error( error ) if error.is_a? ::Deepblue::ExportFilesChecksumMismatch
  end

  def export_data_work( target_dir:, files:, split_export: false )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "target_dir=#{target_dir}" ] if debug_verbose
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "files=#{files.pretty_inspect}" ] if debug_verbose
    msg_handler.msg_debug [ msg_handler.here, msg_handler.called_from, "target_dir=#{target_dir}" ] if debug_verbose
    msg_handler.msg_debug [ msg_handler.here, msg_handler.called_from, "files=#{files.pretty_inspect}" ] if debug_verbose
    path = Pathname.new target_dir
    if files.blank?
      export_work_files( target_dir: path )
    else
      export_work_file_sets( target_dir: path, files: files, split_export: split_export )
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
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
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "target_dir=#{target_dir}" ] if debug_verbose
    work.metadata_report( dir: target_dir, filename_pre: 'w_' )
    export_file_sets_filter_date = export_file_sets_filter_date_init
    verbose = msg_handler.verbose
    msg_handler.verbose = false unless debug_verbose
    pop = ::Deepblue::YamlPopulate.new( populate_type: 'work',
                                        msg_handler: msg_handler,
                                        options: { verbose:                  false,
                                                   mode:                     'bag',
                                                   collect_exported_file_set_files: true,
                                                   export_files:              export_file_sets,
                                                   export_files_newer_than_date: export_file_sets_filter_date,
                                                   target_dir:                target_dir,
                                                   validate_file_checksums:   validate_file_checksums,
                                                   debug_verbose:             debug_verbose } )
    service = pop.yaml_bag_work( id: work.id, work: work )
    msg_handler.verbose = verbose
    @exported_file_set_files = service.exported_file_set_files
    @export_errors = service.errors
    # export provenance log
    entries = ::Deepblue::ProvenanceLogService.entries( work.id, refresh: true )
    prov_file = File.join( target_dir, "w_#{work.id}_provenance.log" )
    ::Deepblue::ProvenanceLogService.write_entries( prov_file, entries )
  end

  def export_work_file_sets( target_dir:, files:, split_export: false )
    msg_handler.msg_debug [ msg_handler.here, msg_handler.called_from,
                              "target_dir=#{target_dir}",
                              "files=#{files.pretty_inspect}",
                              "split_export=#{split_export}" ]
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "target_dir=#{target_dir}",
                             "files=#{files.pretty_inspect}",
                             "split_export=#{split_export}" ] if debug_verbose
    unless split_export
      msg_handler.msg_debug "export provenance log"
      work.metadata_report( dir: target_dir, filename_pre: 'w_' )
    end
    export_file_sets_filter_date = export_file_sets_filter_date_init
    export_includes_callback = ->(file_set) do
      msg_handler.msg_debug "export_includes_callback file_set.id #{file_set.id}"
      rv = files.include? file_set.id
    end
    verbose = msg_handler.verbose
    msg_handler.verbose = false unless debug_verbose
    pop = ::Deepblue::YamlPopulate.new( populate_type: 'work',
                                        msg_handler: msg_handler,
                                        options: { mode:                     'bag',
                                                   collect_exported_file_set_files: true,
                                                   export_files:              export_file_sets,
                                                   export_files_newer_than_date: export_file_sets_filter_date,
                                                   target_dir:                target_dir,
                                                   validate_file_checksums:   validate_file_checksums,
                                                   export_includes_callback:  export_includes_callback,
                                                   debug_verbose:             debug_verbose } )
    service = pop.yaml_bag_work( id: work.id, work: work )
    msg_handler.verbose = verbose
    unless split_export
      # TODO: need to deal with when split exporting
      @exported_file_set_files = service.exported_file_set_files
      @export_errors = service.errors
    end
    unless split_export
      msg_handler.msg_debug "export provenance log"
      entries = ::Deepblue::ProvenanceLogService.entries( work.id, refresh: true )
      prov_file = File.join( target_dir, "w_#{work.id}_provenance.log" )
      ::Deepblue::ProvenanceLogService.write_entries( prov_file, entries )
    end
    msg_handler.msg_debug [ msg_handler.here, msg_handler.called_from, "exiting" ]
  end

  def exported_files()
    return exported_file_set_files
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
