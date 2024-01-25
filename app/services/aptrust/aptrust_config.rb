# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustConfig

  mattr_accessor :aptrust_config_debug_verbose, default: false

  attr_accessor :aws_access_key_id
  attr_accessor :aws_secret_access_key
  attr_accessor :bucket
  attr_accessor :bucket_region
  attr_accessor :context
  attr_accessor :repository
  attr_accessor :local_repository

  attr_accessor :aptrust_api_url
  attr_accessor :aptrust_api_user
  attr_accessor :aptrust_api_key

  attr_accessor :download_dir
  attr_accessor :export_dir
  attr_accessor :working_dir

  attr_accessor :storage_option

  def initialize( filename: nil )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "filename=#{filename}",
                                           "" ] if aptrust_config_debug_verbose
    if filename.present?
      load( filename )
    else
      @aws_access_key_id        = Settings.aptrust.aws_access_key_id
      @aws_secret_access_key    = Settings.aptrust.aws_secret_access_key
      @bucket                   = Settings.aptrust.bucket
      @bucket_region            = Settings.aptrust.bucket_region
      @context                  = Settings.aptrust.context
      @repository               = Settings.aptrust.repository
      @local_repository         = Settings.aptrust.local_repository
      @aptrust_api_download_dir = Settings.aptrust.aptrust_api_download_dir
      @aptrust_api_url          = Settings.aptrust.aptrust_api_url
      @aptrust_api_user         = Settings.aptrust.aptrust_api_user
      @aptrust_api_key          = Settings.aptrust.aptrust_api_key
      @download_dir             = Settings.aptrust.download_dir
      @export_dir               = Settings.aptrust.export_dir
      @working_dir              = Settings.aptrust.working_dir
      @storage_option           = Settings.aptrust.storage_option
    end
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "self.pretty_inspect=#{self.pretty_inspect}",
                                           "" ] if aptrust_config_debug_verbose
  end

  def identifier( template: nil, type:, noid: )
    rv = template
    rv ||= ::Aptrust::IDENTIFIER_TEMPLATE
    rv = rv.gsub( /\%local_repository\%/, local_repository )
    rv = rv.gsub( /\%context\%/, context )
    rv = rv.gsub( /\%type\%/, type )
    rv = rv.gsub( /\%id\%/, noid )
    return rv
  end

  def load( filename )
    aptrust_config = YAML.safe_load( File.read( filename ) )
    @aws_access_key_id        = aptrust_config['AwsAccessKeyId']
    @aws_secret_access_key    = aptrust_config['AwsSecretAccessKey']
    @bucket                   = aptrust_config['Bucket']
    @bucket_region            = aptrust_config['BucketRegion']
    @context                  = aptrust_config['Context']
    @repository               = aptrust_config['Repository']
    @local_repository         = aptrust_config['LocalRepository']
    @download_dir             = aptrust_config['DownloadDir']
    @aptrust_api_url          = aptrust_config['AptrustApiUrl']
    @aptrust_api_user         = aptrust_config['AptrustApiUser']
    @aptrust_api_key          = aptrust_config['AptrustApiKey']
  end

end
