# Reference
# https://github.com/samvera/hyrax/blob/master/app/controllers/concerns/hyrax/works_controller_behavior.rb
# https://github.com/samvera/hyrax/blob/master/app/controllers/hyrax/uploads_controller.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/master/lib/generators/leaf_addons/templates/lib/importer/factory/object_factory.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/master/lib/generators/leaf_addons/templates/lib/importer/files_parser.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/9643b649df513e404c96ba5b9285d83abc4b2c9a/lib/generators/leaf_addons/templates/lib/importer/factory/base_factory.rb

require_relative "../../../../actors/hyrax/actors/environment"

module Integrator
  module Hyrax
    module WorksBehavior
      extend ActiveSupport::Concern

      mattr_accessor :integrator_hyrax_works_behavior_debug_verbose, default: false
      # default: ::Deepblue::IngestIntegrationService.ingest_job_debug_verbose

      def upload_files
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if integrator_hyrax_works_behavior_debug_verbose
        return if @files.blank?
        @file_ids = []
        @uploaded_files = {}
        @files.each do |file|
          u = ::Hyrax::UploadedFile.new
          @current_user = User.batch_user unless @current_user.present?
          u.user_id = @current_user.id unless @current_user.nil?
          u.file = ::CarrierWave::SanitizedFile.new(file)
          u.save
          chosen_file = @files_attributes.select{ |fa| File.basename(fa['filepath']) == File.basename(file) }
          if chosen_file.any?
            chosen_file[0]['uploaded_file'] = u
            @uploaded_files[File.basename(file)] = chosen_file[0]
          else
            @file_ids << u.id
          end
        end
      end

      def add_work
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if integrator_hyrax_works_behavior_debug_verbose
        @object = find_work if @object.blank?
        if @object
          update_work
        else
          create_work
        end
      end

      def upload_files_with_attributes
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if integrator_hyrax_works_behavior_debug_verbose
        return if @uploaded_files.blank?
        @uploaded_files.each do |file_name, uploaded_file|
          create_file_set_with_attributes(uploaded_file)
        end
      end

      def find_work_by_query(work_id = params[:id])
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if integrator_hyrax_works_behavior_debug_verbose
        model = find_work_klass(work_id)
        return nil if model.blank?
        @work_klass = model.constantize
        @object = find_work(work_id)
      end

      def find_work(work_id = params[:id])
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if integrator_hyrax_works_behavior_debug_verbose
        # params[:id] = SecureRandom.uuid unless params[:id].present?
        return find_work_by_id(work_id) if work_id
      end

      def find_work_by_id(work_id = params[:id])
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if integrator_hyrax_works_behavior_debug_verbose
        @work_klass.find(work_id)
      rescue ActiveFedora::ActiveFedoraError
        nil
      end

      def update_work
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if integrator_hyrax_works_behavior_debug_verbose
        raise "Object doesn't exist" unless @object
        work_actor.update(environment(update_attributes))
      end

      def create_work
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if integrator_hyrax_works_behavior_debug_verbose
        attrs = create_attributes
        #the object 
        @object = @work_klass.new
        work_actor.create(environment(attrs))

        collection_id = params["collection_id"]
        unless collection_id.blank?
          collection_id =  WillowSword.config.default_collection[:id] if collection_id.eql? ("default")
          collection = Collection.find (collection_id)
          @object.member_of_collections << collection
          @object.save!
        end
      end

      private
        def create_attributes
          transform_attributes
        end

        def update_attributes
          transform_attributes.except(:id, 'id')
        end

        def set_work_klass
          # Transform name of model to match across name variations
          work_models = WillowSword.config.work_models
          if work_models.kind_of?(Array)
            work_models = work_models.map { |m| [m, m] }.to_h
          end
          work_models.transform_keys!{ |k| k.underscore.gsub('_', ' ').gsub('-', ' ').downcase }
          # Match with header first, then resource type and finally pick one from list
          hyrax_work_model = @headers.fetch(:hyrax_work_model, nil)
          if hyrax_work_model and work_models.include?(hyrax_work_model)
            # Read the class from the header
            @work_klass = work_models[hyrax_work_model].constantize
          elsif @resource_type and work_models.include?(@resource_type)
            # Set the class based on the resource type
            @work_klass = work_models[@resource_type].constantize
          else
            # Chooose the first class from the config
            @work_klass = work_models[work_models.keys.first].constantize
          end
        end

        # @param [Hash] attrs the attributes to put in the environment
        # @return [Hyrax::Actors::Environment]
        def environment(attrs)
          # Set Hyrax.config.batch_user_key
          @current_user = User.batch_user unless @current_user.present?
          #::Hyrax::Actors::EnvironmentEnhanced.new(@object, Ability.new(@current_user), attrs)
          ::Hyrax::Actors::EnvironmentEnhanced.new(curation_concern: @object, current_ability: Ability.new(@current_user),
                                                   attributes:attrs, action:"create", wants_format:nil)
        end

        def work_actor
          ::Hyrax::CurationConcern.actor
        end

        # Override if we need to map the attributes from the parser in
        # a way that is compatible with how the factory needs them.
        def transform_attributes
          # TODO: attributes are strings and not symbols
          @attributes['visibility'] = WillowSword.config.default_visibility if @attributes.fetch('visibility', nil).blank?
          if WillowSword.config.allow_only_permitted_attributes
           @attributes.slice(*permitted_attributes).merge(file_attributes)
          else
           @attributes.merge(file_attributes)
          end
        end

        def file_attributes
          @file_ids.present? ? { uploaded_files: @file_ids } : {}
        end

        def permitted_attributes
          @work_klass.properties.keys.map(&:to_sym) + [:id, :edit_users, :edit_groups, :read_groups, :visibility]
        end

        def find_work_klass(work_id)
          model = nil
          blacklight_config = Blacklight::Configuration.new
          search_builder = Blacklight::SearchBuilder.new([], blacklight_config)
          search_builder.merge(fl: 'id, has_model_ssim')
          search_builder.merge(fq: "{!raw f=id}#{work_id}")
          repository = Blacklight::Solr::Repository.new(blacklight_config)
          response = repository.search(search_builder.query)
          if response.dig('response', 'numFound') == 1
            model = response.dig('response', 'docs')[0]['has_model_ssim'][0]
          end
          model
        end

        def create_file_set_with_attributes(file_attributes)
          @file_set_klass = WillowSword.config.file_set_models.first.constantize
          file_set = @file_set_klass.create
          @current_user = User.batch_user unless @current_user.present?
          actor = file_set_actor.new(file_set, @current_user)
          actor.file_set.permissions_attributes = @object.permissions.map(&:to_hash)
          # Add file
          if file_attributes.fetch('uploaded_file', nil)
            actor.create_content(file_attributes['uploaded_file'])
          end
          title = Array(file_attributes.dig('mapped_metadata', 'file_name'))
          unless title.any?
            filepath = file_attributes.fetch('filepath', nil)
            title = [File.basename(filepath)] unless filepath.blank?
          end
          actor.file_set.title = title
          # update_metadata
          unless file_attributes['mapped_metadata'].blank?
            chosen_attributes = file_set_attributes(file_attributes['mapped_metadata'])
            actor.file_set.update(chosen_attributes)
            actor.file_set.save!
          end
          actor.attach_to_work(@object) if @object
        end

        def file_set_attributes(attributes)
          if WillowSword.config.allow_only_permitted_attributes
            attributes.slice(*permitted_file_attributes).except(:id, 'id')
          else
            attributes.except(:id, 'id')
          end
        end

        def file_set_actor
          ::Hyrax::Actors::FileSetActor
        end

        def permitted_file_attributes
          @file_set_klass.properties.keys.map(&:to_sym) + [:id, :edit_users, :edit_groups, :read_groups, :visibility]
        end
    end
  end
end
