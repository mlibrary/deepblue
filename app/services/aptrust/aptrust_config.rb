# frozen_string_literal: true

require_relative './aptrust'

module Aptrust

  class AptrustConfig

    attr_accessor :aws_access_key_id
    attr_accessor :aws_secret_access_key
    attr_accessor :bucket
    attr_accessor :bucket_region

    def initialize( filename: nil )
      if filename.present?
        load( filename )
      else
        @aws_access_key_id = Settings.aptrust.aws_access_key_id
        @aws_secret_access_key = Settings.aptrust.aws_secret_access_key
        @bucket = Settings.aptrust.bucket
        @bucket_region = Settings.aptrust.bucket_region
      end
    end

    def load( filename )
      aptrust_config = YAML.safe_load( File.read( filename ) )
      @aws_access_key_id = aptrust_config['AwsAccessKeyId']
      @aws_secret_access_key = aptrust_config['AwsSecretAccessKey']
      @bucket = aptrust_config['Bucket']
      @bucket_region = aptrust_config['BucketRegion']
    end

  end

end
