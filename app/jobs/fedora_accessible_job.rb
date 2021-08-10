# frozen_string_literal: true

class FedoraAccessibleJob < ::Hyrax::ApplicationJob

  queue_as :scheduler

  mattr_accessor :fedora_accessible_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.fedora_accessible_job_debug_verbose

  EXAMPLE_SCHEDULER_ENTRY = <<-END_OF_EXAMPLE_SCHEDULER_ENTRY

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

END_OF_EXAMPLE_SCHEDULER_ENTRY

  attr_accessor :email_targets_when_not_accessible, :verbose

  def self.perform( *args )
    FedoraAccessibleJob.perform_now( *args )
  end

  def perform( *args )
    return if ::Deepblue::FedoraAccessibleService.fedora_accessible?
    email_fedora_not_accessible( *args )
  rescue
    email_fedora_not_accessible( *args )
  end

  def email_fedora_not_accessible( *args )
    options = ::Deepblue::JobTaskHelper.options_from_args( *args )
    @verbose = options_value( options, key: 'verbose', default_value: false )
    @email_targets_when_not_accessible = options_value( options,
                                                        key: 'email_targets_when_not_accessible',
                                                        default_value: [] )
    ::Deepblue::FedoraAccessibleService.email_fedora_not_accessible( targets: @email_targets_when_not_accessible )
  end

  def options_value( options, key:, default_value: nil )
    ::Deepblue::JobTaskHelper.options_value( options, key: key, default_value: default_value, verbose: false )
  end

end
