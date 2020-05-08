# frozen_string_literal: true

class ExportDocumentationJob < ::Hyrax::ApplicationJob
  include JobHelper
  queue_as :default

  def perform( id:, target_path:, **options )
    ::Deepblue::LoggingHelper.bold_debug [ Deepblue::LoggingHelper.here,
                                           Deepblue::LoggingHelper.called_from,
                                           Deepblue::LoggingHelper.obj_class( 'class', self ),
                                           "id=#{id}",
                                           "target_path=#{target_path}",
                                           "options=#{options}",
                                           Deepblue::LoggingHelper.obj_class( 'options', options ),
                                           "" ]
    options = { "target_dir" => target_path,
                "export_files" => true,
                "mode" => "build" }
    task = ::Deepblue::YamlPopulateFromCollection.new( id: id, options: options )
    task.run

  rescue Exception => e # rubocop:disable Lint/RescueException
    Rails.logger.error "#{e.class} #{e.message} at #{e.backtrace[0]}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

end