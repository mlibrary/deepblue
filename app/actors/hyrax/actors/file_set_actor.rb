require File.join(Gem::Specification.find_by_name("hyrax").full_gem_path, "app/actors/hyrax/actors/file_set_actor.rb")

module Hyrax
  module Actors
    # monkey patch
    class FileSetActor
      alias_method :monkey_create_content, :create_content
      alias_method :monkey_create_metadata, :create_metadata
      alias_method :monkey_update_metadata, :update_metadata

      ## Overide -- copy of method and add new function for updating total file size
      # Adds a FileSet to the work using ore:Aggregations.
      # Locks to ensure that only one process is operating on the list at a time.
      def attach_file_to_work(work, file_set_params = {})
        acquire_lock_for(work.id) do
          # Ensure we have an up-to-date copy of the members association, so that we append to the end of the list.
          work.reload unless work.new_record?
          ## move next four statements to update_work_with_file_set
          #copy_visibility(work, file_set) unless assign_visibility?(file_set_params)
          #work.ordered_members << file_set
          #set_representative(work, file_set)
          #set_thumbnail(work, file_set)
          update_work_with_file_set( work, file_set, file_set_params )
          # Save the work so the association between the work and the file_set is persisted (head_id)
          # NOTE: the work may not be valid, in which case this save doesn't do anything.
          work.save
        end
      end

      def create_content(file, relation = 'original_file', asynchronous = true)
        monkey_create_content( file, relation, asynchronous )
      end

      def create_metadata(file_set_params = {})
        monkey_create_metadata(file_set_params)
      end

      def update_metadata(attributes)
          monkey_update_metadata(attributes)
      end

      private

      def unlink_from_work
        work = file_set.parent
        work.total_file_size_subtract_file_set! file_set
        return unless work && (work.thumbnail_id == file_set.id || work.representative_id == file_set.id)
        # Must clear the thumbnail_id and representative_id fields on the work and force it to be re-solrized.
        # Although ActiveFedora clears the children nodes it leaves those fields in Solr populated.
        work.thumbnail = nil if work.thumbnail_id == file_set.id
        work.representative = nil if work.representative_id == file_set.id
        work.save!
      end

      def update_work_with_file_set( work, file_set, file_set_params )
        copy_visibility(work, file_set) unless assign_visibility?(file_set_params)
        work.ordered_members << file_set
        set_representative(work, file_set)
        set_thumbnail(work, file_set)
      end

    end
  end
end
