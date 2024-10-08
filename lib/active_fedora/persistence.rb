# monkey patch of active_fedora gem, lib/active_fedora/persistence.rb
# Update: hyrax4 -- active-fodora-14.0.1

module ActiveFedora
  # = Active Fedora Persistence
  module Persistence
    extend ActiveSupport::Concern
    extend ActiveSupport::Autoload
    autoload :NullIdentifierService

    included do
      class_attribute :identifier_service_class
      self.identifier_service_class = NullIdentifierService
    end

    def new_record?
      return true if @ldp_source.subject.nil?
      @ldp_source.get
      false
    rescue Ldp::Gone
      false
    rescue Ldp::NotFound
      true
    end

    def persisted?
      !(destroyed? || new_record?)
    end

    # Returns true if this object has been destroyed, otherwise returns false.
    def destroyed?
      @destroyed
    end

    # Saves a Base object, and any dirty attached files, then updates
    # the Solr index for this object, unless option :update_index=>false is present.
    # Indexing is also controlled by the `create_needs_index?' and `update_needs_index?' methods.
    #
    # @param [Hash] options
    # @option options [Boolean] :update_index (true) set false to skip indexing
    # @return [Boolean] true if save was successful, otherwise false
    def save(*options)
      # begin monkey
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "self.class.name=#{self.class.name}",
      #                                        "" ] if false
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "self.class.name=#{self.class.name}",
      #                                        "" ] + caller_locations[0..10] if true && 'FileSet' == self.class.name
      create_or_update(*options)
    rescue Exception => e
      puts "Exception: #{e}"
      puts e.backtrace[0..30]
      # end monkey
    end

    def save!(*args)
      # begin monkey
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "self.class.name=#{self.class.name}",
      #                                        "" ] if false
      # ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
      #                                        ::Deepblue::LoggingHelper.called_from,
      #                                        "self.class.name=#{self.class.name}",
      #                                        "" ] + caller_locations[0..10] if true && 'FileSet' == self.class.name
      # end monkey
      create_or_update(*args)
    end

    # Pushes the object and all of its new or dirty attached files into Fedora
    def update(attributes)
      assign_attributes(attributes)
      save
    end

    alias update_attributes update

    # Updates its receiver just like #update but calls #save! instead
    # of +save+, so an exception is raised if the record is invalid and saving will fail.
    def update!(attributes)
      assign_attributes(attributes)
      save!
    end

    alias update_attributes! update!

    # Deletes an object from Fedora and deletes the indexed record from Solr.
    # Delete does not run any callbacks, so consider using _destroy_ instead.
    # @param [Hash] opts
    # @option opts [Boolean] :eradicate if passed in, eradicate the tombstone from Fedora
    def delete(opts = {})
      return self if new_record?

      @destroyed = true

      id = self.id ## cache so it's still available after delete
      # Clear out the ETag
      @ldp_source = build_ldp_resource(id)
      begin
        @ldp_source.delete
      rescue Ldp::NotFound
        raise ObjectNotFoundError, "Unable to find #{id} in the repository"
      end

      ActiveFedora::SolrService.delete(id) if ActiveFedora.enable_solr_updates?
      self.class.eradicate(id) if opts[:eradicate]
      freeze
    end

    # Delete the object from Fedora and Solr. Run any before/after/around callbacks for destroy
    # @param [Hash] opts
    # @option opts [Boolean] :eradicate if passed in, eradicate the tombstone from Fedora
    def destroy(*opts)
      raise ReadOnlyRecord if readonly?
      delete(*opts)
    end

    # Deletes the record in the database and freezes this instance to reflect
    # that no changes should be made (since they can't be persisted).
    #
    # There's a series of callbacks associated with #destroy!. If the
    # <tt>before_destroy</tt> callback throws +:abort+ the action is cancelled
    # and #destroy! raises ActiveFedora::RecordNotDestroyed.
    # See ActiveFedora::Callbacks for further details.
    def destroy!
      destroy || _raise_record_not_destroyed
    end

    def eradicate
      self.class.eradicate(id)
    end

    # Used when setting containment
    def base_path_for_resource=(path)
      @base_path = path
    end

    module ClassMethods
      # Creates an object (or multiple objects) and saves it to the repository, if validations pass.
      # The resulting object is returned whether the object was saved successfully to the repository or not.
      #
      # The +attributes+ parameter can be either be a Hash or an Array of Hashes.  These Hashes describe the
      # attributes on the objects that are to be created.
      #
      # ==== Examples
      #   # Create a single new object
      #   User.create(:first_name => 'Jamie')
      #
      #   # Create an Array of new objects
      #   User.create([{ :first_name => 'Jamie' }, { :first_name => 'Jeremy' }])
      #
      #   # Create a single object and pass it into a block to set other attributes.
      #   User.create(:first_name => 'Jamie') do |u|
      #     u.is_admin = false
      #   end
      #
      #   # Creating an Array of new objects using a block, where the block is executed for each object:
      #   User.create([{ :first_name => 'Jamie' }, { :first_name => 'Jeremy' }]) do |u|
      #     u.is_admin = false
      #   end
      def create(attributes = nil, &block)
        if attributes.is_a?(Array)
          attributes.collect { |attr| create(attr, &block) }
        else
          object = new(attributes, &block)
          object.save
          object
        end
      end

      # Removes an object's tombstone so another object with the same uri may be created.
      # NOTE: this is in violation of the linked data platform and is only here as a convience
      # method. It shouldn't be used in the general course of repository operations.
      def eradicate(uri)
        gone?(uri) ? delete_tombstone(uri) : false
      end

      # Allows the user to find out if an id has been used in the system and then been deleted
      # @param uri id in fedora that may or may not have been deleted
      def gone?(uri)
        ActiveFedora::Base.find(uri)
        false
      rescue Ldp::Gone
        true
      rescue ActiveFedora::ObjectNotFoundError
        false
      # begin monkey
      rescue Hyrax::ObjectNotFoundError
        false
      # end monkey
      end

      private

        def delete_tombstone(uri)
          tombstone = ActiveFedora::Base.id_to_uri(uri) + "/fcr:tombstone"
          ActiveFedora.fedora.connection.delete(tombstone)
          true
        end
    end

    private

      def create_or_update(*args)
        raise ReadOnlyRecord if readonly?
        result = new_record? ? _create_record(*args) : _update_record(*args)
        result != false
      end

      ## begin monkey patch

      # Deals with preparing new object to be saved to Fedora, then pushes it and its attached files into Fedora.
      def _create_record(_options = {})
        assign_rdf_subject
        serialize_attached_files
        begin
          @ldp_source = @ldp_source.create
        rescue Ldp::Conflict
          _create_record_ldp_source_create_retry
        rescue Ldp::Gone
          ::Deepblue::LoggingHelper.debug "Ldp::Gone"
          puts ">>>>>>>>>>> Ldp::Gone <<<<<<<<<<<<<" if Rails.env.test?
          raise
        end
        assign_uri_to_contained_resources
        save_contained_resources
        refresh
      end

      def _create_record_ldp_source_create_retry
        # puts ">>>>>>>>>>>>>>>> _create_record_ldp_source_create_retry <<<<<<<<<<<<<<<<<<<<<"
        attempts = 0
        loop do
          break if attempts > 99
          new_id = assign_id
          # puts ">>>>>>>>>>> assign_id=#{assign_id} <<<<<<<<<<<<<"
          begin
            @ldp_source = LdpResource.new(ActiveFedora.fedora.connection, self.class.id_to_uri(new_id), @resource)
            @ldp_source = @ldp_source.create
            return
          rescue Ldp::Conflict
            attempts += 1
            raise if attempts > 99
          rescue Ldp::Gone
            ::Deepblue::LoggingHelper.debug "Ldp::Gone #{new_id}"
            puts ">>>>>>>>>>> Ldp::Gone #{new_id} <<<<<<<<<<<<<" if Rails.env.test?
            raise
          end
        end
      end

      ## end monkey patch

      def _update_record(_options = {})
        serialize_attached_files
        execute_sparql_update
        save_contained_resources
        refresh
      end

      def _raise_record_not_destroyed
        @_association_destroy_exception ||= nil
        raise @_association_destroy_exception || RecordNotDestroyed.new("Failed to destroy the record", self)
      ensure
        @_association_destroy_exception = nil
      end

      def refresh
        @ldp_source = build_ldp_resource(id)
        @resource = nil
      end

      def execute_sparql_update
        change_set = ChangeSet.new(self, resource, changed_attributes.keys)
        return true if change_set.empty?
        ActiveFedora.fedora.ldp_resource_service.update(change_set, self.class, id)
      end

      # Override to tie in an ID minting service
      def assign_id
        identifier_service.mint
      end

      def identifier_service
        @identifier_service ||= identifier_service_class.new
      end

      # This is only used when creating a new record. If the object doesn't have an id
      # and assign_id can mint an id for the object, then assign it to the resource.
      # Otherwise the resource will have the id assigned by the LDP server
      def assign_rdf_subject
        @ldp_source = if !id && new_id = assign_id # rubocop:disable Lint/AssignmentInCondition
                        LdpResource.new(ActiveFedora.fedora.connection, self.class.id_to_uri(new_id), @resource)
                      else
                        LdpResource.new(ActiveFedora.fedora.connection, @ldp_source.subject, @resource, base_path_for_resource)
                      end
      end

      def base_path_for_resource
        @base_path ||= ActiveFedora.fedora.host + default_base_path_for_resource
      end

      def default_base_path_for_resource
        init_root_path if has_uri_prefix?
        root_resource_path
      end

      # Check to see if the :base_path (from fedora.yml) exists in Fedora. If it doesn't exist, then create it.
      def init_root_path
        path = root_resource_path.gsub(/^\//, "")
        ActiveFedora.fedora.connection.head(path)
      rescue Ldp::NotFound
        ActiveFedora.fedora.connection.put(path, "")
      end

      def assign_uri_to_contained_resources
        contained_resources.each do |name, source|
          source.uri = "#{uri}/#{name}"
        end
      end

      def save_contained_resources
        # begin monkey
        # Split into two steps due to stack overflow issue while saving works with large numbers of ordered members
        # puts "caller.size=#{caller.size}"
        # changed is a hash
        changed = contained_resources.changed
        # puts "changed.size=#{changed.size}"
        # puts "changed[changed.keys.first].class.name=#{changed[changed.keys.first].class.name}" if changed.size > 0
        # puts "changed[changed.keys.last].class.name=#{changed[changed.keys.last].class.name}" if changed.size > 0
        keys = []
        keys = changed.keys if changed.size > 0
        i = 0
        n = keys.size
        while i < n do
          resource = changed[keys[i]]
          resource.save
          i += 1
        end
        # changed.each do |_, resource|
        #   resource.save
        # end
      rescue SystemStackError => e
        # puts "SystemStackError backtrace.size="
        # puts e.backtrace.size
        # puts e.backtrace[0..20]
        raise
        # end monkey
      end

      def contained_resources
        @contained_resources ||= attached_files.merge(contained_rdf_sources)
      end

      def contained_rdf_sources
        @contained_rdf_sources ||=
          AssociationHash.new(self, self.class.contained_rdf_source_reflections)
      end
  end
end
