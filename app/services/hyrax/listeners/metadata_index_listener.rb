# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Reindexes resources when their metadata is updated.
    #
    # @note This listener makes no attempt to avoid reindexing when no metadata
    #   has actually changed, or when real metadata changes won't impact the
    #   indexed data. We trust that published metadata update events represent
    #   actual changes to object metadata, and that the indexing adapter
    #   optimizes reasonably for actual index document contents.
    class MetadataIndexListener

      mattr_accessor :hyrax_listeners_metadata_index_listener_verbose, default: false

      ##
      # Re-index the resource.
      #
      # @param event [Dry::Event]
      def on_object_metadata_updated(event)
        log_non_resource(event) && return unless event[:object].is_a?(Valkyrie::Resource)

        Hyrax.index_adapter.save(resource: event[:object])
      end

      ##
      # Remove the resource from the index.
      #
      # @param event [Dry::Event]
      def on_object_deleted(event)
        log_non_resource(event.payload) && return unless event.payload[:object].is_a?(Valkyrie::Resource)

        Hyrax.index_adapter.delete(resource: event.payload[:object]) # monkey, fix reference to payload
      end

      private

      def log_non_resource(event)
        Hyrax.logger.info('Skipping object reindex because the object ' \
                          "#{event[:object]} was not a Valkyrie::Resource.") if hyrax_listeners_metadata_index_listener_verbose
      end
    end
  end
end


# # monkey patch
# require File.join( Gem::Specification.find_by_name("hyrax").full_gem_path, "app/services/hyrax/listeners/metadata_index_listener.rb" )
# monkey patching this caused problems
# module Hyrax
#   module Listeners
#
#     class MetadataIndexListener
#
#       mattr_accessor :hyrax_listeners_metadata_index_listener_verbose, default: false
#
#       private
#
#       # monkey override
#       def log_non_resource(event)
#         Hyrax.logger.info('Skipping object reindex because the object ' \
#                           "#{event[:object]} was not a Valkyrie::Resource.") if hyrax_listeners_metadata_index_listener_verbose
#       end
#
#     end
#   end
# end
