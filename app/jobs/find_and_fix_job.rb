# frozen_string_literal: true

require "abstract_rake_task_job"
require "find_and_fix_empty_file_sizes_behavior"
require "find_and_fix_ordered_members_behavior"

class FindAndFixJob < AbstractRakeTaskJob
  include FindAndFixEmptyFileSizesBehavior
  include FindAndFixOrderedMembersBehavior

  # bundle exec rake deepblue:run_job['{"job_class":"FindAndFixJob"\,"verbose":true\,"email_results_to":["fritx@umich.edu"]\,"job_delay":0}']

  FIND_AND_FIX_JOB_DEBUG_VERBOSE = true

  # queue_as :scheduler

EXAMPLE_SCHEDULER_ENTRY = <<-END_OF_EXAMPLE_SCHEDULER_ENTRY

find_and_fix_job:
# Run once a day, 15 minutes after midnight (which is offset by 4 or [5 during daylight savings time], due to GMT)
#       M H D
  cron: '15 5 1 * *'
  class: FindAndFixJob
  queue: scheduler
  description: Find and fix problems
  args:
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    email_results_to:
      - 'fritx@umich.edu'
    find_and_fix_empty_file_size: true
    find_and_fix_all_ordered_members_containing_nils: true
    verbose: true 

END_OF_EXAMPLE_SCHEDULER_ENTRY

  def self.perform( *args )
    RakeTaskJob.perform_now( *args )
  end

  def perform( *args )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "args=#{args}",
                                           "" ] if FIND_AND_FIX_JOB_DEBUG_VERBOSE
    initialized = initialize_from_args( *args )
    find_and_fix_empty_file_size = job_options_value( options,
                                                      key: 'find_and_fix_empty_file_size',
                                                      default_value: true,
                                                      verbose: verbose )
    find_and_fix_all_ordered_members_containing_nils = job_options_value( options,
                                                      key: 'find_and_fix_all_ordered_members_containing_nils',
                                                      default_value: true,
                                                      verbose: verbose )
    ::Deepblue::SchedulerHelper.log( class_name: self.class.name )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "options=#{options}",
                                           "job_options_keys_found=#{job_options_keys_found}",
                                           "verbose=#{verbose}",
                                           "hostnames=#{hostnames}",
                                           "email_results_to=#{email_results_to}",
                                           "initialized=#{initialized}",
                                           "job_delay=#{job_delay}",
                                           "find_and_fix_empty_file_size=#{find_and_fix_empty_file_size}",
                                           "find_and_fix_all_ordered_members_containing_nils=#{find_and_fix_all_ordered_members_containing_nils}",
                                           "" ] if FIND_AND_FIX_JOB_DEBUG_VERBOSE
    return unless initialized
    run_job_delay
    if find_and_fix_empty_file_size
      file_set_ids_fixed = []
      find_and_fix_empty_file_sizes( messages: msg_queue, ids_fixed: file_set_ids_fixed, verbose: verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "timestamp_end=#{timestamp_end}",
                                             "msg_queue=#{msg_queue}",
                                             "file_set_ids_fixed=#{file_set_ids_fixed}",
                                             "" ] if FIND_AND_FIX_JOB_DEBUG_VERBOSE
    end
    if find_and_fix_all_ordered_members_containing_nils
      curation_concern_ids_fixed = []
      find_and_fix_all_ordered_members_containing_nils( messages: msg_queue,
                                                        ids_fixed: curation_concern_ids_fixed,
                                                        verbose: verbose )
      ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                             ::Deepblue::LoggingHelper.called_from,
                                             "msg_queue=#{msg_queue}",
                                             "curation_concern_ids_fixed=#{curation_concern_ids_fixed}",
                                             "" ] if FIND_AND_FIX_JOB_DEBUG_VERBOSE
    end
    timestamp_end = DateTime.now
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "msg_queue=#{msg_queue}",
                                           "timestamp_end=#{timestamp_end}",
                                           "" ] if FIND_AND_FIX_JOB_DEBUG_VERBOSE
    email_results( task_name: "Find and Fix", event: 'find and fix job' )
  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace[0..20].join("\n")
    email_failure( task_name: "find and fix job", exception: e, event: 'find and fix' )
    raise e
  end

  # def self.queue
  #   :default
  # end

end
