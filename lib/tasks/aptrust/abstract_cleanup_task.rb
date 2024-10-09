# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../../app/helpers/deepblue/disk_utilities_helper'

module Aptrust

  class AbstractCleanupTask < ::Aptrust::AbstractTask

    attr_accessor :exclude_if_processing

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
      @exclude_if_processing = option_value( key: 'exclude_if_processing', default_value: true )
      export_dir_init
      working_dir_init
    end

    def bag_dir( noid: )
      bag_id = bag_id( noid: noid )
      rv = File.join( working_dir, bag_id )
      rv
    end

    def bag_id( noid: )
      rv = ::Aptrust.aptrust_identifier( template:         ::Aptrust::IDENTIFIER_TEMPLATE,
                                         local_repository: aptrust_config.local_repository,
                                         context:          ::Aptrust::AptrustIntegrationService.deposit_context,
                                         type:             ::Aptrust::AptrustUploaderForWork.dbd_bag_id_type( work: nil ),
                                         noid:             noid )
      return rv
    end

    def cleanup_by_noid( noid: )
      bag_dir = bag_dir( noid: noid )
      msg_handler.msg_verbose "bag_dir: '#{bag_dir}'"
      status = status_for( noid: noid )
      msg_handler.msg_verbose "#{noid} status: #{status}"
      if exclude_by_status( status: status )
        msg_handler.msg_verbose "excluded by status: #{noid}"
        return
      end

      loop do # while false for break
        tar_filename = ::Aptrust::AptrustUploader.tar_filename( bag_dir: bag_dir )
        tar_file = File.join working_dir, tar_filename
        if File.exist? tar_file
          msg_handler.msg_verbose "delete tar file '#{tar_file}'"
          File.delete tar_file unless test_mode?
        end
        break if working_dir == export_dir
        tar_file = File.join export_dir, tar_filename
        break unless File.exist? tar_file
        msg_handler.msg_verbose "delete tar file '#{tar_file}'"
        File.delete tar_file unless test_mode?
      end # for break

      # recursively delete bag_dir
      return unless Dir.exists? bag_dir
      msg_handler.msg_verbose "delete bag_dir '#{bag_dir}'"
      ::Deepblue::DiskUtilitiesHelper.delete_dir( dir_path: bag_dir, msg_handler: msg_handler, recursive: true ) unless test_mode?
    end

    def exclude_by_status( noid: nil, status: nil )
      return false unless exclude_if_processing
      status = status_for( noid: noid ) if status.nil?
      rv = ::Aptrust::EVENTS_PROCESSING.include?( status )
      return rv
    end

    def export_dir_init
      return if @export_dir.present?
      @export_dir = aptrust_config.export_dir
      @export_dir = File.absolute_path @export_dir
    end

    def status_for( noid: )
      return "" if noid.blank?
      noid = noid.gsub( /_\d+/, "" ) unless nil == noid.index( "_" )
      status = ::Aptrust::Status.for_id( noid: noid )
      return "" if status.blank?
      return status[0].event
    end

    def working_dir_init
      return if @working_dir.present?
      @working_dir = aptrust_config.export_dir
      @working_dir = File.absolute_path @export_dir
    end

  end

end
