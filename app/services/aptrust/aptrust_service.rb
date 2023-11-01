# frozen_string_literal: true

module Aptrust

  # TODO: tracking of status of deposit

  class AptrustInfo

    mattr_accessor :aptrust_info_debug_verbose, default: true

    # mattr_accessor :default_description, default: 'This bag contains all of the data and metadata related to a Monograph which has been exported from the Fulcrum publishing platform hosted at https://www.fulcrum.org. The data folder contains a Fulcrum manifest in the form of a CSV file named with the NOID assigned to this Monograph in the Fulcrum repository. This manifest is exported directly from Fulcrum's heliotrope application (https://github.com/mlibrary/heliotrope) and can be used for re-import as well. The first two rows contain column headers and human-readable field descriptions, respectively. {{ The final row contains descriptive metadata for the Monograph; other rows contain metadata for Resources, which may be components of the Monograph or material supplemental to it.}}'
    mattr_accessor :default_description, default: 'The Description' # TODO

    attr_accessor :access
    attr_accessor :creator
    attr_accessor :description
    attr_accessor :item_description
    attr_accessor :storage_option
    attr_accessor :title

    def initialize( work:,
                    access: nil,
                    creator: nil,
                    description: nil,
                    item_description: nil,
                    storage_option: nil,
                    title: nil )

      @access = access; @access = attr_init( @access, 'Institution' )
      @creator = creator; @creator = attr_init( @item_description, work.creator.join( " & " ) )
      @description = description; @description ||= default_description
      @item_description = item_description; @item_description = attr_init( @item_description, work.description.join( " " ) )
      @storage_option = storage_option; @storage_option = attr_init( @storage_option, 'Standard' )
      @title = title; @title = attr_init( @title, Array( work.title ).join( " " ) )
    end

    def attr_init( attr, work_attr )
      attr ||= work_attr
      if attr.blank?
        attr = ''
      else
        attr = attr.squish[0..255]
      end
      return attr
    end

    def build
      <<~INFO
        Title: #{title}
        Access: #{access}
        Storage-Option: #{storage_option}
        Description: #{description}
        Item Description: #{item_description}
        Creator/Author: #{creator}
      INFO
    end

    def build_fulcrum
      # # Add aptrust-info.txt file
      # # this is text that shows up in the APTrust web interface
      # # title, access, and description are required; Storage-Option defaults to Standard if not present
      # monograph_presenter = Sighrax.hyrax_presenter(monograph)
      # title = monograph_presenter.title.blank? ? '' : monograph_presenter.title.squish[0..255]
      # publisher = monograph_presenter.publisher.blank? ? '' : monograph_presenter.publisher.first.squish[0..249]
      # press = monograph_presenter.press.blank? ? '' : monograph_presenter.press.squish[0..249]
      # description = monograph_presenter.description.first.blank? ? '' : monograph_presenter.description.first.squish[0..249]
      # creator = monograph_presenter.creator.blank? ? '' : monograph_presenter.creator.first.squish[0..249]
      <<~INFO
        Title: #{title}
        Access: #{institution}
        Storage-Option: #{storage_option}
        Description: #{description}
        Press-Name: #{publisher}
        Press: #{press}
        Item Description: #{description}
        Creator/Author: #{creator}
      INFO
    end

  end

  class AptrustService

    mattr_accessor :aptrust_service_debug_verbose, default: true

    EXT_TAR = '.tar'
    IDENTIFIER_TEMPLATE = "%repository%.%context%%type%%id%"
    ID_SEP = '-'
    CONTEXT = "" # none for DBD
    REPOSITORY = "deepbluedata"

    BAG_INFO_KEY_SOURCE = 'Source-Organization'
    BAG_INFO_KEY_COUNT = 'Bag-Count'
    BAG_INFO_KEY_DATE = 'Bag-Date'
    BAG_INFO_VALUE_SOURCE = 'University of Michigan'
    BAG_FILE_APTRUST_INFO = 'aptrust-info.txt'

    STATUSES = %w[ bagged bagging
                   deposit_skipped deposited depositing
                   exported exporting
                   failed
                   packed packing
                   skipped ]


    def self.allow_deposit?
      # TODO: check for service available
      return false
    end

    def self.allow_work?(work)
      return true # TODO: check size
      # return false unless monograph.is_a?(Sighrax::Monograph)
    end

    def self.aptrust_info( work: )
      AptrustInfo.new( work: work ).build
    end

    def self.aptrust_info_write( bag:, work: )
      aptrust_info = aptrust_info( work: work )
      File.write( File.join( bag.bag_dir, BAG_FILE_APTRUST_INFO ), aptrust_info, mode: 'w' )
    end

    def self.bag_export( working_dir: nil, work:, id: nil, status_history: nil )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "working_dir=#{working_dir}",
                                             "work=#{work}",
                                             "id=#{id}",
                                             "status_history=#{status_history}",
                                             "" ], bold_puts: false if aptrust_service_debug_verbose

      status_history = track_deposit( id: work.id, status: 'bagging', status_history: status_history )
      working_dir ||= dir_working
      id ||= identifier( work: work )
      working_dir = File.join( working_dir, id )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "working_dir=#{working_dir}",
                                             "work=#{work}",
                                             "id=#{id}",
                                             "" ], bold_puts: false if aptrust_service_debug_verbose
      Dir.mkdir( working_dir ) unless Dir.exist? working_dir
      bag = BagIt::Bag.new( working_dir )
      bag_info = bag_info( work: work )
      bag.write_bag_info( bag_info ) # Create bagit-info.txt file
      aptrust_info_write( bag: bag, work: work )
      bag_data_dir = File.join( bag.bag_dir, "data" )
      bag_data_dir = Pathname.new bag_data_dir
      export_work( work: work, target_dir: bag_data_dir )
      bag_manifest( bag: bag )
      status_history = track_deposit( id: work.id, status: 'bagged', status_history: status_history )
      working_dir
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

    def self.bag_manifest( bag: )
      bag.manifest!(algo: 'md5') # Create manifests

      # HELIO-4380 demo.aptrust.org doesn't like this file for some reason, gives an ingest error:
      # "Bag contains illegal tag manifest 'sha1'""
      # APTrust only wants SHA256, or MD5, not SHA1.
      # 'tagmanifest-sha1.txt' is a bagit gem default, so we need to remove it manually.
      sha1tag = File.join( bag.bag_dir, 'tagmanifest-sha1.txt' )
      File.delete(sha1tag) if File.exist?(sha1tag)

    end

    def self.deposit( filename:, id:, status_history: nil  ) # TODO: review and code
      success = false
      if !allow_deposit?
        status_history = track_deposit( id: id, status: 'deposit_skipped', status_history: status_history )
      else
        begin
        #   aptrust_yaml = Rails.root.join('config', 'aptrust.yml')
        #   aptrust = YAML.safe_load(File.read(aptrust_yaml))
        #   Aws.config.update(credentials: Aws::Credentials.new(aptrust['AwsAccessKeyId'], aptrust['AwsSecretAccessKey']))
        #   s3 = Aws::S3::Resource.new(region: aptrust['BucketRegion'])
        #   success = s3.bucket(aptrust['Bucket']).object(File.basename(filename)).upload_file(filename)
        rescue Aws::S3::Errors::ServiceError => e
        #   Rails.logger.error "Upload of file #{filename} failed in #{e.context} with error #{e}"
        #   success = false
        end
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

    def self.identifier( work: )
      rv = IDENTIFIER_TEMPLATE
      rv = rv.gsub( /\%repository\%/, REPOSITORY )
      rv = rv.gsub( /\%context\%/, CONTEXT )
      rv = rv.gsub( /\%type\%/, type( work ) )
      rv = rv.gsub( /\%id\%/, work.id )
      return rv
    end

    def self.perform_deposit( id, status_history: nil  )
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
        work = find_work( id )
        work_dir = bag_export( work: work, status_history: status_history )
        tar_file = tar( dir: work_dir, id: id, status_history: status_history )
        # TODO: move tar_file to dir_export
        # TODO: delete untarred file
        # FileUtils.mv( @ingest_script_path, new_path )
        deposit( filename: tar_file, id: id, status_history: status_history )
      rescue StandardError => e
        ::Deepblue::LoggingHelper.bold_error ["AptrustService.perform_deposit(#{id}) error #{e}"] + e.backtrace[0..20]
        status_history = track_deposit( id: id, status: 'failed', status_history: status_history )
      end
      return status_history
    end

    def self.tar( dir:, id:, status_history: nil  )
      tar_file = dir + EXT_TAR
      status_history = track_deposit( id: id, status: 'packing', status_history: status_history )
      Minitar.pack( dir, File.open( tar_file, 'wb') )
      status_history = track_deposit( id: id, status: 'packed', status_history: status_history )
      tar_file
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

  end

end
