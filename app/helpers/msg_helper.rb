# frozen_string_literal: true

module MsgHelper
  extend ActionView::Helpers::TranslationHelper

  mattr_accessor :msg_helper_debug_verbose, default: false

  FIELD_SEP = '; ' unless const_defined? :FIELD_SEP

  def self.creator( curation_concern, field_sep: FIELD_SEP )
    curation_concern.creator.join( field_sep )
  end

  def self.description( curation_concern, field_sep: FIELD_SEP )
    curation_concern.description.join( field_sep )
  end

  def self.display_now
    DeepblueHelper.display_timestamp DateTime.now
  end

  def self.globus_link( curation_concern )
    ::Deepblue::GlobusService.globus_external_url curation_concern.id
  end

  def self.msg_handler( debug_verbose: ::Deepblue::MessageHandler::DEFAULT_DEBUG_VERBOSE,
                        msg_prefix: ::Deepblue::MessageHandler::DEFAULT_MSG_PREFIX,
                        msg_queue: [],
                        to_console: ::Deepblue::MessageHandler::DEFAULT_TO_CONSOLE,
                        verbose: ::Deepblue::MessageHandler::DEFAULT_VERBOSE )

    ::Deepblue::MessageHandler.new( debug_verbose: debug_verbose,
                                    msg_prefix: msg_prefix,
                                    msg_queue: msg_queue,
                                    to_console: to_console,
                                    verbose: verbose )
  end

  def self.msg_handler_for( task:,
                            debug_verbose: ::Deepblue::MessageHandler::DEFAULT_DEBUG_VERBOSE,
                            msg_prefix: ::Deepblue::MessageHandler::DEFAULT_MSG_PREFIX,
                            msg_queue: [],
                            to_console: ::Deepblue::MessageHandler::DEFAULT_TO_CONSOLE,
                            verbose: ::Deepblue::MessageHandler::DEFAULT_VERBOSE )

    ::Deepblue::MessageHandler.msg_handler_for( task: task,
                                                debug_verbose: debug_verbose,
                                                msg_prefix: msg_prefix,
                                                msg_queue: msg_queue,
                                                to_console: to_console,
                                                verbose: verbose )
  end

  def self.msg_handler_for_job( msg_queue: [], options: {} )
    ::Deepblue::MessageHandler.msg_handler_for_job( msg_queue: msg_queue, options: options )
  end

  def self.msg_handler_for_task( msg_queue: nil, options: {} )
    ::Deepblue::MessageHandler.msg_handler_for_task( msg_queue: msg_queue, options: options )
  end

  def self.msg_handler_null( debug_verbose: false,
                             msg_prefix: false,
                             msg_queue: nil,
                             to_console: false,
                             verbose: false  )

    ::Deepblue::MessageHandler.msg_handler_null( debug_verbose: debug_verbose,
                                                 msg_prefix: msg_prefix,
                                                 msg_queue: msg_queue,
                                                 to_console: to_console,
                                                 verbose: verbose )
  end

  # def file_msg_handler(task);  ::Deepblue::MessageHandlerQueueToFile.msg_handler_for( task: true, verbose: true, debug_verbose: false, msg_queue_file: "./log/%timestamp%.#{task}.log" ); end

  def self.msg_handler_queue_to_file( task: true,
                                      task_id: nil,
                                      msg_queue_file: nil,
                                      append: false,
                                      debug_verbose: ::Deepblue::MessageHandler::DEFAULT_DEBUG_VERBOSE,
                                      msg_prefix: ::Deepblue::MessageHandler::DEFAULT_MSG_PREFIX,
                                      to_console: ::Deepblue::MessageHandler::DEFAULT_TO_CONSOLE,
                                      verbose: ::Deepblue::MessageHandler::DEFAULT_VERBOSE )

    ::Deepblue::MessageHandlerQueueToFile.msg_handler_for( task: task,
                                                           task_id: task_id,
                                                           msg_queue_file: msg_queue_file,
                                                           append: append,
                                                           debug_verbose: debug_verbose,
                                                           msg_prefix: msg_prefix,
                                                           to_console: to_console,
                                                           verbose: verbose )
  end

  def self.publisher( curation_concern, field_sep: FIELD_SEP )
    curation_concern.publisher.join( field_sep )
  end

  def self.subject_discipline( curation_concern, field_sep: FIELD_SEP )
    curation_concern.subject_discipline.join( field_sep )
  end

  def self.title( curation_concern, field_sep: FIELD_SEP )
    curation_concern.title.join( field_sep )
  end

  def self.work_location( curation_concern: nil )
    # Rails.application.routes.url_helpers.hyrax_data_set_url( id: curation_concern.id )
    # Rails.application.routes.url_helpers.url_for( only_path: false,
    #                                               action: 'show',
    #                                               host: "http://todo.com",
    #                                               controller: 'concern/data_sets',
    #                                               id: id )
    "work location for: #{curation_concern.class.name} #{curation_concern.id}"
  end

end
