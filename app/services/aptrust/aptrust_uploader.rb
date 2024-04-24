# frozen_string_literal: true

require 'zip'
require_relative './aptrust'

class Aptrust::TarBag

  attr_accessor :bag_dir
  attr_accessor :bag_id
  attr_accessor :msg_handler
  attr_accessor :tar_file
  attr_accessor :tar_cmd_out

  def initialize( bag_dir:, bag_id:, tar_file:, msg_handler: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_dir=#{bag_dir}",
                             "bag_id=#{bag_id}",
                             "tar_file=#{tar_file}",
                             "" ] if msg_handler.debug_verbose
    @bag_dir = bag_dir
    @bag_id = bag_id
    @tar_file = tar_file
    @msg_handler = msg_handler
  end

  def run
    operation_dir = File.dirname bag_dir
    tar_target_file = File.basename tar_file
    source_dir_name = File.basename bag_dir
    @tar_cmd_out = `cd #{operation_dir};tar -cf #{tar_target_file} #{source_dir_name}`
  end

end

class Aptrust::AptrustUploader

  mattr_accessor :aptrust_uploader_debug_verbose, default: false

  mattr_accessor :allow_deposit,          default: ::Aptrust::AptrustIntegrationService.allow_deposit

  mattr_accessor :cleanup_after_deposit,  default: ::Aptrust::AptrustIntegrationService.cleanup_after_deposit
  mattr_accessor :cleanup_bag,            default: ::Aptrust::AptrustIntegrationService.cleanup_bag
  mattr_accessor :cleanup_bag_data,       default: ::Aptrust::AptrustIntegrationService.cleanup_bag_data
  mattr_accessor :clear_status,           default: ::Aptrust::AptrustIntegrationService.clear_status

  mattr_accessor :use_external_tar_cmd, default: true

  mattr_accessor :event_sleep_secs, default: 1

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

  def self.cleanup_bag_dir( bag_dir:, msg_handler:, debug_verbose: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_dir=#{bag_dir}",
                             "" ] if debug_verbose
    files_deleted = ::Deepblue::DiskUtilitiesHelper.delete_files_in_dir( bag_dir,
                                                                         delete_subdirs: true,
                                                                         msg_handler: msg_handler )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "files_deleted=#{files_deleted}",
                             "" ] if debug_verbose
    ::Aptrust::AptrustUploader.delete_bag_data_dir( bag_dir: bag_dir )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    ::Aptrust::AptrustUploader.delete_bag_dir( bag_dir: bag_dir,
                                               msg_handler: msg_handler,
                                               debug_verbose: debug_verbose )
  end

  def self.cleanup_tar_file( bag_dir:, export_dir:, msg_handler:, debug_verbose: )
    export_dir = File.absolute_path export_dir
    filename = File.join( export_dir, ::Aptrust::AptrustUploader.tar_filename( bag_dir: bag_dir ) )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "delete filename=#{filename}",
                             "" ] if debug_verbose
    return unless File.exist? filename
    File.delete filename
  end

  def self.delete_bag_dir( bag_dir:, and_contents: false, msg_handler:, debug_verbose: )
    if Dir.empty?( bag_dir ) || and_contents
      msg_handler.bold_debug [ "deleting #{bag_dir}", ] if debug_verbose
      ::Deepblue::DiskUtilitiesHelper.delete_dir( dir,
                                                  recursive: true,
                                                  msg_handler: debug_verbose ? msg_handler : ::Aptrust::NULL_MSG_HANDLER )
    else
      msg_handler.bold_debug [ "can't delete #{bag_dir}", ] if debug_verbose
    end
  end

  def self.tar_filename( bag_dir: )
    rv = File.basename( bag_dir ) + EXT_TAR
    return rv
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
  attr_accessor :bag_info
  attr_accessor :bi_date
  attr_accessor :bi_description
  attr_accessor :bi_id
  attr_accessor :bi_source

  attr_accessor :bag_id
  attr_accessor :bag_id_context
  attr_accessor :bag_id_local_repository
  attr_accessor :bag_id_type
  attr_accessor :bag_max_total_file_size

  attr_accessor :cleanup_after_deposit
  attr_accessor :cleanup_bag
  attr_accessor :cleanup_bag_data
  attr_accessor :clear_status

  attr_accessor :debug_assume_upload_succeeds

  attr_accessor :event_start
  attr_accessor :event_stop
  attr_accessor :event_stopped # once stopped, don't continue
  attr_accessor :export_errors
  attr_accessor :export_file_sets
  attr_accessor :export_file_sets_filter_date
  attr_accessor :export_file_sets_filter_event
  attr_accessor :export_by_closure
  attr_accessor :export_copy_src
  attr_accessor :export_dir
  attr_accessor :export_move_src
  attr_accessor :export_src_dir

  attr_accessor :msg_handler
  attr_accessor :most_recent_status
  attr_accessor :object_id
  attr_accessor :skip_event
  attr_accessor :working_dir
  attr_accessor :zip_data_dir

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

                  bag_info:            nil,
                  bi_date:             nil, # ignored if bag_info is defined
                  bi_description:      nil, # ignored if bag_info is defined
                  bi_id:               nil, # ignored if bag_info is defined
                  bi_source:           nil, # ignored if bag_info is defined

                  bag_id:                  nil,
                  bag_id_context:          ::Aptrust::AptrustIntegrationService.deposit_context, # ignored if bag_id is defined
                  bag_id_local_repository: nil, # ignored if bag_id is defined
                  bag_id_type:             nil, # ignored if bag_id is defined
                  bag_max_total_file_size: ::Aptrust::AptrustIntegrationService.bag_max_total_file_size,

                  cleanup_after_deposit:  ::Aptrust::AptrustUploader.cleanup_after_deposit,
                  cleanup_bag:            ::Aptrust::AptrustUploader.cleanup_bag,
                  cleanup_bag_data:       ::Aptrust::AptrustUploader.cleanup_bag_data,
                  clear_status:           ::Aptrust::AptrustUploader.clear_status,

                  event_start:                   nil,
                  event_stop:                    nil,
                  export_file_sets:              true,
                  export_file_sets_filter_date:  nil,
                  export_file_sets_filter_event: nil,
                  export_by_closure:             nil,
                  export_copy_src:               false,
                  export_src_dir:                nil,

                  export_dir:          nil,
                  working_dir:         nil,
                  zip_data_dir:        false,

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

    @most_recent_status = nil

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "@debug_verbose=#{@debug_verbose}",
                                           "@msg_handler=#{@msg_handler.pretty_inspect}",
                                           # "aptrust_config.pretty_inspect=#{aptrust_config.pretty_inspect}",
                                           "" ] if aptrust_uploader_debug_verbose

    debug_dump_aptrust_integration_service if debug_verbose
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "object_id=#{object_id}",
                             "aptrust_config=#{aptrust_config}",
                             "aptrust_config_file=#{aptrust_config_file}",
                             "aptrust_info=#{aptrust_info}",
                             "ai_access=#{ai_access}",
                             "ai_creator=#{ai_creator}",
                             "ai_description=#{ai_description}",
                             "ai_item_description=#{ai_item_description}",
                             "ai_storage_option=#{ai_storage_option}",
                             "ai_title=#{ai_title}",
                             "bag_info=#{bag_info}",
                             "bi_date=#{bi_date}",
                             "bi_description=#{bi_description}",
                             "bi_id=#{bi_id}",
                             "bag_id=#{bag_id}",
                             "bag_id_context=#{bag_id_context}",
                             "bag_id_local_repository=#{bag_id_local_repository}",
                             "bag_id_type=#{bag_id_type}",
                             "bag_max_total_file_size=#{bag_max_total_file_size}",
                             "cleanup_after_deposit=#{cleanup_after_deposit}",
                             "cleanup_bag=#{cleanup_bag}",
                             "cleanup_bag_data=#{cleanup_bag_data}",
                             "clear_status=#{clear_status}",
                             "debug_assume_upload_succeeds=#{debug_assume_upload_succeeds}",
                             "event_start=#{event_start}",
                             "event_stop=#{event_stop}",
                             "export_by_closure=#{export_by_closure}",
                             "export_copy_src=#{export_copy_src}",
                             "export_src_dir=#{export_src_dir}",
                             "export_dir=#{export_dir}",
                             "working_dir=#{working_dir}",
                             "" ] if debug_verbose

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

    @bag_max_total_file_size = bag_max_total_file_size
    @bag_max_total_file_size = ::Aptrust::AptrustIntegrationService.bag_max_total_file_size if @bag_max_total_file_size.blank?

    @cleanup_after_deposit        = cleanup_after_deposit
    @cleanup_bag                  = cleanup_bag
    @cleanup_bag_data             = cleanup_bag_data
    @clear_status                 = clear_status
    @debug_assume_upload_succeeds = ::Aptrust.aptrust_debug_assume_upload_succeeds

    @event_start                   = event_start
    @event_stop                    = event_stop
    @event_stopped                 = false
    @export_errors                 = nil
    @export_file_sets              = export_file_sets
    @export_file_sets_filter_date  = export_file_sets_filter_date
    @export_file_sets_filter_event = export_file_sets_filter_event
    @export_by_closure             = export_by_closure
    @export_copy_src               = export_copy_src
    @export_src_dir                = export_src_dir

    @export_dir          = ::Aptrust.arg_init( export_dir,  DEFAULT_EXPORT_DIR )
    @export_dir = File.absolute_path( @export_dir )
    @working_dir         = ::Aptrust.arg_init( working_dir, DEFAULT_WORKING_DIR )
    @working_dir = File.absolute_path( @working_dir )
    @zip_data_dir = zip_data_dir

    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "@object_id=#{@object_id}",
                             "@aptrust_config=#{@aptrust_config}",
                             "@aptrust_config_file=#{@aptrust_config_file}",
                             "@aptrust_info=#{@aptrust_info}",
                             "@ai_access=#{@ai_access}",
                             "@ai_creator=#{@ai_creator}",
                             "@ai_description=#{@ai_description}",
                             "@ai_item_description=#{@ai_item_description}",
                             "@ai_storage_option=#{@ai_storage_option}",
                             "@ai_title=#{@ai_title}",
                             "@bag_info=#{@bag_info}",
                             "@bi_date=#{@bi_date}",
                             "@bi_description=#{@bi_description}",
                             "@bi_id=#{@bi_id}",
                             "@bag_id=#{@bag_id}",
                             "@bag_id_context=#{@bag_id_context}",
                             "@bag_id_local_repository=#{@bag_id_local_repository}",
                             "@bag_id_type=#{@bag_id_type}",
                             "@bag_max_total_file_size=#{@bag_max_total_file_size}",
                             "@cleanup_after_deposit=#{@cleanup_after_deposit}",
                             "@cleanup_bag=#{@cleanup_bag}",
                             "@cleanup_bag_data=#{@cleanup_bag_data}",
                             "@clear_status=#{@clear_status}",
                             "@debug_assume_upload_succeeds=#{@debug_assume_upload_succeeds}",
                             "@event_start=#{@event_start}",
                             "@event_stop=#{@event_stop}",
                             "@export_by_closure=#{@export_by_closure}",
                             "@export_copy_src=#{@export_copy_src}",
                             "@export_src_dir=#{@export_src_dir}",
                             "@export_dir=#{@export_dir}",
                             "@working_dir=#{@working_dir}",
                             "" ] if debug_verbose

  end

  def additional_tag_files
    @additional_tag_files ||= []
  end

  def allow_deposit?
    return allow_deposit
  end

  def aptrust_config
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "@aptrust_config.blank?=#{@aptrust_config.blank?}",
                             "" ] if debug_verbose
    @aptrust_config ||= aptrust_config_init
  end

  def aptrust_config_init
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "@aptrust_config.blank?=#{@aptrust_config.blank?}",
                             "@aptrust_config_file.blank?=#{@aptrust_config_file}",
                             "" ] if debug_verbose
    if @aptrust_config.blank?
      @aptrust_config = if @aptrust_config_file.present?
                          ::Aptrust::AptrustConfig.new( filename: @aptrust_config_filename )
                        else
                          ::Aptrust::AptrustConfig.new
                        end
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "@aptrust_config=#{@aptrust_config.pretty_inspect}",
                             "" ] if debug_verbose
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

  def aptrust_info_write( bag:, aptrust_info: nil )
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

  def bag_bag( bag:, bag_info:, note: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_skip? ::Aptrust::EVENT_BAGGED
      # info = bag_info
      bag.write_bag_info( bag_info ) # Create bagit-info.txt file
      aptrust_info_write( bag: bag )
      bag_manifest( bag: bag )
      msg_handler.msg_error "bag.complete? return false" unless bag.complete?
      msg_handler.msg_error "bag.consistent? return false" unless bag.consistent?
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "bag.complete?=#{bag.complete?}",
                               "bag.consistent?=#{bag.consistent?}",
                               "" ] if debug_verbose
      track_with_sleep( status: ::Aptrust::EVENT_BAGGED, note: "bag_dir: #{bag.bag_dir}" )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_bagging( bag:, note: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_skip? ::Aptrust::EVENT_BAGGING
      track_with_sleep( status: ::Aptrust::EVENT_BAGGING, note: note )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_data_dir( bag: )
    File.join( bag.bag_dir, "data" )
  end

  def bag_data_files( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    return [] unless Dir.exist? bag.bag_dir
    files = ::Deepblue::DiskUtilitiesHelper.files_in_dir( bag.data_dir,
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

  def bag_export( bag:, bag_info: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    track_with_sleep( status: ::Aptrust::EVENT_BAGGING )
    bag.write_bag_info( bag_info ) # Create bagit-info.txt file
    aptrust_info_write( bag: bag )
    exporting( bag: bag )
    exported( bag: bag )
    begin # until true for break
      break if event_skip? ::Aptrust::EVENT_BAGGED
      break unless most_recent_status == ::Aptrust::EVENT_EXPORTED
      bag_manifest( bag: bag )
      msg_handler.msg_error "bag.complete? return false" unless bag.complete?
      msg_handler.msg_error "bag.consistent? return false" unless bag.consistent?
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "bag.complete?=#{bag.complete?}",
                               "bag.consistent?=#{bag.consistent?}",
                               "" ] if debug_verbose
      track_with_sleep( status: ::Aptrust::EVENT_BAGGED, note: id_from( bag: bag ) )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_export_data_files( bag:, data_files: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      bag_id = id_from( bag: bag )
      track_with_sleep( status: ::Aptrust::EVENT_EXPORTING, note: bag_id )
      break if event_stop?
      data_dir = bag.data_dir
      data_files.each do|file|
        next unless File.file? file
        FileUtils.mv( file, data_dir )
      end
      track_with_sleep( status: ::Aptrust::EVENT_EXPORTED, note: bag_id )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_id
    @bag_id = bag_id_init if @bag_id.blank?
    @bag_id
  end

  def bag_id_init()
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id_template=#{bag_id_template}",
                             "@bag_id_context=#{@bag_id_context}",
                             "bag_id_context=#{bag_id_context}",
                             "bag_id_type=#{bag_id_type}",
                             "object_id=#{object_id}",
                             "" ] if debug_verbose
    rv = Aptrust.aptrust_identifier( template: bag_id_template,
                                     local_repository: bag_id_local_repository,
                                     context: bag_id_context,
                                     type: bag_id_type,
                                     noid: object_id )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "rv=#{rv}" ] if debug_verbose
    return rv
    # rv = bag_id_template
    # rv = rv.gsub( /\%local_repository\%/, bag_id_local_repository )
    # rv = rv.gsub( /\%context\%/, bag_id_context )
    # rv = rv.gsub( /\%type\%/, bag_id_type )
    # rv = rv.gsub( /\%id\%/, object_id )
    # return rv
  end

  def bag_id_context
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "@bag_id_context=#{@bag_id_context}" ] if debug_verbose
    @bag_id_context = bag_id_context_init if @bag_id_context.nil?
    @bag_id_context
  end

  def bag_id_context_init
    rv = aptrust_config.context
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "aptrust_config.context=#{aptrust_config.context}",
                             "rv=#{rv}" ] if debug_verbose
    return rv
  end

  def bag_id_local_repository
    @bag_id_local_repository = bag_id_local_repository_init if @bag_id_local_repository.blank?
    @bag_id_local_repository
  end

  def bag_id_local_repository_init
    aptrust_config.local_repository
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

  def bag_info_for_multiple_bags( bag_group_identifier:, bag_num:, bag_max: )
    rv = { 'Bag-Group-Identifier' => bag_group_identifier }.merge bag_info
    rv['Bag-Count'] = bag_info_bag_count( count: bag_num, max: bag_max )
    return rv
  end

  def bag_info_bag_count( count: 1, max: 1 )
    "#{count} of #{max}"
  end

  def bag_init( bag_id: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{bag_id}" ] if debug_verbose
    bag_target_dir = File.join( File.absolute_path( working_dir ), bag_id )
    Dir.mkdir( bag_target_dir ) unless Dir.exist? bag_target_dir
    rv = BagIt::Bag.new( bag_target_dir )
    return rv
  end

  def bag_manifest( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      # Create tagmanifest-info.txt and the data directory maniftest.txt
      # bag.manifest!(algo: 'md5')
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "aptrust_config.bag_checksum_algorithm=#{aptrust_config.bag_checksum_algorithm}" ] if debug_verbose
      bag.manifest!( algo: aptrust_config.bag_checksum_algorithm )

      # need to rewrite the tag manifest files to include the aptrust-info.txt file
      tag_files = bag.tag_files
      new_tag_files = tag_files | additional_tag_files
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "tag_files=#{tag_files}",
                               "additional_tag_files=#{additional_tag_files}",
                               "new_tag_files=#{new_tag_files}",
                               "( new_tag_files - tag_files )=#{( new_tag_files - tag_files )}" ] if debug_verbose
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
                                 "can validate file set checksums using #{manifest_file}" ] if debug_verbose
      end
      if debug_verbose
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "manifest_file=#{manifest_file}" ] if debug_verbose
        if File.exist? manifest_file
          contents = File.open( manifest_file, "r" ) { |io| io.read }
          msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                   "manifest_file contents:",
                                   "#{contents}" ] if debug_verbose
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
                                     "#{contents}" ] if debug_verbose
          end
        end
        File.delete(sha1tag) if File.exist?(sha1tag)
      end
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_pack( bag:, note: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_skip? ::Aptrust::EVENT_PACKED
      if use_external_tar_cmd
        tar = Aptrust::TarBag.new( bag_dir: bag.bag_dir,
                                   bag_id: bag_id,
                                   tar_file: tar_file( bag: bag ),
                                   msg_handler: msg_handler )
        tar.run
      else
        parent = File.dirname bag.bag_dir
        Dir.chdir( parent ) do
          tar_src = File.basename bag.bag_dir
          msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
          Minitar.pack( tar_src, File.open( tar_filename( bag: bag ), 'wb') )
        end
      end
      export_tar_file = File.join( export_dir, File.basename( tar_file( bag: bag ) ) )
      bag_tar_mv( bag: bag, export_tar_file: export_tar_file, note: note )
      track_with_sleep( status: ::Aptrust::EVENT_PACKED, note: note )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_pack_and_upload( bag:, note: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}"  ] if debug_verbose
    files_exported = ::Aptrust::AptrustFileList.from_dir( dir: bag.data_dir )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "files_exported=#{files_exported}",
                             "files_exported.total_file_size=#{files_exported.total_file_size}",
                             "bag_max_total_file_size=#{bag_max_total_file_size}" ] if debug_verbose
    total_file_size = files_exported.total_file_size
    if total_file_size < bag_max_total_file_size
      bag_bagging( bag: bag )
      bag_bag( bag: bag, bag_info: bag_info )
      bag_packing( bag: bag, note: note )
      bag_pack( bag: bag )
      bag_uploading( bag: bag )
      bag_upload( bag: bag )
    else
      bag_pack_and_upload_multiple_bags( bag: bag, files_exported: files_exported )
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_pack_and_upload_multiple_bags( bag:, files_exported: )
    # TODO: add support for event_start and event_stop
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      base_bag_id = id_from( bag: bag )
      partitioned = []
      files_exported.sort_by_size
      msg_handler.bold_debug files_exported.files if debug_verbose
      begin
        partition = files_exported.list_files_up_to( max_total: bag_max_total_file_size )
        files_exported.delete_files( files: partition )
        partitioned << partition
      end until files_exported.empty?
      bag_max = partitioned.size
      lines = ["Multiple bag file distribution:"]
      partitioned.each_with_index do |partition,index|
        bag_num = index + 1
        part_bag_id = "#{base_bag_id}_#{bag_num}"
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "bag_num=#{bag_num}",
                                 "part_bag_id=#{part_bag_id}" ] if debug_verbose
        msg_handler.bold_debug partition if debug_verbose
        partition.each do |f|
          lines << "#{part_bag_id}: #{File.basename f}"
        end
      end
      export_log_lines( bag, lines )
      partitioned.each_with_index do |partition,index|
        bag_num = index + 1
        part_bag_id = "#{base_bag_id}_#{bag_num}"
        part_bag = bag_init( bag_id: part_bag_id )
        part_bag_info = bag_info_for_multiple_bags( bag_group_identifier: base_bag_id,
                                                    bag_num: bag_num,
                                                    bag_max: bag_max )
        bag_export_data_files( bag: part_bag, data_files: partition )
        bag_bagging( bag: bag, note: part_bag_id )
        bag_bag( bag: part_bag, bag_info: part_bag_info, note: part_bag_id )
        bag_packing( bag: bag, note: note )
        bag_pack( bag: bag, note: part_bag_id )
        bag_uploading( bag: bag, note: part_bag_id )
        bag_upload( bag: bag, note: part_bag_id )
      end
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_packing( bag:, note: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_skip? ::Aptrust::EVENT_PACKING
      track_with_sleep( status: ::Aptrust::EVENT_PACKING, note: note )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_tar_mv( bag:, export_tar_file:, note: nil )
    tar_file = tar_file( bag: bag )
    return if File.identical? tar_file, export_tar_file
    FileUtils.mv( tar_file, export_tar_file )
  end

  def bag_upload( bag:, note: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "bag_id=#{id_from( bag: bag )}",
                               "allow_deposit?=#{allow_deposit?}" ] if debug_verbose
      if !allow_deposit?
        track_with_sleep( status: ::Aptrust::EVENT_UPLOAD_SKIPPED, note: 'allow_deposit? returned false' )
        break
      end
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "bag_id=#{id_from( bag: bag )}",
                               "debug_assume_upload_succeeds=#{debug_assume_upload_succeeds}" ] if debug_verbose
      if debug_assume_upload_succeeds
        track_with_sleep( status: ::Aptrust::EVENT_UPLOAD_SKIPPED, note: 'debug_assume_upload_succeeds is true' )
        break
      end
      begin
        # TODO: add timing
        config = aptrust_config
        Aws.config.update( credentials: Aws::Credentials.new( config.aws_access_key_id,
                                                              config.aws_secret_access_key ) )
        s3 = Aws::S3::Resource.new( region: config.bucket_region )
        bucket = s3.bucket( config.bucket )
        aws_object = bucket.object( tar_filename( bag: bag ) )
        filename = File.join( export_dir, tar_filename( bag: bag ) )
        # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Object.html#upload_file-instance_method
        aws_object.upload_file( filename )
        track_with_sleep( status: ::Aptrust::EVENT_UPLOADED, note: note )
      rescue Aws::S3::MultipartUploadError => e
        track_with_sleep( status: ::Aptrust::EVENT_FAILED, error: true, note: "failed in #{e.context} with error #{e}" )
        msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                                 "failed in #{e.context} with error #{e}",
                                 "" ]
        # TODO: Rails.logger.error "Upload of file #{filename} failed with error #{e}"
      rescue Aws::S3::Errors::ServiceError => e
        track_with_sleep( status: ::Aptrust::EVENT_FAILED, error: true, note: "failed in #{e.context} with error #{e}" )
        msg_handler.bold_error [ msg_handler.here, msg_handler.called_from,
                                 "failed in #{e.context} with error #{e}" ]
      end
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def bag_uploading( bag:, note: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_skip? ::Aptrust::EVENT_UPLOADING
      track_with_sleep( status: ::Aptrust::EVENT_UPLOADING, note: note )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def cleanup_error( e )
    begin
      msg_handler.bold_error ["Aptrust::AptrustService cleanup -- #{object_id} -- error #{e}"] + e.backtrace[0..30]
      ::Aptrust::Status.update_note( noid: object_id, note: 'cleanup error' )
      # track_with_sleep( status: ::Aptrust::EVENT_DEPOSIT_FAILED, error: true, note: "failed in #{e.backtrace[0]} with error #{e}" )
    rescue StandardError => e2
      msg_handler.bold_error ["Aptrust::AptrustService cleanup -- #{object_id} -- error #{e2}"] + e2.backtrace[0..30]
    end
  end

  def cleanup_upload( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_stop?
      cleanup_tar_file( bag: bag, cleanup_flag: cleanup_after_deposit )
      cleanup_bag_after( bag: bag )
    rescue StandardError => e
      cleanup_error( e )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def cleanup_bag_after( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_after_deposit=#{cleanup_after_deposit}",
                             "cleanup_bag=#{cleanup_bag}",
                             "cleanup_bag_data=#{cleanup_bag_data}" ] if debug_verbose
    return unless cleanup_after_deposit
    delete_bag_data( bag: bag ) if cleanup_bag_data
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "" ] if debug_verbose
    delete_bag( bag: bag, delete_dir: true ) if cleanup_bag
  end

  def cleanup_bag_data_files( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_bag_data=#{cleanup_bag_data}" ] if debug_verbose
    return [] unless cleanup_bag_data
    files = bag_data_files( bag: bag )
    return files
  end

  def cleanup_tar_file( bag:, cleanup_flag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_flag=#{cleanup_flag}" ] if debug_verbose
    return unless cleanup_flag
    filename = File.join( export_dir, tar_filename( bag: bag ) )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "delete filename=#{filename}" ] if debug_verbose
    return unless File.exist? filename
    File.delete filename
  end

  def delete_bag( bag:, delete_dir: false )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "delete_dir=#{delete_dir}", "" ] if debug_verbose
    delete_files_in( dir: bag.bag_dir )
    return unless delete_dir
    delete_dir( dir: bag.bag_dir, and_contents: true )
  end

  def delete_bag_data( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag.bag_dir=#{bag.bag_dir}",
                             "Dir.exist? bag.bag_dir=#{Dir.exist? bag.bag_dir}",
                             "" ] if debug_verbose
    return unless Dir.exist? bag.bag_dir
    files = cleanup_bag_data_files( bag: bag )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_bag_data_files files.size=#{files.size}" ] if debug_verbose
    delete_files( bag: bag, files: files )
    delete_dir( dir: bag.data_dir )
  end

  def delete_bag_data_before( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag.bag_dir=#{bag.bag_dir}",
                             "Dir.exist? bag.bag_dir=#{Dir.exist? bag.bag_dir}" ] if debug_verbose
    return unless Dir.exist? bag.bag_dir
    files = bag_data_files( bag: bag )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "cleanup_bag_data_files files.size=#{files.size}" ] if debug_verbose
    delete_files( bag: bag, files: files )
  end

  def delete_dir( dir:, and_contents: false )
    dir_empty = Dir.empty? dir
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "dir=#{dir}",
                             "and_contents=#{and_contents}",
                             "Dir.empty? #{dir}=#{dir_empty}" ] if debug_verbose
    if dir_empty || and_contents
      msg_handler.bold_debug [ "deleting #{dir}", ] if debug_verbose
      ::Deepblue::DiskUtilitiesHelper.delete_dir( dir,
                                                  recursive: true,
                                                  msg_handler: debug_verbose ? msg_handler : ::Aptrust::NULL_MSG_HANDLER )
    else
      msg_handler.bold_debug [ "can't delete #{dir}", ] if debug_verbose
    end
  end

  def delete_files( bag:, files: )
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
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
    begin
      bag = bag_init( bag_id: bag_id )
      depositing( bag: bag )
      exporting( bag: bag )
      exported( bag: bag )
      bag_pack_and_upload( bag: bag )
      deposited( bag: bag )
      cleanup_upload( bag: bag )
    rescue StandardError => e
      msg_handler.bold_error ["Aptrust::AptrustService.perform_deposit(#{object_id}) error #{e}"] + e.backtrace[0..30]
      track_with_sleep( status: ::Aptrust::EVENT_DEPOSIT_FAILED, error: true, note: "failed in #{e.backtrace[0]} with error #{e}" )
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def deposited( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_stop?
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "@most_recent_status=#{@most_recent_status}"  ] if debug_verbose
      track_with_sleep( status: ::Aptrust::EVENT_DEPOSITED ) if most_recent_status == ::Aptrust::EVENT_UPLOADED
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def depositing( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_skip? ::Aptrust::EVENT_DEPOSITING
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
      aptrust_upload_status.clear_statuses if clear_status
      track_with_sleep( status: ::Aptrust::EVENT_DEPOSITING )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def event_skip?( event_to_skip )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "event_to_skip=#{event_to_skip}",
                             "@most_recent_status=#{@most_recent_status}",
                             "@event_stopped=#{@event_stopped}" ] if debug_verbose
    begin # until true for break
      rv = true
      break if @event_stopped
      rv = false
      break if skip_events.empty?
      rv = skip_events[event_to_skip]
      break if rv.nil?
      break unless rv
      @most_recent_status = event_to_skip
      rv = true
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "rv=#{rv} for event_to_skip #{event_to_skip}" ] if debug_verbose
    return rv
  end

  def event_stop?( event_to_stop = @most_recent_status )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "event_to_stop=#{event_to_stop}",
                             "@event_stop=#{@event_stop}",
                             "@event_stopped=#{@event_stopped}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
    begin # until true for break
      rv = true
      break if @event_stopped
      rv = false
      break unless event_to_stop.present?
      break unless @event_stop.present?
      rv = event_to_stop == @event_stop
      @event_stopped = true if rv
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, "rv=#{rv} for event_to_stop #{event_to_stop}" ] if debug_verbose
    return rv
  end

  def exported( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_skip? ::Aptrust::EVENT_EXPORTED
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
      status_note = nil
      data_dir = bag.data_dir
      data_dir = File.absolute_path data_dir
      begin # until true for break
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "export_by_closure.nil?=#{export_by_closure.nil?}" ] if debug_verbose
        unless export_by_closure.nil?
          export_data_by_closure( data_dir )
          status = ::Aptrust::EVENT_EXPORTED
          zip_data( bag: bag )
          export_data_resolve_errors
          break
        end
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "export_copy_src=#{export_copy_src}" ] if debug_verbose
        if export_copy_src
          export_data_by_copy( data_dir )
          status = ::Aptrust::EVENT_EXPORTED
          zip_data( bag: bag )
          export_data_resolve_errors
          break
        end
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "export_move_src=#{export_move_src}" ] if debug_verbose
        if export_move_src
          export_data_by_move( data_dir )
          status = ::Aptrust::EVENT_EXPORTED
          zip_data( bag: bag )
          export_data_resolve_errors
          break
        end
        msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                                 "export failed, no export method defined" ] if debug_verbose
        status = ::Aptrust::EVENT_EXPORT_FAILED
        status_note = 'no export method defined'
      end until true
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "status=#{status}" ] if debug_verbose
      track_with_sleep( status: status,
                        error: status == ::Aptrust::EVENT_EXPORT_FAILED,
                        note: status_note )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def export_data_by_closure( data_dir )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "data_dir=#{data_dir}" ] if debug_verbose
    return if export_by_closure.nil?
    # @export_by_closure = ->(data_dir) { export_data_work( target_dir: data_dir ) }
    # @export_by_closure = ->(data_dir) { for each file in src_directory copy it to data_dir }
    export_by_closure.call( data_dir )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "data_dir=#{data_dir}" ] if debug_verbose
  end

  def export_data_by_copy( data_dir )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "data_dir=#{data_dir}" ] if debug_verbose
    return if export_src_dir.nil?
    return unless File.directory? export_src_dir
    # Note: this is a flat copy, i.e. it only copies files that are direct children of export_src_dir
    Dir.each_child( export_src_dir ) do|filename|
      file = File.join( export_src_dir, filename )
      next unless File.file? file
      FileUtils.cp( file, data_dir, preserve: true )
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "data_dir=#{data_dir}" ] if debug_verbose
  end

  def export_data_by_move( data_dir )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "data_dir=#{data_dir}" ] if debug_verbose
    return if export_src_dir.nil?
    return unless File.directory? export_src_dir
    # Note: this is a flat move, i.e. it only moves files that are direct children of export_src_dir
    Dir.each_child( export_src_dir ) do|filename|
      file = File.join( export_src_dir, filename )
      next unless File.file? file
      FileUtils.mv( file, data_dir )
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "data_dir=#{data_dir}" ] if debug_verbose
  end

  def export_data_resolve_error( error )
    # if export_errors may contain an instance of the ::Deepblue::ExportFilesChecksumMismatch
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "error&.message=#{error&.message}",
                             "error=#{error.pretty_inspect}",
                             "" ] if debug_verbose
    note = "#{error&.message}"
    track_with_sleep( status: ::Aptrust::EVENT_ERROR, error: false, note: note )
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

  def export_log_lines( bag, *lines )
    file = File.join bag.data_dir, "w_#{object_id}.export.log"
    File.open( file, "a" ) do |f|
      lines.each { |line| f.puts line }
    end
  end

  def exporting( bag: )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from, "bag_id=#{id_from( bag: bag )}" ] if debug_verbose
    begin # until true for break
      break if event_skip? ::Aptrust::EVENT_EXPORTING
      track_with_sleep( status: ::Aptrust::EVENT_EXPORTING )
    end until true # for break
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "bag_id=#{id_from( bag: bag )}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def id_from( bag: )
    File.basename bag.bag_dir
  end

  def skip_events
    @skip_events ||= skip_events_init
  end

  def skip_events_init
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "event_start=#{event_start}" ] if debug_verbose
    case event_start
    when ::Aptrust::EVENT_DEPOSITING
      rv =     { ::Aptrust::EVENT_DEPOSITING => false,
                 ::Aptrust::EVENT_EXPORTING => false,
                 ::Aptrust::EVENT_EXPORTED => false,
                 ::Aptrust::EVENT_BAGGING => false,
                 ::Aptrust::EVENT_BAGGED => false,
                 ::Aptrust::EVENT_PACKING => false,
                 ::Aptrust::EVENT_PACKED => false,
                 ::Aptrust::EVENT_UPLOADING => false,
                 ::Aptrust::EVENT_UPLOADED => false,
                 ::Aptrust::EVENT_DEPOSITED => false }
    when ::Aptrust::EVENT_EXPORTING
      rv =     { ::Aptrust::EVENT_DEPOSITING => true,
                 ::Aptrust::EVENT_EXPORTING => false,
                 ::Aptrust::EVENT_EXPORTED => false,
                 ::Aptrust::EVENT_BAGGING => false,
                 ::Aptrust::EVENT_BAGGED => false,
                 ::Aptrust::EVENT_PACKING => false,
                 ::Aptrust::EVENT_PACKED => false,
                 ::Aptrust::EVENT_UPLOADING => false,
                 ::Aptrust::EVENT_UPLOADED => false,
                 ::Aptrust::EVENT_DEPOSITED => false }
    when ::Aptrust::EVENT_EXPORTED
      rv =     { ::Aptrust::EVENT_DEPOSITING => true,
                 ::Aptrust::EVENT_EXPORTING => true,
                 ::Aptrust::EVENT_EXPORTED => false,
                 ::Aptrust::EVENT_BAGGING => false,
                 ::Aptrust::EVENT_BAGGED => false,
                 ::Aptrust::EVENT_PACKING => false,
                 ::Aptrust::EVENT_PACKED => false,
                 ::Aptrust::EVENT_UPLOADING => false,
                 ::Aptrust::EVENT_UPLOADED => false,
                 ::Aptrust::EVENT_DEPOSITED => false }
    when ::Aptrust::EVENT_BAGGING
      rv =     { ::Aptrust::EVENT_DEPOSITING => true,
                 ::Aptrust::EVENT_EXPORTING => true,
                 ::Aptrust::EVENT_EXPORTED => true,
                 ::Aptrust::EVENT_BAGGING => false,
                 ::Aptrust::EVENT_BAGGED => false,
                 ::Aptrust::EVENT_PACKING => false,
                 ::Aptrust::EVENT_PACKED => false,
                 ::Aptrust::EVENT_UPLOADING => false,
                 ::Aptrust::EVENT_UPLOADED => false,
                 ::Aptrust::EVENT_DEPOSITED => false }
    when ::Aptrust::EVENT_BAGGED
      rv =     { ::Aptrust::EVENT_DEPOSITING => true,
                 ::Aptrust::EVENT_EXPORTING => true,
                 ::Aptrust::EVENT_EXPORTED => true,
                 ::Aptrust::EVENT_BAGGING => true,
                 ::Aptrust::EVENT_BAGGED => false,
                 ::Aptrust::EVENT_PACKING => false,
                 ::Aptrust::EVENT_PACKED => false,
                 ::Aptrust::EVENT_UPLOADING => false,
                 ::Aptrust::EVENT_UPLOADED => false,
                 ::Aptrust::EVENT_DEPOSITED => false }
    when ::Aptrust::EVENT_PACKING
      rv =     { ::Aptrust::EVENT_DEPOSITING => true,
                 ::Aptrust::EVENT_EXPORTING => true,
                 ::Aptrust::EVENT_EXPORTED => true,
                 ::Aptrust::EVENT_BAGGING => true,
                 ::Aptrust::EVENT_BAGGED => true,
                 ::Aptrust::EVENT_PACKING => false,
                 ::Aptrust::EVENT_PACKED => false,
                 ::Aptrust::EVENT_UPLOADING => false,
                 ::Aptrust::EVENT_UPLOADED => false,
                 ::Aptrust::EVENT_DEPOSITED => false }
    when ::Aptrust::EVENT_PACKED
      rv =     { ::Aptrust::EVENT_DEPOSITING => true,
                 ::Aptrust::EVENT_EXPORTING => true,
                 ::Aptrust::EVENT_EXPORTED => true,
                 ::Aptrust::EVENT_BAGGING => true,
                 ::Aptrust::EVENT_BAGGED => true,
                 ::Aptrust::EVENT_PACKING => true,
                 ::Aptrust::EVENT_PACKED => false,
                 ::Aptrust::EVENT_UPLOADING => false,
                 ::Aptrust::EVENT_UPLOADED => false,
                 ::Aptrust::EVENT_DEPOSITED => false }
    when ::Aptrust::EVENT_UPLOADING
      rv =     { ::Aptrust::EVENT_DEPOSITING => true,
                 ::Aptrust::EVENT_EXPORTING => true,
                 ::Aptrust::EVENT_EXPORTED => true,
                 ::Aptrust::EVENT_BAGGING => true,
                 ::Aptrust::EVENT_BAGGED => true,
                 ::Aptrust::EVENT_PACKING => true,
                 ::Aptrust::EVENT_PACKED => true,
                 ::Aptrust::EVENT_UPLOADING => false,
                 ::Aptrust::EVENT_UPLOADED => false,
                 ::Aptrust::EVENT_DEPOSITED => false }
    when ::Aptrust::EVENT_UPLOADED
      rv =     { ::Aptrust::EVENT_DEPOSITING => true,
                 ::Aptrust::EVENT_EXPORTING => true,
                 ::Aptrust::EVENT_EXPORTED => true,
                 ::Aptrust::EVENT_BAGGING => true,
                 ::Aptrust::EVENT_BAGGED => true,
                 ::Aptrust::EVENT_PACKING => true,
                 ::Aptrust::EVENT_PACKED => true,
                 ::Aptrust::EVENT_UPLOADING => true,
                 ::Aptrust::EVENT_UPLOADED => false,
                 ::Aptrust::EVENT_DEPOSITED => false }
    when ::Aptrust::EVENT_DEPOSITED
      rv =     { ::Aptrust::EVENT_DEPOSITING => true,
                 ::Aptrust::EVENT_EXPORTING => true,
                 ::Aptrust::EVENT_EXPORTED => true,
                 ::Aptrust::EVENT_BAGGING => true,
                 ::Aptrust::EVENT_BAGGED => true,
                 ::Aptrust::EVENT_PACKING => true,
                 ::Aptrust::EVENT_PACKED => true,
                 ::Aptrust::EVENT_UPLOADING => true,
                 ::Aptrust::EVENT_UPLOADED => true,
                 ::Aptrust::EVENT_DEPOSITED => false }
    else
      rv = {}
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "skip_events rv=#{rv.pretty_inspect}" ] if debug_verbose
    return rv
  end

  def tar_file( bag: )
    rv = bag.bag_dir + EXT_TAR
    return rv
  end

  def tar_filename( bag: )
    rv = ::Aptrust::AptrustUploader.tar_filename( bag_dir: bag.bag_dir )
    return rv
  end

  def target_dir( bag: )
    bag.bag_dir
  end

  def track( status:, error: false, note: nil )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "status=#{status}",
                             "note=#{note}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
    begin # until true for break
      break if event_skip? status
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
      status_str = "#{status}"
      status_str += " -- #{note}" if note.present?
      msg_handler.msg_verbose "#{@object_id}: #{status_str}"
      aptrust_upload_status.track( status: status, note: note )
    end until true # for break
    @most_recent_status = status
    if error
      @event_stopped = true # due to error
    else
      event_stop? status
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def track_with_sleep( status:, note: nil, error: false, sleep_secs: event_sleep_secs )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "status=#{status}",
                             "note=#{note}",
                             # "sleep_secs=#{sleep_secs}",
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
    begin # until true for break
      break if event_skip? status
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
      sleep_secs = event_sleep_secs if sleep_secs.blank?
      sleep( sleep_secs )
      status_str = "#{status}"
      status_str += " -- #{note}" if note.present?
      msg_handler.msg_verbose "#{@object_id}: #{status_str}"
      aptrust_upload_status.track( status: status, note: note )
    end until true # for break
    @most_recent_status = status
    if error
      @event_stopped = true # due to error
    else
      event_stop? status
    end
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "@most_recent_status=#{@most_recent_status}" ] if debug_verbose
  end

  def debug_dump_aptrust_integration_service
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "::Aptrust::AptrustIntegrationService.allow_deposit=#{::Aptrust::AptrustIntegrationService.allow_deposit}",
                             "::Aptrust::AptrustIntegrationService.deposit_context=#{::Aptrust::AptrustIntegrationService.deposit_context}",
                             "::Aptrust::AptrustIntegrationService.repository=#{::Aptrust::AptrustIntegrationService.repository}",
                             "::Aptrust::AptrustIntegrationService.local_repository=#{::Aptrust::AptrustIntegrationService.local_repository}",

                             "::Aptrust::AptrustIntegrationService.aptrust_info_txt_template=#{::Aptrust::AptrustIntegrationService.aptrust_info_txt_template}",

                             "::Aptrust::AptrustIntegrationService.bag_checksum_algorithm=#{::Aptrust::AptrustIntegrationService.bag_checksum_algorithm}",
                             "::Aptrust::AptrustIntegrationService.bag_delete_manifest_sha1=#{::Aptrust::AptrustIntegrationService.bag_delete_manifest_sha1}",
                             "::Aptrust::AptrustIntegrationService.bag_max_total_file_size=#{::Aptrust::AptrustIntegrationService.bag_max_total_file_size}",

                             "::Aptrust::AptrustIntegrationService.cleanup_after_deposit=#{::Aptrust::AptrustIntegrationService.cleanup_after_deposit}",
                             "::Aptrust::AptrustIntegrationService.cleanup_bag=#{::Aptrust::AptrustIntegrationService.cleanup_bag}",
                             "::Aptrust::AptrustIntegrationService.cleanup_bag_data=#{::Aptrust::AptrustIntegrationService.cleanup_bag_data}",
                             "::Aptrust::AptrustIntegrationService.clear_status=#{::Aptrust::AptrustIntegrationService.clear_status}",

                             "::Aptrust::AptrustIntegrationService.default_access=#{::Aptrust::AptrustIntegrationService.default_access}",
                             "::Aptrust::AptrustIntegrationService.default_creator=#{::Aptrust::AptrustIntegrationService.default_creator}",
                             "::Aptrust::AptrustIntegrationService.default_description=#{::Aptrust::AptrustIntegrationService.default_description}",
                             "::Aptrust::AptrustIntegrationService.default_item_description=#{::Aptrust::AptrustIntegrationService.default_item_description}",
                             "::Aptrust::AptrustIntegrationService.default_storage_option=#{::Aptrust::AptrustIntegrationService.default_storage_option}",
                             "::Aptrust::AptrustIntegrationService.default_title=#{::Aptrust::AptrustIntegrationService.default_title}",

                             "::Aptrust::AptrustIntegrationService.dbd_creator=#{::Aptrust::AptrustIntegrationService.dbd_creator}",
                             "::Aptrust::AptrustIntegrationService.dbd_bag_description=#{::Aptrust::AptrustIntegrationService.dbd_bag_description}",
                             "::Aptrust::AptrustIntegrationService.dbd_work_description=#{::Aptrust::AptrustIntegrationService.dbd_work_description}",
                             "::Aptrust::AptrustIntegrationService.dbd_validate_file_checksums=#{::Aptrust::AptrustIntegrationService.dbd_validate_file_checksums}",

                             "::Aptrust::AptrustIntegrationService.download_dir=#{::Aptrust::AptrustIntegrationService.download_dir}",
                             "::Aptrust::AptrustIntegrationService.export_dir=#{::Aptrust::AptrustIntegrationService.export_dir}",
                             "::Aptrust::AptrustIntegrationService.working_dir=#{::Aptrust::AptrustIntegrationService.working_dir}",
                             "::Aptrust::AptrustIntegrationService.storage_option=#{::Aptrust::AptrustIntegrationService.storage_option}",
                             "" ] if debug_verbose
  end

  def upload
    debug_dump_aptrust_integration_service if debug_verbose
    deposit
  end

  # TODO: review this for references to static methods
  # NOTE: this does not support event_start / event_stop
  def upload_legacy( filename:, id: 'uknown' )
    @id ||= object_id
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                             "filename=#{filename}",
                             "id=#{id}",
                             "" ], bold_puts: false if debug_verbose
    success = false
    track_with_sleep( status: ::Aptrust::EVENT_DEPOSITING )
    msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from ] if debug_verbose
    begin
      # add timing
      config = aptrust_config
      msg_handler.bold_debug [ msg_handler.here, msg_handler.called_from,
                               "config.bucket=#{config.bucket}",
                               "config.bucket_region=#{config.bucket_region}",
                               "config.aws_access_key_id=#{config.aws_access_key_id}",
                               "config.aws_secret_access_key=#{config.aws_secret_access_key}" ] if debug_verbose
      msg_handler.bold_debug [ msg_handler.here ]
      Aws.config.update( credentials: Aws::Credentials.new( config.aws_access_key_id, config.aws_secret_access_key ) )
      msg_handler.bold_debug [ msg_handler.here ]
      s3 = Aws::S3::Resource.new( region: config.bucket_region )
      msg_handler.bold_debug [ msg_handler.here ]
      bucket = s3.bucket( config.bucket )
      msg_handler.bold_debug [ msg_handler.here ]
      aws_object = bucket.object( File.basename(filename) )
      msg_handler.bold_debug [ msg_handler.here ]
      track_with_sleep( status: ::Aptrust::EVENT_UPLOADING )
      msg_handler.bold_debug [ msg_handler.here ]
      aws_object.upload_file( filename )
      success = true
      msg_handler.bold_debug [ msg_handler.here ]
      track_with_sleep( status: ::Aptrust::EVENT_UPLOADED )
      track_with_sleep( status: ::Aptrust::EVENT_DEPOSITED )
    rescue Aws::S3::Errors::ServiceError => e
      track_with_sleep( status: ::Aptrust::EVENT_FAILED, error: true, note: "failed in #{e.context} with error #{e}" )
      msg_handler.bold_error ["Upload of file #{filename} failed in #{e.context} with error #{e}"] + e.backtrace[0..20]
      Rails.logger.error "Upload of file #{filename} failed with error #{e}"
      success = false
    end
    success
  end

  def zip_data( bag: )
    return unless zip_data_dir
    data_dir = bag.data_dir
    # NOTE: based on naming conventions for file set extracts, 'data.zip' will NOT be one of the files in the data dir
    base_zipfile = 'data.zip'
    target_zipfile = File.join data_dir, base_zipfile
    File.delete target_zipfile if File.exist? target_zipfile
    data_files = bag_data_files( bag: bag )
    msg_handler.msg_verbose "zip file '#{target_zipfile}'"
    Zip::File.open( target_zipfile, Zip::File::CREATE ) do |zipfile|
      data_files.each do |file|
        base_file_name = File.basename file
        next if base_file_name == base_zipfile
        msg_handler.msg_verbose "zipping '#{base_file_name}'"
        zipfile.add( base_file_name, file )
      end
    end
    # empty the data dir of all files but the zip file
    data_files.each do |file|
      base_file_name = File.basename file
      next if base_file_name == base_zipfile
      msg_handler.msg_verbose "deleting after zip '#{base_file_name}'"
      File.delete file
    end
  end

end
