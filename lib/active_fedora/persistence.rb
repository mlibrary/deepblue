# frozen_string_literal: true

require File.join(Gem::Specification.find_by_name("active-fedora").full_gem_path, "lib/active_fedora/persistence.rb")

# monkey patch of active_fedora gem, lib/active_fedora/persistence.rb

module ActiveFedora
  # = Active Fedora Persistence
  module Persistence
    extend ActiveSupport::Concern

    private

      ## begin monkey patch

      # Deals with preparing new object to be saved to Fedora, then pushes it and its attached files into Fedora.
      def XXX_create_record(_options = {})
        assign_rdf_subject
        serialize_attached_files
        begin
          @ldp_source = @ldp_source.create
        rescue Ldp::Conflict
          _create_record_ldp_source_create_retry
        end
        assign_uri_to_contained_resources
        save_contained_resources
        refresh
      end

      def XXX_create_record_ldp_source_create_retry
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
          end
        end
      end

      ## end monkey patch

  end
end
