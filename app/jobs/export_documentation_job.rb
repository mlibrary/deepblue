# frozen_string_literal: true

require_relative "../../lib/tasks/yaml_populate_for_collection"

class ExportDocumentationJob < ::Deepblue::DeepblueJob

  mattr_accessor :export_documentation_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.export_documentation_job_debug_verbose

  queue_as :default

  SCHEDULER_ENTRY = <<-END_OF_SCHEDULER_ENTRY

export_log_files_job:
  # Run once a week at midnight
  #      M H D
  # cron: '*/5 * * * *'
  cron: '0 5 * * 0'
  class: ExportDocumentationJob
  queue: default
  description: Export documentation.
  args:
    by_request_only: true
    hostnames:
      - 'deepblue.lib.umich.edu'
      - 'staging.deepblue.lib.umich.edu'
      - 'testing.deepblue.lib.umich.edu'
    verbose: false

  END_OF_SCHEDULER_ENTRY

  def perform( id: ::Deepblue::WorkViewContentService.content_documentation_collection_id,
               export_path: ::Deepblue::WorkViewContentService.export_documentation_path,
               user_email: nil )
    initialize_with( debug_verbose: export_documentation_job_debug_verbose )
    @from_dashboard = user_email
    # initialize_options_from( *args, debug_verbose: export_documentation_job_debug_verbose )
    # export_path = job_options_value( options, key: 'export_path', default_value: nil )
    # id = options[:id]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "export_path=#{export_path}",
                                           "email_targets=#{email_targets}",
                                           "" ] if export_documentation_job_debug_verbose
    task_options = { "target_dir" => export_path,
                     "export_files" => true,
                     "mode" => "build" }
    log( event: "export documentation job", **task_options )
    task = ::Deepblue::YamlPopulateFromCollection.new( id: id, options: task_options, msg_queue: job_msg_queue )
    task.run
    email_all_targets( task_name: "export documentation",
                       event: "export documentation" ,
                       body: job_msg_queue.join("\n"),
                       debug_verbose: export_documentation_job_debug_verbose )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    email_all_targets( task_name: "export documentation",
                       event: "export documentation" ,
                       body: job_msg_queue.join("\n") + e.message + "\n" + e.backtrace.join("\n"),
                       debug_verbose: export_documentation_job_debug_verbose )
    job_status_register( exception: e, args: { id: id, export_path: export_path, user_email: user_email } )
    raise e
  end

end
