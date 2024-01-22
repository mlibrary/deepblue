# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustService

  mattr_accessor :aptrust_service_debug_verbose, default: false

  mattr_accessor :aptrust_service_allow_deposit,      default: true
  mattr_accessor :aptrust_service_deposit_context,    default: "" # none for DBD
  mattr_accessor :aptrust_service_deposit_repository, default: "deepbluedata"

  EXT_TAR = '.tar'
  IDENTIFIER_TEMPLATE = "%repository%.%context%%type%%id%"
  ID_SEP = '-'

  BAG_INFO_KEY_SOURCE = 'Source-Organization'
  BAG_INFO_KEY_COUNT = 'Bag-Count'
  BAG_INFO_KEY_DATE = 'Bagging-Date'
  BAG_INFO_VALUE_SOURCE = 'University of Michigan'
  BAG_FILE_APTRUST_INFO = 'aptrust-info.txt'

  STATUSES = %w[ bagged bagging
                 deposit_skipped deposited depositing
                 exported exporting
                 failed
                 packed packing
                 skipped
                 uploaded uploading ]

  def self.context
    rv = aptrust_service_deposit_context
    if rv.blank?
      hostname = ::Deepblue::ReportHelper.hostname_short
      if 'local' == hostname
        rv = 'localhost' + ID_SEP
      end
    end
  end

  def self.repository
    aptrust_service_deposit_repository
  end

  def self.allow_deposit?
    return false unless aptrust_service_allow_deposit
    # TODO: check for service available
    return true
  end

  def self.allow_work?(work)
    return true # TODO: check size
    # return false unless monograph.is_a?(Sighrax::Monograph)
  end

  def self.aptrust_info( work: ) # TODO: broken
    AptrustInfo.new( work: work ).build
  end

  def self.aptrust_info_write( bag:, work:, additional_tag_files: )
    aptrust_info = aptrust_info( work: work )
    file = File.join( bag.bag_dir, BAG_FILE_APTRUST_INFO )
    File.write( file, aptrust_info, mode: 'w' )
    # this does not work: bag.tag_files << file
    additional_tag_files << file
  end

  def self.bag_export( working_dir: nil, work:, bag_id: nil, status_history: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "working_dir=#{working_dir}",
                                           "work=#{work}",
                                           "bag_id=#{bag_id}",
                                           "status_history=#{status_history}",
                                           "" ], bold_puts: false if aptrust_service_debug_verbose

    status_history = track_deposit( id: work.id, status: 'bagging', status_history: status_history )
    working_dir ||= dir_working
    bag_id ||= bag_identifier( work: work )
    target_dir = File.join( working_dir, id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "working_dir=#{target_dir}",
                                           "work=#{work}",
                                           "bag_id=#{bag_id}",
                                           "" ], bold_puts: false if aptrust_service_debug_verbose
    Dir.mkdir( target_dir ) unless Dir.exist? target_dir
    bag = BagIt::Bag.new( target_dir )
    bag_info = bag_info( work: work )
    bag.write_bag_info( bag_info ) # Create bagit-info.txt file
    additional_tag_files = []
    aptrust_info_write( bag: bag, work: work, additional_tag_files: additional_tag_files )
    bag_data_dir = File.join( bag.bag_dir, "data" )
    bag_data_dir = Pathname.new bag_data_dir
    export_work( work: work, target_dir: bag_data_dir )
    bag_manifest( bag: bag, additional_tag_files: additional_tag_files )
    status_history = track_deposit( id: work.id,
                                    status: 'bagged',
                                    note: "target_dir: #{target_dir}",
                                    status_history: status_history )
    target_dir
  end

  def self.bag_date_now()
    rv = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    rv = Time.parse(rv).iso8601
    return rv
  end

  def self.bag_info( work: )
    # add bagit-info.txt file
    # The length of the following 'internal_sender_description' does not work with the current bagit gem, maybe later.
    # pub = monograph_presenter.publisher.blank? ? '' : monograph_presenter.publisher.first.squish[0..55]
    # internal_sender_description = "This bag contains all of the data and metadata in a Monograph from #{pub} which has been exported from the Fulcrum publishing platform hosted at www.fulcrum.org."
    {
      BAG_INFO_KEY_SOURCE => BAG_INFO_VALUE_SOURCE,
      BAG_INFO_KEY_COUNT => '1',
      BAG_INFO_KEY_DATE => bag_date_now(),
      'Internal-Sender-Description' => bag_description( work ),
      'Internal-Sender-Identifier' => id_work( work )
    }
  end

  def self.bag_description( work )
    "Bag for a #{work.class.name} hosted at deepblue.lib.umich.edu/data/" # TODO: improve this, or move to config
  end

  def self.bag_manifest
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

  def self.deposit( filename:, id:, status_history: nil  ) # TODO: review and code
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "filename=#{filename}",
                                           "id=#{id}",
                                           "status_history=#{status_history}",
                                           "" ], bold_puts: false if aptrust_service_debug_verbose
    success = false
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "allow_deposit?=#{allow_deposit?}",
                                           "" ], bold_puts: false if aptrust_service_debug_verbose
    if !allow_deposit?
      status_history = track_deposit( id: id, status: 'deposit_skipped', status_history: status_history )
    else
      upload( filename: filename, id: id, status_history: status_history )
    end
    status_history = track_deposit( id: id, status: 'deposited', status_history: status_history ) if success
    success
  end

  def self.dir_export
    hostname = ::Deepblue::ReportHelper.hostname_short
    if 'local' == hostname
      rv = './data/aptrust_export/'
    else
      rv = '/deepbluedata-prep/aptrust_export/'
    end
    Dir.mkdir( rv ) unless Dir.exist? rv
    return rv
  end

  def self.dir_working
    hostname = ::Deepblue::ReportHelper.hostname_short
    if 'local' == hostname
      rv = './data/aptrust_work/'
    else
      rv = '/deepbluedata-prep/aptrust_work/'
    end
    Dir.mkdir( rv ) unless Dir.exist? rv
    return rv
  end

  def self.export_do_copy?( target_dir, target_file_name ) # TODO: check file size?
    prep_file_name = target_file_name( target_dir, target_file_name )
    do_copy = true
    if File.exist? prep_file_name
      ::Deepblue::LoggingHelper.debug "skipping copy because #{prep_file_name} already exists"
      do_copy = false
    end
    do_copy
  end

  def self.export_work( work:, target_dir:, status_history: nil  )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work=#{work}",
                                           "target_dir=#{target_dir}",
                                           "" ] if aptrust_service_debug_verbose
    status_history = track_deposit( id: work.id, status: 'exporting', status_history: status_history )
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
    status_history = track_deposit( id: work.id, status: 'exported', status_history: status_history )
  end

  def self.find_work( id )
    return DataSet.find id
  end

  def self.id_work( work )
    work.id
  end

  def self.bag_identifier( work: )
    rv = IDENTIFIER_TEMPLATE
    rv = rv.gsub( /\%repository\%/, repository )
    rv = rv.gsub( /\%context\%/, context )
    rv = rv.gsub( /\%type\%/, type( work ) )
    rv = rv.gsub( /\%id\%/, work.id )
    return rv
  end

  def self.load_config

    # TODO: load this into a var and reuse

    #   aptrust_yaml = Rails.root.join('config', 'aptrust.yml')
    #   aptrust = YAML.safe_load(File.read(aptrust_yaml))
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ], bold_puts: false if aptrust_service_debug_verbose
    aptrust_yaml = Rails.root.join( 'data', 'config', 'aptrust.yml')
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "aptrust_yaml=#{aptrust_yaml}",
                                           "" ], bold_puts: false if aptrust_service_debug_verbose
    aptrust = YAML.safe_load( File.read(aptrust_yaml) )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "aptrust_yaml=#{aptrust_yaml}",
                                           "" ], bold_puts: false if aptrust_service_debug_verbose
    return aptrust
  end

  def self.peform_deposit( id )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "" ] if aptrust_service_debug_verbose
    work = find_work( id )
    uploader = AptrustUploaderForWork.new( work: work )
    uploader.upload
  end

  def self.perform_deposit2( id, status_history: nil  )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "" ] if aptrust_service_debug_verbose
    work = find_work( id )
    unless allow_work? work
      status_history = track_deposit( id: id, status: 'skipped', status_history: status_history )
      return status_history
    end
    begin
      status_history = track_deposit( id: id, status: 'depositing', status_history: status_history )
      work_dir = bag_export( work: work, status_history: status_history )
      tar_file = tar( dir: work_dir, id: id, status_history: status_history )
      export_dir = dir_export
      export_tar_file = File.join( export_dir, File.basename( tar_file ) )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "export_dir=#{export_dir}",
                                             "tar_file=#{tar_file}",
                                             "export_tar_file=#{export_tar_file}",
                                             "" ] if aptrust_service_debug_verbose
      FileUtils.mv( tar_file, export_tar_file )
      # TODO: delete untarred files
      deposit( filename: export_tar_file, id: id, status_history: status_history )
    rescue StandardError => e
      ::Deepblue::LoggingHelper.bold_error ["AptrustService.perform_deposit(#{id}) error #{e}"] + e.backtrace[0..20]
      status_history = track_deposit( id: id, status: 'failed', status_history: status_history, note: "failed in #{e.context} with error #{e}" )
    end
    return status_history
  end

  def self.tar( dir:, id:, status_history: nil  )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "dir=#{dir}",
                                           "id=#{id}",
                                           "" ] if aptrust_service_debug_verbose
    parent = File.dirname dir
    Dir.chdir(parent) do
      tar_src = File.basename dir
      tar_file = File.basename( dir ) + EXT_TAR
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "dir=#{dir}",
                                             "parent=#{parent}",
                                             "tar_src=#{tar_src}",
                                             "tar_file=#{tar_file}",
                                             "" ] if aptrust_service_debug_verbose
      status_history = track_deposit( id: id, status: 'packing', status_history: status_history )
      Minitar.pack( tar_src, File.open( tar_file, 'wb') )
      status_history = track_deposit( id: id, status: 'packed', status_history: status_history )
    end
    rv = dir + EXT_TAR
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "dir=#{dir}",
                                           "id=#{id}",
                                           "rv=#{rv}",
                                           "" ] if aptrust_service_debug_verbose
    return rv
  end

  def self.target_file_name( dir, filename, ext = '' ) # TODO: review
    return Pathname.new( filename + ext ) if dir.nil?
    if dir.is_a? String
      rv = File.join dir, filename + ext
    else
      rv = dir.join( filename + ext )
    end
    return rv
  end

  def self.track_deposit( id:, status:, status_history: nil, note: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "status=#{status}",
                                           "status_history=#{status_history}",
                                           "" ] if aptrust_service_debug_verbose
    # TODO
    status_history ||= []
    ::Deepblue::LoggingHelper.bold_error "AptrustService.track_deposit(#{id},#{status}) unknown status" unless STATUSES.include? status
    if note.blank?
      status_history << { id: id, status: status, timestamp: DateTime.now }
    else
      status_history << { id: id, status: status, timestamp: DateTime.now, note: note }
    end
    return status_history
  end

  def self.type( work )
    return "#{work.class.name}#{ID_SEP}"
  end

  def self.upload( filename:, id: 'uknown', status_history: nil  )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "filename=#{filename}",
                                           "id=#{id}",
                                           "status_history=#{status_history}",
                                           "" ], bold_puts: false if aptrust_service_debug_verbose
    status_history = [] if status_history.nil?
    success = false
    begin
      # add timing
      aptrust = load_config
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "aptrust['Bucket']=#{aptrust['Bucket']}",
                                             "aptrust['BucketRegion']=#{aptrust['BucketRegion']}",
                                             "aptrust['AwsAccessKeyId']=#{aptrust['AwsAccessKeyId']}",
                                             "aptrust['AwsSecretAccessKey']=#{aptrust['AwsSecretAccessKey']}",
                                             "" ], bold_puts: false if aptrust_service_debug_verbose
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
      Aws.config.update( credentials: Aws::Credentials.new( aptrust['AwsAccessKeyId'], aptrust['AwsSecretAccessKey'] ) )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
      s3 = Aws::S3::Resource.new( region: aptrust['BucketRegion'] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
      bucket = s3.bucket( aptrust['Bucket'] )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
      aws_object = bucket.object( File.basename(filename) )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
      status_history = track_deposit( id: id, status: 'uploading', status_history: status_history )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
      aws_object.upload_file( filename )
      success = true
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here ]
      status_history = track_deposit( id: id, status: 'uploaded', status_history: status_history )
    rescue Aws::S3::Errors::ServiceError => e
      status_history = track_deposit( id: id, status: 'failed', status_history: status_history, note: "failed in #{e.context} with error #{e}" )
      ::Deepblue::LoggingHelper.bold_error ["Upload of file #{filename} failed in #{e.context} with error #{e}"] + e.backtrace[0..20]
      Rails.logger.error "Upload of file #{filename} failed with error #{e}"
      success = false
    end
    success
  end

end
