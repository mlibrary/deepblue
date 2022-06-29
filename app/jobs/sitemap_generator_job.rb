# frozen_string_literal: true

require_relative '../services/deepblue/sitemap_generator_service'

class SitemapGeneratorJob < ::Deepblue::DeepblueJob

  mattr_accessor :sitemap_generator_job_debug_verbose, default: false

SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

sitemap_generator_job:
  # Run once a week at midnight
  #      M H D
  # cron: '*/5 * * * *'
  cron: '0 5 * * 0'
  class: SitemapGeneratorJob
  queue: default
  description: Sitemap generator job.
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'

END_OF_SCHEDULER_ENTRY

  queue_as :default

  EVENT = 'sitemap generator'

  def perform( *args )
    initialize_options_from( *args, debug_verbose: sitemap_generator_job_debug_verbose )
    log( event: "sitemap generator job", hostname_allowed: hostname_allowed? )
    return job_finished unless hostname_allowed?
    Deepblue::SitemapGeneratorService.generate_sitemap
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: args )
    email_failure( task_name: self.class.name, exception: e, event: self.class.name )
    raise
  end

end
