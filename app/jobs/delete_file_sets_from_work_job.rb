# frozen_string_literal: true

# Converts UploadedFiles into FileSets and attaches them to works.
class DeleteFileSetsFromWorkJob < ::Deepblue::DeepblueJob
  include Rails.application.routes.url_helpers

  include ::Hyrax::Lockable

  #queue_as Hyrax.config.ingest_queue_name

  EVENT = "DeleteFileSetsFromWorkJob"

  mattr_accessor :delete_files_from_work_job_debug_verbose,
                 default: ::Deepblue::IngestIntegrationService.delete_file_sets_from_work_job_debug_verbose

  attr_accessor :file_set_ids,
                :user_key,
                :work

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform( work:, file_set_ids:, user_key: )
    debug_verbose = delete_files_from_work_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work.id=#{work.id}",
                                           "user_key=#{user_key}",
                                           "file_set_ids=#{file_set_ids}",
                                           "" ] if debug_verbose
    initialize_with( id: work.id, debug_verbose: debug_verbose )
    @work = work
    @user_key = user_key
    @current_user = nil
    @file_set_ids = Array( file_set_ids )
    email_targets << user_key
    perform_delete
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "work.id=#{work.id}",
                                           "user_key=#{user_key}",
                                           "file_set_ids=#{file_set_ids}",
                                           "" ] + msg_handler.msg_queue if debug_verbose
    email_all_targets( task_name: EVENT, event: EVENT )
    job_finished
  rescue Exception => e # rubocop:disable Lint/RescueException
    job_status_register( exception: e, args: [ work.id, file_set_ids, user_key ] )
    email_failure( task_name: EVENT, exception: e, event: EVENT )
    raise e
  end

  def perform_delete
    debug_verbose = delete_files_from_work_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if debug_verbose
    msg_handler.msg( "work.id=#{work.id}" )
    # lock the work
    acquire_lock_for( work.id ) do
      file_set_ids.each do |fsid|
        begin
          fs = FileSet.find fsid
          msg_handler.msg( "Delete file set #{fsid} - #{fs.label} ..." )
          provenance_log_destroy( fs )
          fs.delete
          msg_handler.msg( "deleted." )
          # catch errors and LDP gone
        rescue Ldp::Gone => gone
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "#{e.class} -- FileSet id #{fsid}, work_id=#{work.id} -- #{e.message} at #{e.backtrace[0]}",
                                                 "" ] if debug_verbose
          msg_handler.msg( "Already deleted: FileSet id #{fsid}" )
        rescue Exception => e # rubocop:disable Lint/RescueException
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "#{e.class} -- FileSet id #{fsid}, work_id=#{work.id} -- #{e.message} at #{e.backtrace[0]}",
                                                 "" ] if debug_verbose
          msg_handler.msg( "#{e.class} -- FileSet id #{fsid}, work_id=#{work.id} -- #{e.message} at #{e.backtrace[0]}" )
        end
      end
    end
  end

  def current_user
    if @current_user.blank?
      @current_user = User.find_by_user_key( user_key )
    end
    return @current_user
  end

  def provenance_log_destroy( file_set )
    debug_verbose = delete_files_from_work_job_debug_verbose
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if debug_verbose
    file_set.provenance_destroy( current_user: current_user, event_note: 'DeleteFileSetsFromWorkJob' )
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "provenance_child_remove",
                                           "work.id=#{work.id}",
                                           "child_id=#{file_set.id}",
                                           "child_title=#{file_set.title}",
                                           "event_note=FileSetsController",
                                           "" ] if debug_verbose
    return unless work.respond_to? :provenance_child_add
    work.provenance_child_remove( current_user: current_user,
                                    child_id: file_set.id,
                                    child_title: file_set.title,
                                    event_note: 'DeleteFileSetsFromWorkJob' )
  end

end
