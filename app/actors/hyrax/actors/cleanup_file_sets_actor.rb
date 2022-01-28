
module Hyrax
  module Actors
    # Responsible for removing FileSets related to the given curation concern.
    class CleanupFileSetsActor < Hyrax::Actors::AbstractActor

      mattr_accessor :cleanup_file_sets_actor_debug_verbose,
                     default: Rails.configuration.cleanup_file_sets_actor_debug_verbose

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        cleanup_file_sets(env.curation_concern)
        next_actor.destroy(env)
      end

      private

        def cleanup_file_sets(curation_concern)
          # begin monkey
          return unless curation_concern
          # end monkey

          # Destroy the list source first.  This prevents each file_set from attemping to
          # remove itself individually from the work. If hundreds of files are attached,
          # this would take too long.

          # Get list of member file_sets from Solr
          fs = curation_concern.file_sets
          curation_concern.list_source.destroy
          # Remove Work from Solr after it was removed from Fedora so that the
          # in_objects lookup does not break when FileSets are destroyed.
          ActiveFedora::SolrService.delete(curation_concern.id)
          fs.each(&:destroy)
        end
    end
  end
end
