# frozen_string_literal: true

require_relative './aptrust'

module Aptrust

  class AptrustUploader

    mattr_accessor :aptrust_uploader_debug_verbose, default: true

    ALLOW_DEPOSIT          = true
    BAG_FILE_APTRUST_INFO  = 'aptrust-info.txt'
    DEFAULT_BI_DESCRIPTION = 'No description supplied.'
    DEFAULT_BI_SOURCE      = 'University of Michigan'
    DEFAULT_CONTEXT        = ''
    DEFAULT_EXPORT_DIR     = './aptrust_export'
    DEFAULT_REPOSITORY     = 'UnknownRepo'
    DEFAULT_TYPE           = ''
    DEFAULT_UPLOAD_CONFIG_FILE = Rails.root.join( 'data', 'config', 'aptrust.yml' )
    DEFAULT_WORKING_DIR    = './aptrust_work'
    EXT_TAR                = '.tar'
    IDENTIFIER_TEMPLATE    = "%repository%.%context%%type%%id%"

    def self.bag_date_now()
      rv = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      rv = Time.parse(rv).iso8601
      return rv
    end

    attr_accessor :additional_tag_files

    attr_accessor :aptrust_info
    attr_accessor :ai_access
    attr_accessor :ai_creator
    attr_accessor :ai_description
    attr_accessor :ai_item_description
    attr_accessor :ai_storage_option
    attr_accessor :ai_title

    attr_accessor :aptrust_upload_status
    attr_accessor :bag
    attr_accessor :bag_data_dir
    attr_accessor :bag_info
    attr_accessor :bi_date
    attr_accessor :bi_description
    attr_accessor :bi_id
    attr_accessor :bi_source

    attr_accessor :bag_id
    attr_accessor :bag_id_context
    attr_accessor :bag_id_repository
    attr_accessor :bag_id_type

    attr_accessor :export_by_closure
    attr_accessor :export_copy_src
    attr_accessor :export_move_src
    attr_accessor :export_src_dir

    attr_accessor :object_id
    attr_accessor :export_dir
    attr_accessor :working_dir

    attr_accessor :upload_config
    attr_accessor :upload_config_file

    def initialize( object_id:,

                    aptrust_info:        nil,
                    ai_access:           nil, # ignored if aptrust_info is defined
                    ai_creator:          nil, # ignored if aptrust_info is defined
                    ai_description:      nil, # ignored if aptrust_info is defined
                    ai_item_description: nil, # ignored if aptrust_info is defined
                    ai_storage_option:   nil, # ignored if aptrust_info is defined
                    ai_title:            nil, # ignored if aptrust_info is defined

                    bag:                 nil,
                    bag_info:            nil,
                    bi_date:             nil, # ignored if bag_info is defined
                    bi_description:      nil, # ignored if bag_info is defined
                    bi_id:               nil, # ignored if bag_info is defined
                    bi_source:           nil, # ignored if bag_info is defined

                    bag_id:              nil,
                    bag_id_context:      nil, # ignored if bag_id is defined
                    bag_id_repository:   nil, # ignored if bag_id is defined
                    bag_id_type:         nil, # ignored if bag_id is defined

                    export_by_closure:   nil,
                    export_copy_src:     false,
                    export_src_dir:      nil,

                    export_dir:          nil,
                    working_dir:         nil,

                    upload_config:       nil,
                    upload_config_file:  nil # ignored if upload_config is defined
                    )

      @object_id           = object_id

      @aptrust_info        = aptrust_info
      @ai_access           = ai_access
      @ai_creator          = ai_creator
      @ai_description      = ai_description
      @ai_item_description = ai_item_description
      @ai_storage_option   = ai_storage_option
      @ai_title            = ai_title

      @bag                 = bag
      @bag_info            = bag_info
      @bi_date             = Aptrust.arg_init_squish( bi_date,        AptrustUploader.bag_date_now )
      @bi_description      = Aptrust.arg_init_squish( bi_description, DEFAULT_BI_DESCRIPTION )
      @bi_id               = Aptrust.arg_init_squish( bi_id,          @object_id )
      @bi_source           = Aptrust.arg_init_squish( bi_source,      DEFAULT_BI_SOURCE )

      @bag_id              = bag_id
      @bag_id_context      = Aptrust.arg_init_squish( bag_id_context,    DEFAULT_CONTEXT )
      @bag_id_repository   = Aptrust.arg_init_squish( bag_id_repository, DEFAULT_REPOSITORY )
      @bag_id_type         = Aptrust.arg_init_squish( bag_id_type,       DEFAULT_TYPE )

      @export_by_closure   = export_by_closure
      @export_copy_src     = export_copy_src
      @export_src_dir      = export_src_dir

      @export_dir          = Aptrust.arg_init( export_dir,  DEFAULT_EXPORT_DIR )
      @working_dir         = Aptrust.arg_init( working_dir, DEFAULT_WORKING_DIR )

      @upload_config       = upload_config
      @upload_config_file  = Aptrust.arg_init( upload_config_file, DEFAULT_UPLOAD_CONFIG_FILE )
    end

    def additional_tag_files
      @additional_tag_files ||= []
    end

    def allow_deposit?
      return ALLOW_DEPOSIT
    end

    def aptrust_info
      @aptrust_info ||= AptrustInfo.new( access:           ai_access,
                                         creator:          ai_creator,
                                         description:      ai_description,
                                         item_description: ai_item_description,
                                         storage_option:   ai_storage_option,
                                         title:            ai_title ).build
    end

    def aptrust_info_write( aptrust_info: nil )
      aptrust_info = self.aptrust_info
      file = File.join( bag.bag_dir, BAG_FILE_APTRUST_INFO )
      File.write( file, aptrust_info, mode: 'w' )
      # this does not work: bag.tag_files << file
      additional_tag_files << file
    end

    def aptrust_upload_status
      @aptrust_uploader_status ||= AptrustUploaderStatus.new( id: @object_id )
    end

    def bag_data_dir
      @bag_data_dir ||= File.join( bag.bag_dir, "data" )
    end

    def bag
      @bag ||= bag_init
    end

    def bag_init
      bag_target_dir = File.join( working_dir, bag_id )
      Dir.mkdir( bag_target_dir ) unless Dir.exist? bag_target_dir
      bag = BagIt::Bag.new( bag_target_dir )
    end

    def bag_id
      @bag_id ||= bag_id_init
    end

    def bag_id_init()
      rv = bag_id_template
      rv = rv.gsub( /\%repository\%/, bag_id_repository )
      rv = rv.gsub( /\%context\%/, bag_id_context )
      rv = rv.gsub( /\%type\%/, bag_id_type )
      rv = rv.gsub( /\%id\%/, object_id )
      return rv
    end

    def bag_id_template
      return IDENTIFIER_TEMPLATE
    end

    def bag_info
      @bag_info || bag_info_init
    end

    def bag_info_init
      rv = {
        'Source-Organization'         => bi_source,
        'Bag-Count'                   => '1',
        'Bagging-Date'                => bi_date,
        'Internal-Sender-Description' => bi_description,
        'Internal-Sender-Identifier'  => bi_id
      }
      return rv
    end

    def bag_export
      track( status: EVENT_BAGGING )
      bag.write_bag_info( bag_info ) # Create bagit-info.txt file
      aptrust_info_write
      status = export_data
      if status == EVENT_EXPORTED
        bag_manifest
        track( status: EVENT_BAGGED, note: "bag_dir: #{bag_dir}" )
        return EVENT_BAGGED
      end
      return export_status
    end

    def bag_manifest
      bag.manifest!(algo: 'md5') # Create tagmanifest-info.txt and the data directory maniftest.txt

      # need to rewrite the tag manifest files to include the aptrust-info.txt file
      tag_files = bag.tag_files
      new_tag_files = tag_files & additional_tag_files
      # rewrite tagmanifest-info.txt if necessary
      bag.tagmanifest!( new_tag_files ) unless ( new_tag_files - tag_files ).empty?

      # HELIO-4380 demo.aptrust.org doesn't like this file for some reason, gives an ingest error:
      # "Bag contains illegal tag manifest 'sha1'""
      # APTrust only wants SHA256, or MD5, not SHA1.
      # 'tagmanifest-sha1.txt' is a bagit gem default, so we need to remove it manually.
      sha1tag = File.join( bag.bag_dir, 'tagmanifest-sha1.txt' )
      File.delete(sha1tag) if File.exist?(sha1tag)

    end

    def bag_tar
      tar_bag
      export_tar_file = File.join( export_dir, File.basename( tar_file ) )
      FileUtils.mv( tar_file, export_tar_file )
    end

    def bag_upload
      if !allow_deposit?
        track( status: EVENT_UPLOAD_SKIPPED, note: 'allow_deposit? returned false' )
        return false
      end
      if DEBUG_ASSUME_UPLOAD_SUCCEEDS
        track( status: EVENT_UPLOADED, note: 'DEBUG_ASSUME_UPLOAD_SUCCEEDS is true' )
        return true
      end
      begin
        # TODO: add timing
        aptrust = upload_config
        Aws.config.update( credentials: Aws::Credentials.new( aptrust['AwsAccessKeyId'],
                                                              aptrust['AwsSecretAccessKey'] ) )
        s3 = Aws::S3::Resource.new( region: aptrust['BucketRegion'] )
        bucket = s3.bucket( aptrust['Bucket'] )
        # filename = tar_filename
        # aws_object = bucket.object( File.basename(filename) )
        aws_object = bucket.object( tar_filename )
        track( status: EVENT_UPLOADING )
        filename = File.join( export_dir, tar_filename )
        aws_object.upload_file( filename )
        track( status: EVENT_UPLOADED )
        return true
      rescue Aws::S3::Errors::ServiceError => e
        track( status: EVENT_FAILED, note: "failed in #{e.context} with error #{e}" )
        # TODO: Rails.logger.error "Upload of file #{filename} failed with error #{e}"
        return false
      end
    end

    def bag_upload2( upload_file: )
      begin
        # TODO: add timing
        aptrust = upload_config
        Aws.config.update( credentials: Aws::Credentials.new( aptrust['AwsAccessKeyId'],
                                                              aptrust['AwsSecretAccessKey'] ) )
        s3 = Aws::S3::Resource.new( region: aptrust['BucketRegion'] )
        bucket = s3.bucket( aptrust['Bucket'] )
        # filename = tar_filename
        # aws_object = bucket.object( File.basename(filename) )
        aws_object = bucket.object( upload_file )
        track( status: EVENT_UPLOADING )
        filename = File.join( export_dir, tar_filename )
        aws_object.upload_file( filename )
        track( status: EVENT_UPLOADED )
        return true
      rescue Aws::S3::Errors::ServiceError => e
        track( status: EVENT_FAILED, note: "failed in #{e.context} with error #{e}" )
        # TODO: Rails.logger.error "Upload of file #{filename} failed with error #{e}"
        return false
      end
    end

    # TODO: review this for references to static methods
    def upload2( filename:, id: 'uknown' )
      @id ||= id
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "filename=#{filename}",
                                             "id=#{id}",
                                             "" ], bold_puts: false if aptrust_uploader_debug_verbose
      success = false
      track( status: EVENT_DEPOSITING )
      begin
        # add timing
        aptrust = upload_config
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "aptrust['Bucket']=#{aptrust['Bucket']}",
                                               "aptrust['BucketRegion']=#{aptrust['BucketRegion']}",
                                               "aptrust['AwsAccessKeyId']=#{aptrust['AwsAccessKeyId']}",
                                               "aptrust['AwsSecretAccessKey']=#{aptrust['AwsSecretAccessKey']}",
                                               "" ], bold_puts: false if aptrust_uploader_debug_verbose
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
        Aws.config.update( credentials: Aws::Credentials.new( aptrust['AwsAccessKeyId'], aptrust['AwsSecretAccessKey'] ) )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
        s3 = Aws::S3::Resource.new( region: aptrust['BucketRegion'] )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
        bucket = s3.bucket( aptrust['Bucket'] )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
        aws_object = bucket.object( File.basename(filename) )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
        track( status: EVENT_UPLOADING )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
        aws_object.upload_file( filename )
        success = true
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
        track( status: EVENT_UPLOADED )
        track( status: EVENT_DEPOSITED )
      rescue Aws::S3::Errors::ServiceError => e
        track( status: EVENT_FAILED, note: "failed in #{e.context} with error #{e}" )
        ::Deepblue::LoggingHelper.bold_error ["Upload of file #{filename} failed in #{e.context} with error #{e}"] + e.backtrace[0..20]
        Rails.logger.error "Upload of file #{filename} failed with error #{e}"
        success = false
      end
      success
    end

    def bag_dir
      bag.bag_dir
    end

    def deposit()
      begin
        track( status: EVENT_DEPOSITING )
        status = bag_export
        if status == EVENT_BAGGED
          bag_tar
          bag_upload
          track( status: EVENT_DEPOSITED )
          # TODO: delete untarred files
        end
      rescue StandardError => e
        #::Deepblue::LoggingHelper.bold_error ["AptrustService.perform_deposit(#{object_id}) error #{e}"] + e.backtrace[0..20]
        track( status: 'deposit failed', note: "failed in #{e.backtrace[0]} with error #{e}" )
      end
    end

    def export_data()
      track( status: EVENT_EXPORTING )
      status_note = nil
      begin # until true for break
        unless export_by_closure.nil?
          export_data_by_closure
          status = EVENT_EXPORTED
          break
        end
        if export_copy_src
          export_data_by_copy
          status = EVENT_EXPORTED
          break
        end
        if export_move_src
          export_data_by_move
          status = EVENT_EXPORTED
          break
        end
        status = EVENT_EXPORT_FAILED
        status_note = 'no export method defined'
      end until true
      track( status: EVENT_EXPORTED, note: status_note )
      return status
   end

    def export_data_by_closure # DBD dependency
      return if export_by_closure.nil?
      # @export_by_closure = ->(bag_data_dir) { export_data_work( target_dir: bag_data_dir ) }
      # @export_by_closure = ->(bag_data_dir) { for each file in src_directory copy it to bag_data_dir }
      data_dir = bag_data_dir
      export_by_closure.call( data_dir )
    end

    def export_data_by_copy
      return if export_src_dir.nil?
      return unless File.directory? export_src_dir
      # Note: this is a flat copy, i.e. it only copies files that are direct children of export_src_dir
      Dir.each_child( export_src_dir ) do|filename|
        file = File.join( export_src_dir, filename )
        next unless File.file? file
        FileUtils.cp( file, bag_data_dir, preserve: true )
      end
    end

    def export_data_by_move
      return if export_src_dir.nil?
      return unless File.directory? export_src_dir
      # Note: this is a flat move, i.e. it only moves files that are direct children of export_src_dir
      Dir.each_child( export_src_dir ) do|filename|
        file = File.join( export_src_dir, filename )
        next unless File.file? file
        FileUtils.mv( file, bag_data_dir )
      end
    end

    def tar_bag
      parent = File.dirname bag.bag_dir
      Dir.chdir( parent ) do
        tar_src = File.basename bag.bag_dir
        track( status: EVENT_PACKING )
        Minitar.pack( tar_src, File.open( tar_filename, 'wb') )
        track( status: EVENT_PACKED )
      end
    end

    def tar_file
      rv = bag.bag_dir + EXT_TAR
      return rv
    end

    def tar_filename
      rv = File.basename( bag.bag_dir ) + EXT_TAR
      return rv
    end

    def target_dir
      bag.bag_dir
    end

    def track( status:, note: nil )
      aptrust_upload_status.track( status: status, note: note )
    end

    def upload
      deposit
    end

    def upload_config
      @aptrust_upload_config ||= upload_config_load
    end

    def upload_config_load
      aptrust_yaml = upload_config_file
      aptrust = YAML.safe_load( File.read( aptrust_yaml ) )
      return aptrust
    end

  end

end
