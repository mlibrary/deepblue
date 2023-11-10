# frozen_string_literal: true

module Aptrust

  class AptrustUploader

    # include AptrustBehavior

    ALLOW_DEPOSIT          = true
    BAG_FILE_APTRUST_INFO  = 'aptrust-info.txt'
    DEFAULT_BI_DESCRIPTION = 'No description supplied.'
    DEFAULT_BI_SOURCE      = 'University of Michigan'
    DEFAULT_CONTEXT        = ''
    DEFAULT_EXPORT_DIR     = './aptrust_export'
    DEFAULT_REPOSITORY     = 'UnknownRepo'
    DEFAULT_TYPE           = ''
    DEFAULT_UPLOAD_CONFIG_FILE = Rails.root.join( 'config', 'aptrust.yml' )
    DEFAULT_WORKING_DIR    = './aptrust_work'
    EXT_TAR                = '.tar'
    IDENTIFIER_TEMPLATE    = "%repository%.%context%%type%%id%"

    def self.arg_init( attr, default )
      attr ||= default
      return attr
    end

    def self.arg_init_squish(attr, default, squish: 255 )
      attr ||= default
      if attr.blank? && squish.present?
        attr = ''
      else
        attr = attr.squish[0..squish]
      end
      return attr
    end

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
      @bi_date             = AptrustBehavior.arg_init_squish( bi_date,        AptrustUploader.bag_date_now )
      @bi_description      = AptrustBehavior.arg_init_squish( bi_description, DEFAULT_BI_DESCRIPTION )
      @bi_id               = AptrustBehavior.arg_init_squish( bi_id,          @object_id )
      @bi_source           = AptrustBehavior.arg_init_squish( bi_source,      DEFAULT_BI_SOURCE )

      @bag_id              = bag_id
      @bag_id_context      = AptrustBehavior.arg_init_squish( bag_id_context,    DEFAULT_CONTEXT )
      @bag_id_repository   = AptrustBehavior.arg_init_squish( bag_id_repository, DEFAULT_REPOSITORY )
      @bag_id_type         = AptrustBehavior.arg_init_squish( bag_id_type,       DEFAULT_TYPE )

      @export_by_closure   = export_by_closure
      @export_copy_src     = export_copy_src
      @export_src_dir      = export_src_dir

      @export_dir          = AptrustBehavior.arg_init( export_dir,  DEFAULT_EXPORT_DIR )
      @working_dir         = AptrustBehavior.arg_init( working_dir, DEFAULT_WORKING_DIR )

      @upload_config       = upload_config
      @upload_config_file  = AptrustBehavior.arg_init( upload_config_file, DEFAULT_UPLOAD_CONFIG_FILE )
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
      track( status: 'bagging' )
      bag.write_bag_info( bag_info ) # Create bagit-info.txt file
      aptrust_info_write
      export_data
      bag_manifest
      track( status: 'bagged', note: "bag_dir: #{bag_dir}" )
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
        track( status: 'upload_skipped', note: 'allow_deposit? returned false' )
        return false
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
        track( status: 'uploading' )
        filename = File.join( export_dir, tar_filename )
        aws_object.upload_file( filename )
        track( status: 'uploaded' )
        return true
      rescue Aws::S3::Errors::ServiceError => e
        track( status: 'failed', note: "failed in #{e.context} with error #{e}" )
        # TODO: Rails.logger.error "Upload of file #{filename} failed with error #{e}"
        return false
      end
    end

    def bag_dir
      bag.bag_dir
    end

    def deposit()
      begin
        track( status: 'depositing' )
        bag_export
        bag_tar
        if bag_upload
          track( status: 'deposited' )
          # TODO: delete untarred files
        end
      rescue StandardError => e
        #::Deepblue::LoggingHelper.bold_error ["AptrustService.perform_deposit(#{object_id}) error #{e}"] + e.backtrace[0..20]
        track( status: 'deposit failed', note: "failed in #{e.backtrace[0]} with error #{e}" )
      end
    end

    def export_data()
      track( status: 'exporting' )
      export_data_by_closure unless export_by_closure.nil?
      export_data_by_copy if export_copy_src
      export_data_by_move if export_move_src
      track( status: 'exported' )
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
        track( status: 'packing' )
        Minitar.pack( tar_src, File.open( tar_filename, 'wb') )
        track( status: 'packed' )
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
