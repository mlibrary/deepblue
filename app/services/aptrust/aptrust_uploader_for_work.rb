# frozen_string_literal: true

require_relative './aptrust'

module Aptrust

  class AptrustUploaderForWork < AptrustUploader

    mattr_accessor :aptrust_service_allow_deposit,      default: true
    mattr_accessor :aptrust_service_deposit_context,    default: '' # none for DBD
    mattr_accessor :aptrust_service_deposit_repository, default: 'deepbluedata'

    def self.dbd_bag_description( work: )
      "Bag of a #{work.class.name} hosted at deepblue.lib.umich.edu/data/" # TODO: improve this, or move to config
    end

    def self.dbd_export_dir
      hostname = dbd_hostname_short
      if 'local' == hostname
        rv = './data/aptrust_export/'
      else
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
      if 'local' == hostname
        rv = './data/aptrust_work/'
      else
        rv = '/deepbluedata-prep/aptrust_work/'
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

    def initialize( work: nil, msg_handler: nil )
      super( object_id:          work.id,
             msg_handler:        msg_handler,
             aptrust_info:       AptrustInfoFromWork.new( work: work ),
             #bag_id_context:     aptrust_service_deposit_context,
             #bag_id_repository:  aptrust_service_deposit_repository,
             bag_id_type:        'DataSet.',
             export_dir:         AptrustUploaderForWork.dbd_export_dir,
             working_dir:        AptrustUploaderForWork.dbd_working_dir,
             bi_description:     AptrustUploaderForWork.dbd_bag_description( work: work ) )
      @work = work
      @export_by_closure = ->(target_dir) { export_data_work( target_dir: target_dir ) }
    end

    def allow_deposit?
      return ALLOW_DEPOSIT # TODO: check size
      # return false unless monograph.is_a?(Sighrax::Monograph)
    end

    def aptrust_info_work
      @aptrust_info ||= AptrustInfoFromWork.new( work:             work,
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
      pop = ::Deepblue::YamlPopulate.new( populate_type: 'work',
                                          options: { mode: 'bag',
                                                     target_dir: target_dir,
                                                     export_files: true } )
      pop.yaml_bag_work( id: work.id, work: work )
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

    # def bag_export_work()
    #   track_deposit( status: 'bagging' )
    #   working_dir ||= dir_working
    #   target_dir = File.join( working_dir, bag_id )
    #   Dir.mkdir( target_dir ) unless Dir.exist? target_dir
    #   @bag = BagIt::Bag.new( target_dir )
    #   bag.write_bag_info( bag_info ) # Create bagit-info.txt file
    #   aptrust_info_work_write
    #   export_data_work( target_dir: bag_data_dir )
    #   bag_manifest
    #   track_deposit( status: 'bagged', note: "target_dir: #{target_dir}" )
    #   target_dir
    # end

    # def deposit_work()
    #   unless allow_deposit?
    #     track_deposit( status: 'skipped' )
    #     return
    #   end
    #   begin
    #     track_deposit( status: 'depositing' )
    #     work_dir = bag_export
    #     tar_file = tar( dir: work_dir, id: object_id, status_history: status_history )
    #     export_dir = dir_export
    #     export_tar_file = File.join( export_dir, File.basename( tar_file ) )
    #     FileUtils.mv( tar_file, export_tar_file )
    #     # TODO: delete untarred files
    #     #deposit( filename: export_tar_file, id: object_id, status_history: status_history )
    #   rescue StandardError => e
    #     ::Deepblue::LoggingHelper.bold_error ["AptrustService.perform_deposit(#{object_id}) error #{e}"] + e.backtrace[0..20]
    #     #track( id: object_id, status: 'failed', status_history: status_history, note: "failed in #{e.context} with error #{e}" )
    #   end
    # end

  end

end
