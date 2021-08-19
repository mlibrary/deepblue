# frozen_string_literal: true

# Primarily for jobs like IngestJob to revivify an equivalent FileActor to one that existed on
# the caller's side of an asynchronous Job invocation.  This involves providing slots
# for the metadata that might travel w/ the actor's various supported types of @file.
# For example, we cannot just do:
#
#   SomeJob.perform_later(arg1, arg2, File.new('/path/to/file'))
#
# Because we'll get:
#
#   ActiveJob::SerializationError: Unsupported argument type: File
#
# This also applies to Hydra::Derivatives::IoDecorator, Tempfile, etc., pretty much any IO.
#
# @note Along with user and file_set_id, path or uploaded_file are required.
#  If both are provided: path is used preferentially for access IF it exists;
#  however, the uploaded_file is used preferentially for default original_name and mime_type,
#  because it already has that information.
class JobIoWrapper < ApplicationRecord

  mattr_accessor :job_io_wrapper_debug_verbose,
                 default: ::DeepBlueDocs::Application.config.job_io_wrapper_debug_verbose

  belongs_to :user, optional: false
  belongs_to :uploaded_file, optional: true, class_name: 'Hyrax::UploadedFile'
  validates :uploaded_file, presence: true, if: proc { |x| x.path.blank? }
  validates :file_set_id, presence: true

  after_initialize :static_defaults
  delegate :read, :size, to: :file

  # Responsible for creating a JobIoWrapper from the given parameters, with a
  # focus on sniffing out attributes from the given :file.
  #
  # @param [User] user - The user requesting to create this instance
  # @param [#path, Hyrax::UploadedFile] file - The file that is to be uploaded
  # @param [String] relation
  # @param [FileSet] file_set - The associated file set
  # @return [JobIoWrapper]
  # @raise ActiveRecord::RecordInvalid - if the instance is not valid
  def self.create_with_varied_file_handling!( user:,
                                              file:,
                                              relation:,
                                              file_set: )

    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user=#{user}",
                                           "file=#{file}",
                                           "file.class.name=#{file.class.name}",
                                           "relation=#{relation}",
                                           "file_set=#{file_set}",
                                           "" ] if job_io_wrapper_debug_verbose
    args = { user: user,
             relation: relation.to_s,
             file_set_id: file_set.id }
    if file.is_a?(Hyrax::UploadedFile)
      args[:uploaded_file] = file
      args[:path] = file.uploader.path
    elsif file.respond_to?(:path)
      args[:path] = file.path
      args[:original_name] = file.original_filename if file.respond_to?(:original_filename)
      args[:original_name] ||= file.original_name if file.respond_to?(:original_name)
    else
      raise "Require Hyrax::UploadedFile or File-like object, received #{file.class} object: #{file}"
    end
    rv = create!(args)
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "user=#{user}",
                                           "file=#{file}",
                                           "relation=#{relation}",
                                           "file_set=#{file_set}",
                                           "rv=#{rv}",
                                           "" ] if job_io_wrapper_debug_verbose
    return rv
  end

  def original_name
    super || extracted_original_name
  end

  def mime_type
    super || extracted_mime_type
  end

  def file_set
    FileSet.find(file_set_id)
  end

  def file_actor
    Hyrax::Actors::FileActor.new(file_set, relation.to_sym, user)
  end

  def ingest_file( continue_job_chain: true,
                   continue_job_chain_later: true,
                   delete_input_file: true,
                   job_status:,
                   uploaded_file_ids: [] )

    #  job_status.add_message! "JobIoWrapper#ingest_file: #{file_set_id}" if job_status.verbose
    actor = file_actor
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "actor.class=#{actor.class.name}",
                                           "relation=#{relation}",
                                           "continue_job_chain=#{continue_job_chain}",
                                           "continue_job_chain_later=#{continue_job_chain_later}",
                                           "delete_input_file=#{delete_input_file}",
                                           "job_status=#{job_status}",
                                           "uploaded_file_ids=#{uploaded_file_ids}",
                                           "" ] if job_io_wrapper_debug_verbose

    user_key = nil
    unless user_id.nil?
      user = User.find user_id
      user_key = user.user_key
    end
    actor.ingest_file(self,
                      continue_job_chain: continue_job_chain,
                      continue_job_chain_later: continue_job_chain_later,
                      current_user: user_key,
                      delete_input_file: delete_input_file,
                      job_status: job_status,
                      uploaded_file_ids: uploaded_file_ids )
  end

  private

    def extracted_original_name
      eon = uploaded_file.uploader.filename if uploaded_file
      eon ||= File.basename(path) if path.present? # note: uploader.filename is `nil` with uncached remote files (e.g. AWSFile)
      eon
    end

    def extracted_mime_type
      uploaded_file ? uploaded_file.uploader.content_type : Hydra::PCDM::GetMimeTypeForFile.call(original_name)
    end

    # The magic that switches *once* between local filepath and CarrierWave file
    # @return [File, StringIO, #read] File-like object ready to #read
    def file
      @file ||= (file_from_path || file_from_uploaded_file!)
    end

    # @return [File, StringIO] depending on CarrierWave configuration
    # @raise when uploaded_file *becomes* required but is missing
    def file_from_uploaded_file!
      raise("path '#{path}' was unusable and uploaded_file empty") unless uploaded_file
      self.path = uploaded_file.uploader.file.path # old path useless now
      uploaded_file.uploader.sanitized_file.file
    end

    # @return [File, nil] nil if the path doesn't exist on this (worker) system or can't be read
    def file_from_path
      File.open(path, 'rb') if path && File.exist?(path) && File.readable?(path)
    end

    def static_defaults
      self.relation ||= 'original_file'
    end

end
