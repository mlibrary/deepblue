# frozen_string_literal: true

module Hyrax
  module Actors
    # If there is a key +:remote_files+ in the attributes, it attaches the files at the specified URIs
    # to the work. e.g.:
    #     attributes[:remote_files] = filenames.map do |name|
    #       { url: "https://example.com/file/#{name}", file_name: name }
    #     end
    #
    # Browse everything may also return a local file. And although it's in the
    # url property, it may have spaces, and not be a valid URI.
    class CreateWithRemoteFilesActor < Hyrax::Actors::AbstractActor
      # monkey

      mattr_accessor :create_with_remove_files_actor_debug_verbose, default: false
                     #               default: Rails.configuration.file_set_actor_debug_verbose

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env=#{env}",
                                               "" ] if create_with_remove_files_actor_debug_verbose
        remote_files = env.attributes.delete(:remote_files)
        next_actor.create(env) && attach_files(env, remote_files)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "env=#{env}",
                                               "" ] if create_with_remove_files_actor_debug_verbose
        remote_files = env.attributes.delete(:remote_files)
        next_actor.update(env) && attach_files(env, remote_files)
      end

      def file_set_actor_class
        ::Hyrax::Actors::FileSetActor
      end

      private

      def registered_ingest_dirs
        Hyrax.config.registered_ingest_dirs
        end

        # @param uri [URI] the uri fo the resource to import
        def validate_remote_url(uri)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "uri=#{uri}",
                                                 "" ] if create_with_remove_files_actor_debug_verbose
          if uri.scheme == 'file'
            path = File.absolute_path(CGI.unescape(uri.path))
            registered_ingest_dirs.any? do |dir|
              path.start_with?(dir) && path.length > dir.length
            end
          else
            Rails.logger.debug "Assuming #{uri.scheme} uri is valid without a serious attempt to validate: #{uri}"
            # TODO: It might be a good idea to validate other URLs as well.
            #       The server can probably access URLs the user can't.
            true
          end
        end

        # @param [HashWithIndifferentAccess] remote_files
        # @return [TrueClass]
        def attach_files(env, remote_files)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "env=#{env}",
                                                 "remote_files=#{remote_files}",
                                                 "" ] if create_with_remove_files_actor_debug_verbose
          return true unless remote_files
          remote_files.each do |file_info|
            next if file_info.blank? || file_info[:url].blank?
            # Escape any space characters, so that this is a legal URI
            uri = URI.parse(Addressable::URI.escape(file_info[:url]))
            unless validate_remote_url(uri)
              Rails.logger.error "User #{env.user.user_key} attempted to ingest file from url #{file_info[:url]}, which doesn't pass validation"
              return false
            end
            auth_header = file_info.fetch(:auth_header, {})
            create_file_from_url(env, uri, file_info[:file_name], auth_header)
          end
          true
        end

        def create_file_from_url(env, uri, file_name, auth_header)
          case env.curation_concern
          when Valkyrie::Resource
            create_file_from_url_through_valkyrie(env, uri, file_name, auth_header)
          else
            create_file_from_url_through_active_fedora(env, uri, file_name, auth_header)
          end
        end

        # Generic utility for creating FileSet from a URL
        # Used in to import files using URLs from a file picker like browse_everything
        def create_file_from_url_through_active_fedora(env, uri, file_name, auth_header)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "env=#{env}",
                                                 "uri=#{uri}",
                                                 "file_name=#{file_name}",
                                                 "" ] if create_with_remove_files_actor_debug_verbose
          import_url = URI.decode_www_form_component(uri.to_s)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "uri=#{uri}",
                                                 "import_url=#{import_url}",
                                                 "" ] if create_with_remove_files_actor_debug_verbose
          ::FileSet.new(import_url: import_url, label: file_name) do |fs|
            # actor = Hyrax::Actors::FileSetActor.new(fs, env.user)
            actor = file_set_actor_class.new(fs, env.user)
            actor.create_metadata(visibility: env.curation_concern.visibility)
            actor.attach_to_work(env.curation_concern)
            fs.save!
            if uri.scheme == 'file'
              # Turn any %20 into spaces.
              file_path = CGI.unescape(uri.path)
              IngestLocalFileJob.perform_later(fs, file_path, env.user)
            else
              ImportUrlJob.perform_later(fs, operation_for(user: actor.user), auth_header)
            end
          end
        end

        # Generic utility for creating Hyrax::FileSet from a URL
        # Used in to import files using URLs from a file picker like browse_everything
        def create_file_from_url_through_valkyrie(env, uri, file_name, auth_header)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "env=#{env}",
                                                 "uri=#{uri}",
                                                 "file_name=#{file_name}",
                                                 "" ] if create_with_remove_files_actor_debug_verbose
          import_url = URI.decode_www_form_component(uri.to_s)
          ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                                 ::Deepblue::LoggingHelper.called_from,
                                                 "uri=#{uri}",
                                                 "import_url=#{import_url}",
                                                 "" ] if create_with_remove_files_actor_debug_verbose
          fs = Hyrax.persister.save(resource: Hyrax::FileSet.new(import_url: import_url, label: file_name))
          actor = Hyrax::Actors::FileSetActor.new(fs, env.user, use_valkyrie: true)
          actor.create_metadata(visibility: env.curation_concern.visibility)
          actor.attach_to_work(env.curation_concern)
          if uri.scheme == 'file'
            # Turn any %20 into spaces.
            file_path = CGI.unescape(uri.path)
            IngestLocalFileJob.perform_later(fs, file_path, env.user)
          else
            ImportUrlJob.perform_later(fs, operation_for(user: actor.user), auth_header)
          end
        end

        def operation_for(user:)
          Hyrax::Operation.create!(user: user,
                                   operation_type: "Attach Remote File")
        end
    end
  end
end
