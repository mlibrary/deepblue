# frozen_string_literal: true

class IngestJob < ::Hyrax::ApplicationJob
  # monkey patch

  queue_as Hyrax.config.ingest_queue_name

  after_perform do |job|
    # We want the lastmost Hash, if any.
    opts = job.arguments.reverse.detect { |x| x.is_a? Hash } || {}
    wrapper = job.arguments.first
    ContentNewVersionEventJob.perform_later(wrapper.file_set, wrapper.user) if opts[:notification]
  end

  # @param [JobIoWrapper] wrapper
  # @param [Boolean] notification send the user a notification, used in after_perform callback
  # @see 'config/initializers/hyrax_callbacks.rb'
  # rubocop:disable Lint/UnusedMethodArgument
  def perform( wrapper,
               notification: false,
               continue_job_chain: true,
               continue_job_chain_later: true,
               delete_input_file: true,
               uploaded_file_ids: [] )

    uploaded_file = wrapper.uploaded_file
    Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           "wrapper=#{wrapper}",
                                           # Deepblue::LoggingHelper.obj_methods( "wrapper", wrapper ),
                                           Deepblue::LoggingHelper.obj_to_json( "wrapper", wrapper ),
                                           "notification=#{notification}",
                                           "continue_job_chain=#{continue_job_chain}",
                                           "continue_job_chain_later=#{continue_job_chain_later}",
                                           "delete_input_file=#{delete_input_file}",
                                           "uploaded_file=#{uploaded_file}",
                                           # Deepblue::LoggingHelper.obj_methods( "uploaded_file", uploaded_file ),
                                           # Deepblue::LoggingHelper.obj_instance_variables( "uploaded_file", uploaded_file ),
                                           # Deepblue::LoggingHelper.obj_attribute_names( "uploaded_file", uploaded_file ),
                                           Deepblue::LoggingHelper.obj_to_json( "uploaded_file", uploaded_file ),
                                           "uploaded_file.id=#{Deepblue::UploadHelper.uploaded_file_id( uploaded_file )}",
                                           "uploaded_file_ids=#{uploaded_file_ids}",
                                           "" ]
    wrapper.ingest_file( continue_job_chain: continue_job_chain,
                         continue_job_chain_later: continue_job_chain_later,
                         delete_input_file: delete_input_file,
                         uploaded_file_ids: uploaded_file_ids )
  end

end
