# frozen_string_literal: true

class UserStatImporterJob < ::Deepblue::DeepblueJob

  mattr_accessor :user_stat_importer_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.user_stat_importer_job_debug_verbose

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

user_stat_importer_job:
  # Run once a day, thirty minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
  #      M  H
  cron: '30 5 * * *'
  # rails_env: production
  class: UserStatImporterJob
  queue: scheduler
  description: Import user stats job.
  args:
    test: false
    hostnames:
      - 'deepblue.lib.umich.edu'
    verbose: false

END_OF_SCHEDULER_ENTRY


  queue_as :scheduler

  EVENT = "user stat importer"

  def perform( *args )
    initialize_options_from( args: args, id: id, debug_verbose: user_stat_importer_job_debug_verbose )
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name, event: EVENT, hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    test = job_options_value( key: 'test', default_value: true )
    echo_to_stdout = job_options_value( key: 'echo_to_stdout', default_value: false )
    logging = job_options_value( key: 'logging', default_value: false )
    number_of_retries = job_options_value( key: 'number_of_retries', default_value: nil )
    delay_secs = job_options_value( key: 'delay_secs', default_value: nil )
    importer = Hyrax::UserStatImporter.new( echo_to_stdout: echo_to_stdout,
                                            verbose: verbose,
                                            delay_secs: delay_secs,
                                            logging: logging,
                                            number_of_retries: number_of_retries,
                                            test: test )
    importer.import
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

end
