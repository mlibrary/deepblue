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
    verbose: true

  END_OF_SCHEDULER_ENTRY

  queue_as :scheduler

  include JobHelper
  attr_accessor :email_targets_when_not_accessible, :verbose

  def perform( *args )
    initialize_options_from( *args, debug_verbose: fedora_check_and_update_index_job_debug_verbose )
    return if ::Deepblue::FedoraAccessibleService.fedora_accessible?
    email_fedora_not_accessible( *args )
    job_finished
  rescue
    email_fedora_not_accessible( *args )
  end

  def email_fedora_not_accessible( *args )
    @email_targets_when_not_accessible = job_options_value( key: 'email_targets_when_not_accessible',
                                                            default_value: [] )
    ::Deepblue::FedoraAccessibleService.email_fedora_not_accessible( targets: @email_targets_when_not_accessible )
  end

end
