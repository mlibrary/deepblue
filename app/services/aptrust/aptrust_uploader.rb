# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustUploader

  mattr_accessor :aptrust_uploader_debug_verbose, default: false

  CLEAN_UP_AFTER_DEPOSIT = true  unless const_defined? :CLEAN_UP_AFTER_DEPOSIT
  CLEAN_UP_BAG           = false unless const_defined? :CLEAN_UP_BAG
  CLEAN_UP_BAG_DATA      = true  unless const_defined? :CLEAN_UP_BAG_DATA
  CLEAR_STATUS           = true  unless const_defined? :CLEAR_STATUS

  ALLOW_DEPOSIT          = true                               unless const_defined? :ALLOW_DEPOSIT
  BAG_FILE_APTRUST_INFO  = 'aptrust-info.txt'                 unless const_defined? :BAG_FILE_APTRUST_INFO
  DEFAULT_BI_DESCRIPTION = 'No description supplied.'         unless const_defined? :DEFAULT_BI_DESCRIPTION
  DEFAULT_BI_SOURCE      = 'University of Michigan'           unless const_defined? :DEFAULT_BI_SOURCE
  DEFAULT_CONTEXT        = ''                                 unless const_defined? :DEFAULT_CONTEXT
  DEFAULT_EXPORT_DIR     = './aptrust_export'                 unless const_defined? :DEFAULT_EXPORT_DIR
  DEFAULT_REPOSITORY     = 'UnknownRepo'                      unless const_defined? :DEFAULT_REPOSITORY
  DEFAULT_TYPE           = ''                                 unless const_defined? :DEFAULT_TYPE
  DEFAULT_WORKING_DIR    = './aptrust_work'                   unless const_defined? :DEFAULT_WORKING_DIR
  EXT_TAR                = '.tar'                             unless const_defined? :EXT_TAR

  def self.bag_date_now()
    return Time.now
    # rv = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    # rv = Time.parse(rv).iso8601
    # return rv
  end

  attr_accessor :additional_tag_files

  attr_accessor :aptrust_config
  attr_accessor :aptrust_config_file

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
  attr_accessor :bag_id_local_repository
  attr_accessor :bag_id_type

  attr_accessor :debug_assume_upload_succeeds
  attr_accessor :clean_up_after_deposit
  attr_accessor :clean_up_bag
  attr_accessor :clean_up_bag_data
  attr_accessor :clear_status

  attr_accessor :export_by_closure
  attr_accessor :export_copy_src
  attr_accessor :export_move_src
  attr_accessor :export_src_dir

  attr_accessor :msg_handler

  attr_accessor :object_id
  attr_accessor :export_dir
  attr_accessor :working_dir

  attr_accessor :debug_verbose

  def initialize( object_id:,
                  msg_handler:         nil,

                  aptrust_config:      nil,
                  aptrust_config_file: nil, # ignored if aptrust_config is defined

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

                  bag_id:                  nil,
                  bag_id_context:          nil, # ignored if bag_id is defined
                  bag_id_local_repository: nil, # ignored if bag_id is defined
                  bag_id_type:             nil, # ignored if bag_id is defined

                  clean_up_after_deposit: CLEAN_UP_AFTER_DEPOSIT,
                  clean_up_bag:           CLEAN_UP_BAG,
                  clean_up_bag_data:      CLEAN_UP_BAG_DATA,
                  clear_status:           CLEAR_STATUS,

                  export_by_closure:   nil,
                  export_copy_src:     false,
                  export_src_dir:      nil,

                  export_dir:          nil,
                  working_dir:         nil,

                  debug_verbose:       aptrust_uploader_debug_verbose )

    @debug_verbose = debug_verbose
    @debug_verbose ||= aptrust_uploader_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Aptrust::NULL_MSG_HANDLER

    # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
    #                                        ::Deepblue::LoggingHelper.called_from,
    #                                        "object_id=#{object_id}",
    #                                        "aptrust_config=#{aptrust_config}",
    #                                        "aptrust_config_file=#{aptrust_config_file}",
    #                                        "aptrust_info=#{aptrust_info}",
    #                                        "ai_access=#{ai_access}",
    #                                        "ai_creator=#{ai_creator}",
    #                                        "ai_description=#{ai_description}",
    #                                        "ai_item_description=#{ai_item_description}",
    #                                        "ai_storage_option=#{ai_storage_option}",
    #                                        "ai_title=#{ai_title}",
    #                                        "bag=#{bag}",
    #                                        "bag_info=#{bag_info}",
    #                                        "bi_date=#{bi_date}",
    #                                        "bi_description=#{bi_description}",
    #                                        "bi_id=#{bi_id}",
    #                                        "bag_id=#{bag_id}",
    #                                        "bag_id_context=#{bag_id_context}",
    #                                        "bag_id_local_repository=#{bag_id_local_repository}",
    #                                        "bag_id_type=#{bag_id_type}",
    #                                        "export_by_closure=#{export_by_closure}",
    #                                        "export_copy_src=#{export_copy_src}",
    #                                        "export_src_dir=#{export_src_dir}",
    #                                        "export_dir=#{export_dir}",
    #                                        "working_dir=#{working_dir}",
    #                                        "" ] if false

    @object_id           = object_id

    @aptrust_config      = aptrust_config
    @aptrust_config_file = aptrust_config_file
    @aptrust_config      ||= aptrust_config_init

    @aptrust_info        = aptrust_info
    @ai_access           = ai_access
    @ai_creator          = ai_creator
    @ai_description      = ai_description
    @ai_item_description = ai_item_description
    @ai_storage_option   = ai_storage_option
    @ai_title            = ai_title

    @bag                 = bag
    @bag_info            = bag_info
    @bi_date             = bi_date
    @bi_date             ||= ::Aptrust::AptrustUploader.bag_date_now
    @bi_description      = ::Aptrust.arg_init_squish( bi_description, DEFAULT_BI_DESCRIPTION )
    @bi_id               = ::Aptrust.arg_init_squish( bi_id,          @object_id )
    @bi_source           = ::Aptrust.arg_init_squish( bi_source,      DEFAULT_BI_SOURCE )

    @bag_id                  = bag_id
    @bag_id_context          = bag_id_context
    @bag_id_local_repository = bag_id_local_repository
    @bag_id_type             = ::Aptrust.arg_init( bag_id_type, DEFAULT_TYPE )

    @clean_up_after_deposit = clean_up_after_deposit
    @clean_up_bag           = clean_up_bag
    @clean_up_bag_data      = clean_up_bag_data
    @clear_status           = clear_status
    @debug_assume_upload_succeeds = ::Aptrust.aptrust_debug_assume_upload_succeeds

    @export_by_closure   = export_by_closure
    @export_copy_src     = export_copy_src
    @export_src_dir      = export_src_dir

    @export_dir          = ::Aptrust.arg_init( export_dir,  DEFAULT_EXPORT_DIR )
    @working_dir         = ::Aptrust.arg_init( working_dir, DEFAULT_WORKING_DIR )
  end

  def additional_tag_files
    @additional_tag_files ||= []
  end

  def allow_deposit?
    return ALLOW_DEPOSIT
  end

  def aptrust_config
    @aptrust_config ||= aptrust_config_init
  end

  def aptrust_config_init
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    if @aptrust_config.blank?
      @aptrust_config = if @aptrust_config_file.present?
                          ::Aptrust::AptrustConfig.new( filename: @aptrust_config_filename )
                        else
                          ::Aptrust::AptrustConfig.new
                        end
    end
    @aptrust_config
  end

  def aptrust_info
    @aptrust_info ||= ::Aptrust::AptrustInfo.new( access:           ai_access,
                                                creator:          ai_creator,
                                                description:      ai_description,
                                                item_description: ai_item_description,
                                                storage_option:   ai_storage_option,
                                                title:            ai_title ).build
  end

  def aptrust_info_write( aptrust_info: nil )
    aptrust_info ||= self.aptrust_info
    aptrust_info = aptrust_info.build if aptrust_info.respond_to? :build
    file = File.join( bag.bag_dir, BAG_FILE_APTRUST_INFO )
    File.write( file, aptrust_info, mode: 'w' )
    # this does not work: bag.tag_files << file
    additional_tag_files << file
  end

  def aptrust_upload_status
    @aptrust_uploader_status ||= ::Aptrust::AptrustUploaderStatus.new( id: @object_id )
  end

  def bag
    @bag ||= bag_init
  end

  def bag_data_dir
    @bag_data_dir ||= File.join( bag.bag_dir, "data" )
  end

  def bag_date_str( t )
    rv = t.utc.strftime("%Y-%m-%d")
    rv = Time.parse(rv).iso8601
    return rv
  end

  def bag_date_time_str( t )
    rv = t.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    rv = Time.parse(rv).iso8601
    return rv
  end

  def bag_id_context
    @bag_id_context = bag_id_context_init if @bag_id_context.blank?
    @bag_id_context
  end

  def bag_id_context_init
    aptrust_config.context
  end

  def bag_id_local_repository
    @bag_id_local_repository = bag_id_local_repository_init if @bag_id_local_repository.blank?
    @bag_id_local_repository
  end

  def bag_id_local_repository_init
    aptrust_config.local_repository
  end

  def bag_init
    bag_target_dir = File.join( working_dir, bag_id )
    Dir.mkdir( bag_target_dir ) unless Dir.exist? bag_target_dir
    bag = BagIt::Bag.new( bag_target_dir )
  end

  def bag_id
    @bag_id = bag_id_init if @bag_id.blank?
    @bag_id
  end

  def bag_id_init()
    return Aptrust.aptrust_identifier( template: bag_id_template,
                                       local_repository: bag_id_local_repository,
                                       context: bag_id_context,
                                       type: bag_id_type,
                                       noid: object_id )
    # rv = bag_id_template
    # rv = rv.gsub( /\%local_repository\%/, bag_id_local_repository )
    # rv = rv.gsub( /\%context\%/, bag_id_context )
    # rv = rv.gsub( /\%type\%/, bag_id_type )
    # rv = rv.gsub( /\%id\%/, object_id )
    # return rv
  end

  def bag_id_template
    return ::Aptrust::IDENTIFIER_TEMPLATE
  end

  def bag_info
    @bag_info ||= bag_info_init
  end

  def bag_info_init
    rv = {
      'Source-Organization'         => bi_source,
      'Bag-Count'                   => '1',
      'Bagging-Date'                => bag_date_str( bi_date ),
      'Bagging-Timestamp'           => bag_date_time_str( bi_date ),
      'Internal-Sender-Description' => bi_description,
      'Internal-Sender-Identifier'  => bi_id
    }
    return rv
  end

  def bag_export
    track( status: ::Aptrust::EVENT_BAGGING )
    bag.write_bag_info( bag_info ) # Create bagit-info.txt file
    aptrust_info_write
    status = export_data
    if status == ::Aptrust::EVENT_EXPORTED
      bag_manifest
      track( status: ::Aptrust::EVENT_BAGGED, note: "bag_dir: #{bag_dir}" )
      return ::Aptrust::EVENT_BAGGED
    end
    return export_status
  end

  def bag_manifest
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    bag.manifest!(algo: 'md5') # Create tagmanifest-info.txt and the data directory maniftest.txt

    # need to rewrite the tag manifest files to include the aptrust-info.txt file
    tag_files = bag.tag_files
    new_tag_files = tag_files | additional_tag_files
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                           "tag_files=#{tag_files}",
                                           "additional_tag_files=#{additional_tag_files}",
                                           "new_tag_files=#{new_tag_files}",
                                           "( new_tag_files - tag_files )=#{( new_tag_files - tag_files )}",
                                           "" ] if debug_verbose
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
      track( status: ::Aptrust::EVENT_UPLOAD_SKIPPED, note: 'allow_deposit? returned false' )
      return false, ::Aptrust::EVENT_UPLOAD_SKIPPED
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                           "debug_assume_upload_succeeds=#{debug_assume_upload_succeedss}",
                                           "" ] if debug_verbose
    if debug_assume_upload_succeeds
      track( status: ::Aptrust::EVENT_UPLOAD_SKIPPED, note: 'debug_assume_upload_succeeds is true' )
      return true, ::Aptrust::EVENT_UPLOAD_SKIPPED
    end
    begin
      # TODO: add timing
      config = aptrust_config
      Aws.config.update( credentials: Aws::Credentials.new( config.aws_access_key_id,
                                                            config.aws_secret_access_key ) )
      s3 = Aws::S3::Resource.new( region: config.bucket_region )
      bucket = s3.bucket( config.bucket )
      # filename = tar_filename
      # aws_object = bucket.object( File.basename(filename) )
      aws_object = bucket.object( tar_filename )
      track( status: ::Aptrust::EVENT_UPLOADING )
      filename = File.join( export_dir, tar_filename )
      # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Object.html#upload_file-instance_method
      aws_object.upload_file( filename )
      track( status: ::Aptrust::EVENT_UPLOADED )
      return true, ::Aptrust::EVENT_UPLOADED
    rescue Aws::S3::MultipartUploadError => e
      track( status: ::Aptrust::EVENT_FAILED, note: "failed in #{e.context} with error #{e}" )
      msg_handler.bold_error [ msg_handler.here,
                                             msg_handler.called_from,
                                             "failed in #{e.context} with error #{e}",
                                             "" ]
      # TODO: Rails.logger.error "Upload of file #{filename} failed with error #{e}"
      return false, ::Aptrust::EVENT_FAILED
    rescue Aws::S3::Errors::ServiceError => e
      track( status: ::Aptrust::EVENT_FAILED, note: "failed in #{e.context} with error #{e}" )
      msg_handler.bold_error [ msg_handler.here,
                                             msg_handler.called_from,
                                             "failed in #{e.context} with error #{e}",
                                             "" ]
      return false, ::Aptrust::EVENT_FAILED
    end
  end

  def bag_upload2( upload_file: )
    begin
      # TODO: add timing
      config = aptrust_config
      Aws.config.update( credentials: Aws::Credentials.new( config.aws_access_key_id,
                                                            config.aws_secret_access_key ) )
      s3 = Aws::S3::Resource.new( region: config.bucket_region )
      bucket = s3.bucket( config.bucket )
      # filename = tar_filename
      # aws_object = bucket.object( File.basename(filename) )
      aws_object = bucket.object( upload_file )
      track( status: ::Aptrust::EVENT_UPLOADING )
      filename = File.join( export_dir, tar_filename )
      aws_object.upload_file( filename )
      track( status: ::Aptrust::EVENT_UPLOADED )
      return true
    rescue Aws::S3::Errors::ServiceError => e
      track( status: ::Aptrust::EVENT_FAILED, note: "failed in #{e.context} with error #{e}" )
      # TODO: Rails.logger.error "Upload of file #{filename} failed with error #{e}"
      return false
    end
  end

  def bag_dir
    bag.bag_dir
  end

  def cleanup_bag
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag.bag_dir=#{bag.bag_dir}",
                             "Dir.exist? bag.bag_dir=#{Dir.exist? bag.bag_dir}",
                             "" ] if debug_verbose
    return unless Dir.exist? bag.bag_dir
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "clean_up_after_deposit=#{clean_up_after_deposit}",
                             "clean_up_bag=#{clean_up_bag}",
                             "clean_up_bag_data=#{clean_up_bag_data}",
                             "" ] if debug_verbose
    return unless clean_up_after_deposit
    files = cleanup_bag_data_files
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "files.size=#{files.size}",
                             "" ] if debug_verbose
    null_msg_handler = ::Aptrust::NULL_MSG_HANDLER
    if files.present?
      ::Deepblue::DiskUtilitiesHelper.delete_files( *files, msg_handler: null_msg_handler )
      files = ::Deepblue::DiskUtilitiesHelper.files_in_dir( bag.bag_dir,
                                                            dotmatch: true,
                                                            msg_handler: null_msg_handler )

      ::Deepblue::DiskUtilitiesHelper.delete_dir( bag_data_dir, msg_handler: null_msg_handler ) if Dir.empty? bag_data_dir
    end
    return unless clean_up_bag
    files = ::Deepblue::DiskUtilitiesHelper.files_in_dir( bag.bag_dir,
                                                          dotmatch: true,
                                                          msg_handler: null_msg_handler )
    ::Deepblue::DiskUtilitiesHelper.delete_files( *files, msg_handler: null_msg_handler )
    ::Deepblue::DiskUtilitiesHelper.delete_dir( bag.bag_dir, msg_handler: null_msg_handler ) if Dir.empty? bag_data_dir
  end

  def cleanup_bag_data_files
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "clean_up_bag_data=#{clean_up_bag_data}",
                             "" ] if debug_verbose
    return [] unless Dir.exist? bag.bag_dir
    return [] unless clean_up_bag_data
    files = ::Deepblue::DiskUtilitiesHelper.files_in_dir( bag_data_dir,
                                                          dotmatch: true,
                                                          msg_handler: ::Aptrust::NULL_MSG_HANDLER )
    return files
  end

  def cleanup_tar_file
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    return unless clean_up_after_deposit
    filename = File.join( export_dir, tar_filename )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                           "delete filename=#{filename}",
                                           "" ] if debug_verbose
    return unless File.exist? filename
    File.delete filename
  end

  def deposit
    bag_uploaded_succeeded = false
    begin
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                             "bag_uploaded_succeeded=#{bag_uploaded_succeeded}",
                                             "clear_status=#{clear_status}",
                                             "" ] if debug_verbose
      aptrust_upload_status.clear_statuses if clear_status
      track( status: ::Aptrust::EVENT_DEPOSITING )
      status = bag_export
      if status == ::Aptrust::EVENT_BAGGED
        bag_tar
        bag_uploaded_succeeded, status = bag_upload
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                               "bag_uploaded_succeeded=#{bag_uploaded_succeeded}",
                                               "status=#{status}",
                                               "" ] if debug_verbose
      end
    rescue StandardError => e
      #msg_handler.bold_error ["Aptrust::AptrustService.perform_deposit(#{object_id}) error #{e}"] + e.backtrace[0..20]
      track( status: ::Aptrust::EVENT_DEPOSIT_FAILED, note: "failed in #{e.backtrace[0]} with error #{e}" )
    end
    return unless bag_uploaded_succeeded
    begin
      track( status: ::Aptrust::EVENT_DEPOSITED ) if status == ::Aptrust::EVENT_UPLOADED
      cleanup_tar_file
      cleanup_bag
    end
  end

  def export_data
    track( status: ::Aptrust::EVENT_EXPORTING )
    status_note = nil
    begin # until true for break
      unless export_by_closure.nil?
        export_data_by_closure
        status = ::Aptrust::EVENT_EXPORTED
        break
      end
      if export_copy_src
        export_data_by_copy
        status = ::Aptrust::EVENT_EXPORTED
        break
      end
      if export_move_src
        export_data_by_move
        status = ::Aptrust::EVENT_EXPORTED
        break
      end
      status = ::Aptrust::EVENT_EXPORT_FAILED
      status_note = 'no export method defined'
    end until true
    track( status: ::Aptrust::EVENT_EXPORTED, note: status_note )
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
      track( status: ::Aptrust::EVENT_PACKING )
      Minitar.pack( tar_src, File.open( tar_filename, 'wb') )
      track( status: ::Aptrust::EVENT_PACKED )
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

  # TODO: review this for references to static methods
  def upload2( filename:, id: 'uknown' )
    @id ||= object_id
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                           "filename=#{filename}",
                                           "id=#{id}",
                                           "" ], bold_puts: false if debug_verbose
    success = false
    track( status: ::Aptrust::EVENT_DEPOSITING )
    begin
      # add timing
      config = aptrust_config
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                             "config.bucket=#{config.bucket}",
                                             "config.bucket_region=#{config.bucket_region}",
                                             "config.aws_access_key_id=#{config.aws_access_key_id}",
                                             "config.aws_secret_access_key=#{config.aws_secret_access_key}",
                                             "" ], bold_puts: false if debug_verbose
      msg_handler.bold_debug [ msg_handler.here ]
      Aws.config.update( credentials: Aws::Credentials.new( config.aws_access_key_id, config.aws_secret_access_key ) )
      msg_handler.bold_debug [ msg_handler.here ]
      s3 = Aws::S3::Resource.new( region: config.bucket_region )
      msg_handler.bold_debug [ msg_handler.here ]
      bucket = s3.bucket( config.bucket )
      msg_handler.bold_debug [ msg_handler.here ]
      aws_object = bucket.object( File.basename(filename) )
      msg_handler.bold_debug [ msg_handler.here ]
      track( status: ::Aptrust::EVENT_UPLOADING )
      msg_handler.bold_debug [ msg_handler.here ]
      aws_object.upload_file( filename )
      success = true
      msg_handler.bold_debug [ msg_handler.here ]
      track( status: ::Aptrust::EVENT_UPLOADED )
      track( status: ::Aptrust::EVENT_DEPOSITED )
    rescue Aws::S3::Errors::ServiceError => e
      track( status: ::Aptrust::EVENT_FAILED, note: "failed in #{e.context} with error #{e}" )
      msg_handler.bold_error ["Upload of file #{filename} failed in #{e.context} with error #{e}"] + e.backtrace[0..20]
      Rails.logger.error "Upload of file #{filename} failed with error #{e}"
      success = false
    end
    success
  end

end
