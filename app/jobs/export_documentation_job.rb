# frozen_string_literal: true

require_relative "../../lib/tasks/yaml_populate_for_collection"

class ExportDocumentationJob < ::Deepblue::DeepblueJob

  mattr_accessor :export_documentation_job_debug_verbose,
                 default: ::Deepblue::JobTaskHelper.export_documentation_job_debug_verbose

  queue_as :default

  def perform( *args )
    initialize_options_from( *args, debug_verbose: export_documentation_job_debug_verbose )
    log( event: "export documentation job" )
    id = options[:id]
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "id=#{id}",
                                           "export_path=#{export_path}",
                                           "email_targets=#{email_targets}",
                                           "" ] if export_documentation_job_debug_verbose
    task_options = { "target_dir" => export_path,
                     "export_files" => true,
                     "mode" => "build" }
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
                       body: job_msg_queue.join("\n") + e.backtrace.join("\n"),
                       debug_verbose: export_documentation_job_debug_verbose )
    job_status_register( exception: e, args: args )
    raise e
  end

end