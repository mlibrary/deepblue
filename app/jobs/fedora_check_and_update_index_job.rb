# frozen_string_literal: true

class FedoraCheckAndUpdateIndexJob < ::Deepblue::DeepblueJob

  mattr_accessor :fedora_check_and_update_index_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.heartbeat_email_job_debug_verbose

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

fedora_accessible_job:
# Run every five minutes
#       M H D
  cron: '5 * * * *'
  class: FedoraCheckAndUpdateIndexJob
  queue: scheduler
  description: Check fedora accessibility and update index by creating a new DataSet with a file.
  args:
    email_targets_when_not_accessible:
      - 'fritx@umich.edu'
    ingest_mode: 'populate'
    ingester: 'fritx@umich.edu'
    path_to_script: '/deepbluedata-prep/scripts/rebuild_fedora_index/rebuild_fedora_index.yml'
    verbose: true

  END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  include JobHelper
  attr_accessor :email_targets_when_not_accessible, :verbose

  def perform( *args )
    initialize_options_from( args: args, debug_verbose: fedora_check_and_update_index_job_debug_verbose )
    return if fedora_accessible?
    ingest_work_to_reindex_fedora
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    raise e
  end

  def email_fedora_not_accessible
    @email_targets_when_not_accessible = job_options_value( key: 'email_targets_when_not_accessible',
                                                            default_value: [] )
    subject = "DBD: Fedora not accessible on #{Rails.configuration.hostname} - reindexing"
    note =<<-END_NOTE
Reindexing: #{::Deepblue::LoggingHelper.timestamp_now}<br/>
path_to_script: #{@path_to_script}<br/>
    END_NOTE
    ::Deepblue::FedoraAccessibleService.email_fedora_not_accessible( targets: @email_targets_when_not_accessible,
                                                                     subject: subject,
                                                                     note: note  )
  end

  def fedora_accessible?
    rv = ::Deepblue::FedoraAccessibleService.fedora_accessible?
    return rv
  end

  def ingest_work_to_reindex_fedora
    # run this script:
    @path_to_script = job_options_value( key: 'path_to_script',
                           default_value: '/deepbluedata-prep/scripts/rebuild_fedora_index/rebuild_fedora_index.yml' )
    @ingester = job_options_value( key: 'ingester', default_value: 'fritx@umich.edu' )
    @populate = job_options_value( key: 'ingest_mode', default_value: 'populate' )
    email_fedora_not_accessible
    IngestScriptJob.perform_now( ingest_mode: @ingest_mode, ingester: @ingester, path_to_script: @path_to_script )
  end

end
