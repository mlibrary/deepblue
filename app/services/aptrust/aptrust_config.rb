# frozen_string_literal: true

require_relative './aptrust'

module Aptrust

  class AptrustConfig

    attr_accessor :aws_access_key_id
    attr_accessor :aws_secret_access_key
    attr_accessor :bucket
    attr_accessor :bucket_region
    attr_accessor :context
    attr_accessor :repository

    def initialize( filename: nil )
      if filename.present?
        load( filename )
      else
        @aws_access_key_id = Settings.aptrust.aws_access_key_id
        @aws_secret_access_key = Settings.aptrust.aws_secret_access_key
        @bucket = Settings.aptrust.bucket
        @bucket_region = Settings.aptrust.bucket_region
        @context = Settings.aptrust.context
        @repository = Settings.aptrust.repository
      end
    end

    def load( filename )
      aptrust_config = YAML.safe_load( File.read( filename ) )
      @aws_access_key_id = aptrust_config['AwsAccessKeyId']
      @aws_secret_access_key = aptrust_config['AwsSecretAccessKey']
      @bucket = aptrust_config['Bucket']
      @bucket_region = aptrust_config['BucketRegion']
      @context = aptrust_config['Context']
      @repository = aptrust_config['Repository']
    end

  end

end
