# frozen_string_literal: true

require_relative './abstract_task'
require_relative '../../../app/helpers/deepblue/disk_utilities_helper'

module Aptrust

  class AbstractCleanupTask < ::Aptrust::AbstractTask

    def initialize( msg_handler: nil, options: {} )
      super( msg_handler: msg_handler, options: options )
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

    def export_dir_init
      return if @export_dir.present?
      @export_dir = aptrust_config.export_dir
      @export_dir = File.absolute_path @export_dir
    end

    def cleanup_by_noid( noid: )
      bag_dir = bag_dir( noid: noid )
      msg_handler.msg_verbose "bag_dir: '#{bag_dir}'"

      # tar_file_list = File.join bag_dir, '.files'
      # if File.exist? tar_file_list
      #   msg_handler.msg_verbose "delete tar file list '#{tar_file_list}'"
      #   File.delete tar_file_list unless test_mode?
      # end

      tar_filename = ::Aptrust::AptrustUploader.tar_filename( bag_dir: bag_dir )
      tar_file = File.join working_dir, tar_filename
      if File.exist? tar_file
        msg_handler.msg_verbose "delete tar file '#{tar_file}'"
        File.delete tar_file unless test_mode?
      end
      tar_file = File.join export_dir, tar_filename
      if File.exist? tar_file
        msg_handler.msg_verbose "delete tar file '#{tar_file}'"
        File.delete tar_file unless test_mode?
      end

      # recursively delete bag_dir
      if Dir.exists? bag_dir
        msg_handler.msg_verbose "delete bag_dir '#{bag_dir}'"
        ::Deepblue::DiskUtilitiesHelper.delete_dir( bag_dir, msg_handler: msg_handler, recursive: true ) unless test_mode?
      end
    end

    def working_dir_init
      return if @working_dir.present?
      @working_dir = aptrust_config.export_dir
      @working_dir = File.absolute_path @export_dir
    end

  end

end
