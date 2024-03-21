# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustUploader

  mattr_accessor :aptrust_uploader_debug_verbose, default: false

  mattr_accessor :allow_deposit,          default: ::Aptrust::AptrustIntegrationService.allow_deposit

  mattr_accessor :cleanup_after_deposit,  default: ::Aptrust::AptrustIntegrationService.cleanup_after_deposit
  mattr_accessor :cleanup_before_deposit, default: ::Aptrust::AptrustIntegrationService.cleanup_before_deposit
  mattr_accessor :cleanup_bag,            default: ::Aptrust::AptrustIntegrationService.cleanup_bag
  mattr_accessor :cleanup_bag_data,       default: ::Aptrust::AptrustIntegrationService.cleanup_bag_data
  mattr_accessor :clear_status,           default: ::Aptrust::AptrustIntegrationService.clear_status

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
  attr_accessor :cleanup_after_deposit
  attr_accessor :cleanup_before_deposit
  attr_accessor :cleanup_bag
  attr_accessor :cleanup_bag_data
  attr_accessor :clear_status

  attr_accessor :export_errors
  attr_accessor :export_file_sets
  attr_accessor :export_file_sets_filter_date
  attr_accessor :export_file_sets_filter_event
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

                  cleanup_after_deposit:  ::Aptrust::AptrustUploader.cleanup_after_deposit,
                  cleanup_before_deposit: ::Aptrust::AptrustUploader.cleanup_before_deposit,
                  cleanup_bag:            ::Aptrust::AptrustUploader.cleanup_bag,
                  cleanup_bag_data:       ::Aptrust::AptrustUploader.cleanup_bag_data,
                  clear_status:           ::Aptrust::AptrustUploader.clear_status,

                  export_file_sets:              true,
                  export_file_sets_filter_date:  nil,
                  export_file_sets_filter_event: nil,
                  export_by_closure:             nil,
                  export_copy_src:               false,
                  export_src_dir:                nil,

                  export_dir:          nil,
                  working_dir:         nil,

                  debug_verbose:       aptrust_uploader_debug_verbose )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "debug_verbose=#{debug_verbose}",
                                           "msg_handler=#{msg_handler.pretty_inspect}",
                                           # "aptrust_config.pretty_inspect=#{aptrust_config.pretty_inspect}",
                                           "" ] if aptrust_uploader_debug_verbose

    @debug_verbose = debug_verbose
    @debug_verbose ||= aptrust_uploader_debug_verbose
    @msg_handler = msg_handler
    @msg_handler ||= ::Aptrust::NULL_MSG_HANDLER

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@debug_verbose=#{@debug_verbose}",
                                           "@msg_handler=#{@msg_handler.pretty_inspect}",
                                           # "aptrust_config.pretty_inspect=#{aptrust_config.pretty_inspect}",
                                           "" ] if aptrust_uploader_debug_verbose

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

    @cleanup_after_deposit        = cleanup_after_deposit
    @cleanup_before_deposit       = cleanup_before_deposit
    @cleanup_bag                  = cleanup_bag
    @cleanup_bag_data             = cleanup_bag_data
    @clear_status                 = clear_status
    @debug_assume_upload_succeeds = ::Aptrust.aptrust_debug_assume_upload_succeeds

    @export_errors                 = nil
    @export_file_sets              = export_file_sets
    @export_file_sets_filter_date  = export_file_sets_filter_date
    @export_file_sets_filter_event = export_file_sets_filter_event
    @export_by_closure             = export_by_closure
    @export_copy_src               = export_copy_src
    @export_src_dir                = export_src_dir

    @export_dir          = ::Aptrust.arg_init( export_dir,  DEFAULT_EXPORT_DIR )
    @working_dir         = ::Aptrust.arg_init( working_dir, DEFAULT_WORKING_DIR )
  end

  def additional_tag_files
    @additional_tag_files ||= []
  end

  def allow_deposit?
    return allow_deposit
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

  def bag_data_files
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    return [] unless Dir.exist? bag.bag_dir
    files = ::Deepblue::DiskUtilitiesHelper.files_in_dir( bag_data_dir,
                                                          dotmatch: true,
                                                          msg_handler: ::Aptrust::NULL_MSG_HANDLER )
    return files
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
    return bag
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
      'Bag-Count'                   => bag_info_bag_count,
      'Bagging-Date'                => bag_date_str( bi_date ),
      'Bagging-Timestamp'           => bag_date_time_str( bi_date ),
      'Internal-Sender-Description' => bi_description,
      'Internal-Sender-Identifier'  => bi_id
    }
    return rv
  end

  def bag_info_bag_count( count: 1, max: 1 )
    "#{count} of #{max}"
  end

  def bag_export
    track( status: ::Aptrust::EVENT_BAGGING )
    info = bag_info
    bag.write_bag_info( info ) # Create bagit-info.txt file
    aptrust_info_write
    status = export_data
    if status == ::Aptrust::EVENT_EXPORTED
      bag_manifest
      msg_handler.msg_error "bag.complete? return false" unless bag.complete?
      msg_handler.msg_error "bag.consistent? return false" unless bag.consistent?
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "bag.complete?=#{bag.complete?}",
                               "bag.consistent?=#{bag.consistent?}",
                               "" ] if debug_verbose
      track( status: ::Aptrust::EVENT_BAGGED, note: "bag_dir: #{bag_dir}" )
      status = ::Aptrust::EVENT_BAGGED
    end
    # bag.write_bag_info( info ) # this causes it generate an incorrect bag checksum
    return status
  end

  def bag_manifest
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    # Create tagmanifest-info.txt and the data directory maniftest.txt
    # bag.manifest!(algo: 'md5')
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "aptrust_config.bag_checksum_algorithm=#{aptrust_config.bag_checksum_algorithm}",
                             "" ] if debug_verbose
    bag.manifest!( algo: aptrust_config.bag_checksum_algorithm )

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

    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "aptrust_config.bag_delete_manifest_sha1=#{aptrust_config.bag_delete_manifest_sha1}",
                             "" ] if debug_verbose
    manifest_file = "manifest-#{aptrust_config.bag_checksum_algorithm}.txt"
    manifest_file = File.join( bag.bag_dir, manifest_file )
    if 'sha1' == aptrust_config.bag_checksum_algorithm
      # TODO: create a class to load the manifest-sha1.txt file and support querying for
      #       checksum consistency with file sets
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "can validate file set checksums using #{manifest_file}",
                               "" ] if debug_verbose
    end
    if debug_verbose
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "manifest_file=#{manifest_file}",
                               "" ] if debug_verbose
      if File.exist? manifest_file
        contents = File.open( manifest_file, "r" ) { |io| io.read }
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "manifest_file contents:",
                                 "#{contents}",
                                 "" ] if debug_verbose
      end
    end
    if aptrust_config.bag_delete_manifest_sha1
      # HELIO-4380 demo.aptrust.org doesn't like this file for some reason, gives an ingest error:
      # "Bag contains illegal tag manifest 'sha1'""
      # APTrust only wants SHA256, or MD5, not SHA1.
      # 'tagmanifest-sha1.txt' is a bagit gem default, so we need to remove it manually.
      sha1tag = File.join( bag.bag_dir, 'tagmanifest-sha1.txt' )
      if debug_verbose
        if File.exist?(sha1tag)
          contents = File.open( sha1tag, "r" ) { |io| io.read }
          msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                   "sha1tag contents:",
                                   "#{contents}",
                                   "" ] if debug_verbose
        end
      end
      File.delete(sha1tag) if File.exist?(sha1tag)
    end
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
                             "debug_assume_upload_succeeds=#{debug_assume_upload_succeeds}",
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

  def cleanup_bag_after
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_after_deposit=#{cleanup_after_deposit}",
                             "cleanup_bag=#{cleanup_bag}",
                             "cleanup_bag_data=#{cleanup_bag_data}",
                             "" ] if debug_verbose
    return unless cleanup_after_deposit
    delete_bag_data if cleanup_bag_data
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    delete_bag( delete_dir: true ) if cleanup_bag
  end

  def cleanup_bag_before
    return # skip this for now
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_bag_before_deposit=#{cleanup_before_deposit}",
                             "" ] if debug_verbose
    return unless cleanup_before_deposit
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_bag_data=#{cleanup_bag_data}",
                             "" ] if debug_verbose
    delete_bag_data_before if cleanup_bag_data
    delete_bag( delete_dir: false )
    @bag = nil
    bag
  end

  def cleanup_bag_data_files
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_bag_data=#{cleanup_bag_data}",
                             "" ] if debug_verbose
    return [] unless cleanup_bag_data
    files = bag_data_files
    return files
  end

  def cleanup_tar_file( cleanup_flag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_flag=#{cleanup_flag}",
                             "" ] if debug_verbose
    return unless cleanup_flag
    filename = File.join( export_dir, tar_filename )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "delete filename=#{filename}",
                             "" ] if debug_verbose
    return unless File.exist? filename
    File.delete filename
  end

  def delete_bag( delete_dir: false )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "delete_dir=#{delete_dir}", "" ] if debug_verbose
    delete_files_in( dir: bag.bag_dir )
    return unless delete_dir
    delete_dir( dir: bag.bag_dir )
  end

  def delete_bag_data
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag.bag_dir=#{bag.bag_dir}",
                             "Dir.exist? bag.bag_dir=#{Dir.exist? bag.bag_dir}",
                             "" ] if debug_verbose
    return unless Dir.exist? bag.bag_dir
    files = cleanup_bag_data_files
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_bag_data_files files.size=#{files.size}",
                             "" ] if debug_verbose
    delete_files( files: files )
    delete_dir( dir: bag_data_dir )
  end

  def delete_bag_data_before
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag.bag_dir=#{bag.bag_dir}",
                             "Dir.exist? bag.bag_dir=#{Dir.exist? bag.bag_dir}",
                             "" ] if debug_verbose
    return unless Dir.exist? bag.bag_dir
    files = bag_data_files
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_bag_data_files files.size=#{files.size}",
                             "" ] if debug_verbose
    delete_files( files: files )
  end

  def delete_dir( dir: )
    if Dir.empty? dir
      msg_handler.bold_debug [ "deleting #{dir}", ] if debug_verbose
      ::Deepblue::DiskUtilitiesHelper.delete_dir( dir, msg_handler: ::Aptrust::NULL_MSG_HANDLER )
    else
      msg_handler.bold_debug [ "can't delete #{dir}", ] if debug_verbose
    end
  end

  def delete_files( files: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "files.size=#{files.size}", "" ] if debug_verbose
    if files.present?
      files.each { |f| msg_handler.bold_debug [ "delete file #{f}" ] if debug_verbose }
      ::Deepblue::DiskUtilitiesHelper.delete_files( *files, msg_handler: ::Aptrust::NULL_MSG_HANDLER )
      files = ::Deepblue::DiskUtilitiesHelper.files_in_dir( bag.bag_dir,
                                                            dotmatch: true,
                                                            msg_handler: ::Aptrust::NULL_MSG_HANDLER )
      files.each { |f| msg_handler.bold_debug [ "after delete #{f}" ] if debug_verbose }
    end
  end

  def delete_files_in( dir: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "dir=#{dir}", "" ] if debug_verbose
    files = ::Deepblue::DiskUtilitiesHelper.files_in_dir( dir,
                                                          dotmatch: true,
                                                          msg_handler: ::Aptrust::NULL_MSG_HANDLER )
    files.each { |f| msg_handler.bold_debug [ "delete file #{f}" ] if debug_verbose }
    ::Deepblue::DiskUtilitiesHelper.delete_files( *files, msg_handler: ::Aptrust::NULL_MSG_HANDLER )
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
      cleanup_tar_file( cleanup_flag: cleanup_before_deposit )
      cleanup_bag_before
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
      msg_handler.bold_error ["Aptrust::AptrustService.perform_deposit(#{object_id}) error #{e}"] + e.backtrace[0..30] if debug_verbose
      track( status: ::Aptrust::EVENT_DEPOSIT_FAILED, note: "failed in #{e.backtrace[0]} with error #{e}" )
    end
    return unless bag_uploaded_succeeded
    begin
      track( status: ::Aptrust::EVENT_DEPOSITED ) if status == ::Aptrust::EVENT_UPLOADED
      cleanup_tar_file( cleanup_flag: cleanup_after_deposit )
      cleanup_bag_after
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
    export_data_resolve_errors
    track( status: ::Aptrust::EVENT_EXPORTED, note: status_note )
    return status
  end

  def export_data_resolve_error( error )
    # if export_errors may contain an instance of the ::Deepblue::ExportFilesChecksumMismatch
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "error&.message=#{error&.message}",
                             "error=#{error.pretty_inspect}",
                             "" ] if debug_verbose
    note = "#{error&.message}"
    track( status: ::Aptrust::EVENT_ERROR, note: note )
  end

  def export_data_resolve_errors
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "export_errors=#{export_errors.pretty_inspect}",
                             "" ] if debug_verbose
    return unless export_errors.present?
    export_errors.each do |error|
      export_data_resolve_error( error )
    end
    export_errors = nil
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
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "status=#{status}",
                             "note=#{note}",
                             "" ] if debug_verbose
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
