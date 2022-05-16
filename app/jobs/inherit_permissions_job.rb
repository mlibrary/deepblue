# A job to apply work permissions to all contained files set
#
class InheritPermissionsJob < Hyrax::ApplicationJob

  mattr_accessor :inherit_permissions_job_debug_verbose, default: false

  # Perform the copy from the work to the contained filesets
  #
  # @param work containing access level and filesets
  def perform(work, use_valkyrie: false) # use_valkyrie: Hyrax.config.use_valkyrie?
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if inherit_permissions_job_debug_verbose
    if use_valkyrie
      valkyrie_perform(work)
    else
      af_perform(work)
    end
  end

  def af_perform(work)
    attribute_map = work.permissions.map(&:to_hash)
    work.file_sets.each do |file|
      begin
        # copy and removed access to the new access with the delete flag
        file.permissions.map(&:to_hash).each do |perm|
          unless attribute_map.include?(perm)
            perm[:_destroy] = true
            attribute_map << perm
          end
        end

        # apply the new and deleted attributes
        file.permissions_attributes = attribute_map
        file.save!
      rescue Ldp::Gone => g
        # ignore, the file set has been deleted
        ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                               ::Deepblue::LoggingHelper.called_from,
                                               "" ] if inherit_permissions_job_debug_verbose
      end
    end
  rescue Ldp::Gone => g
    # ignore, the work has been deleted
    ::Deepblue::LoggingHelper.bold_debug [ ::Deepblue::LoggingHelper.here,
                                           ::Deepblue::LoggingHelper.called_from,
                                           "" ] if inherit_permissions_job_debug_verbose
  end

  # Perform the copy from the work to the contained filesets
  #
  # @param work containing access level and filesets
  def valkyrie_perform(work)
    work_acl = Hyrax::AccessControlList.new(resource: work)

    PersistHelper.file_sets_for(work).each do |file_set|
      Hyrax::AccessControlList
        .copy_permissions(source: work_acl, target: file_set)
    end
  end
end
