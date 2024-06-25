# frozen_string_literal: true
# Updated: hyrax4

module Hyrax
  module Actors
    # Creates a work and attaches files to the work
    class CreateWithFilesActor < Hyrax::Actors::AbstractActor

      mattr_accessor :create_with_files_actor_debug_verbose,
                     default: Rails.configuration.create_with_files_actor_debug_verbose

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create( env )
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env=#{env}",
                                               "" ] if create_with_files_actor_debug_verbose
        env.log_event( next_actor: next_actor ) if env.respond_to? :log_event
        uploaded_file_ids = filter_file_ids(env.attributes.delete(:uploaded_files))
        files             = uploaded_files(uploaded_file_ids)
        # get a current copy of attributes, to protect against future mutations
        attributes        = env.attributes.clone

        validate_files(files, env) &&
          next_actor.create(env) &&
          attach_files(files, env.curation_concern, env.user.id, attributes)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        uploaded_file_ids = filter_file_ids(env.attributes.delete(:uploaded_files))
        files             = uploaded_files(uploaded_file_ids)
        # get a current copy of attributes, to protect against future mutations
        attributes        = env.attributes.clone

        validate_files(files, env) &&
          next_actor.update(env) &&
          attach_files(files, env.curation_concern, env.user.id, attributes)
      end

      private

      def filter_file_ids(input)
        Array.wrap(input).select(&:present?)
      end

      # ensure that the files we are given are owned by the depositor of the work
      def validate_files(files, env)
        expected_user_id = env.user.id
        files.each do |file|
          if file.user_id != expected_user_id
            Rails.logger.error "User #{env.user.user_key} attempted to ingest uploaded_file #{file.id}, but it belongs to a different user"
            return false
          end
        end
        true
      end

      # @return [TrueClass]
      def attach_files(files, curation_concern, user_id, attributes)
        return true if files.blank?
        email = ::User.where( id: user_id )&.first&.email
        # AttachFilesToWorkJob.perform(work:, uploaded_files:, user_key:, **work_attributes)
        AttachFilesToWorkJob.perform_later( work: curation_concern, uploaded_files: files, user_key: email, **attributes.to_h.symbolize_keys )
        true
      end

      # Fetch uploaded_files from the database
      def uploaded_files(uploaded_file_ids)
        return [] if uploaded_file_ids.empty?
        UploadedFile.find(uploaded_file_ids)
      end
    end
  end
end
