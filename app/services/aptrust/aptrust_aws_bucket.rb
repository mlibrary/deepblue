# frozen_string_literal: true

require_relative './aptrust'

class Aptrust::AptrustAwsBucket

  mattr_accessor :aptrust_aws_bucket_debug_verbose, default: false

  attr_accessor :aptrust_config
  attr_accessor :bucket
  attr_accessor :files

  def initialize( aptrust_config: nil )
    @aptrust_config = aptrust_config
  end

  def aptrust_config
    @aptrust_config ||= aptrust_config_init
  end

  def aptrust_config_init
    rv = ::Aptrust::AptrustConfig.new
    return rv
  end

  def bucket
    @bucket ||= bucket_init
  end

  def bucket_init
    config = aptrust_config
    Aws.config.update( credentials: Aws::Credentials.new( config.aws_access_key_id, config.aws_secret_access_key ) )
    s3 = Aws::S3::Resource.new( region: config.bucket_region )
    rv = s3.bucket( config.bucket )
    return rv
  end

  def bucket_list( prefix: nil )
    if prefix.blank?
      objects = bucket.objects
    else
      objects = bucket.objects( prefix: prefix )
    end
    rv = []
    objects.each { |o| rv << o.key };true
    return rv
  end

  def bucket_list_local_repository
    rv = bucket_list( prefix: aptrust_config.local_repository )
    return rv
  end

  def bucket_contains( noid:, type: 'DataSet' )
    id = aptrust_config.identifier( id_context: aptrust_config.context, noid: noid, type: "#{type}." )
    list = bucket_list( prefix: id )
    rv = list.size > 0
    return rv
  end

  def files
    @files ||= []
  end

  def files_from_local_repository
    @files = bucket_list_local_repository
  end

end
