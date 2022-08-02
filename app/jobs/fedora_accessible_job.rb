# frozen_string_literal: true

class FedoraAccessibleJob < ::Hyrax::ApplicationJob

  queue_as :scheduler

  mattr_accessor :fedora_accessible_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.fedora_accessible_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

fedora_accessible_job:
# Run every five minutes
#       M H D
  cron: '5 * * * *'
  class: FedoraAccessibleJob
  queue: scheduler
  description: Check fedora accessibility
  args:
    email_targets_when_not_accessible:
      - 'fritx@umich.edu'
    verbose: true

END_OF_SCHEDULER_ENTRY

  include JobHelper
  attr_accessor :email_targets_when_not_accessible, :verbose

  def self.perform( *args )
    FedoraAccessibleJob.perform_now( *args )
  end

  def perform( *args )
    initialize_options_from( *args, debug_verbose: fedora_accessible_job_debug_verbose )
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
