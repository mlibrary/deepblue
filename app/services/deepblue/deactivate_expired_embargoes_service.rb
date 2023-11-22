# frozen_string_literal: true

module Deepblue

  require_relative '../../tasks/deepblue/abstract_task'
  require_relative '../../helpers/hyrax/embargo_helper'

  class DeactivateExpiredEmbargoesService

    mattr_accessor :deactivate_expired_embargoes_service_debug_verbose, default: false

    include ::Hyrax::EmbargoHelper

    attr_accessor :job_msg_queue

    def initialize( email_owner: true,
                    job_msg_queue: nil,
                    skip_file_sets: true,
                    test_mode: true,
                    to_console: false,
                    verbose: false )

      LoggingHelper.bold_debug [ LoggingHelper.here,
                                  LoggingHelper.called_from,
                                 "email_owner=#{email_owner}",
                                 "job_msg_queue=#{job_msg_queue}",
                                 "skip_file_sets=#{skip_file_sets}",
                                 "test_mode=#{test_mode}",
                                 "to_console=#{to_console}",
                                 "verbose=#{verbose}",
                                 "" ] if deactivate_expired_embargoes_service_debug_verbose
      @email_owner = email_owner
      @job_msg_queue = job_msg_queue
      @skip_file_sets = skip_file_sets
      @test_mode = test_mode
      @to_console = to_console
      @verbose = verbose
    end

    def run
      LoggingHelper.bold_debug [ LoggingHelper.here,
                                 LoggingHelper.called_from,
                                 LoggingHelper.obj_class( 'class', self ),
                                 "@email_owner=#{@email_owner}",
                                 "@skip_file_sets=#{@skip_file_sets}",
                                 "@test_mode=#{@test_mode}",
                                 "" ] if deactivate_expired_embargoes_service_debug_verbose
      @now = DateTime.now
      @assets = Array( assets_with_expired_embargoes )
      run_msg "The number of assets with expired embargoes is: #{@assets.size}" if @verbose
      # puts
      @assets.each_with_index do |asset,i|
        next if @skip_file_sets && "FileSet" == asset.model_name
        run_msg "#{i} - #{asset.id}, #{asset.model_name}, #{asset.human_readable_type}, #{asset.solr_document.title} #{asset.embargo_release_date}, #{asset.visibility_after_embargo}" if @verbose
        model = ::PersistHelper.find asset.id
        deactivate_embargo( curation_concern: model,
                            copy_visibility_to_files: true,
                            current_user: Deepblue::ProvenanceHelper.system_as_current_user,
                            email_owner: @email_owner,
                            test_mode: @test_mode,
                            verbose: @verbose )
      end
    end

    def run_msg( msg )
      LoggingHelper.debug msg
      puts msg if @to_console
      @job_msg_queue << msg unless @job_msg_queue.nil?
    end

  end

end
