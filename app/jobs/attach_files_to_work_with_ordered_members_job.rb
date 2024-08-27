# frozen_string_literal: true
# Reviewed: hyrax4

# Converts UploadedFiles into FileSets and attaches them to works.
class AttachFilesToWorkWithOrderedMembersJob < AttachFilesToWorkJob
  attr_reader :ordered_members, :uploaded_files

  # @param [ActiveFedora::Base] work - the work object
  # @param [Array<Hyrax::UploadedFile>] uploaded_files - an array of files to attach
  def perform(work, uploaded_files, **work_attributes)
    @uploaded_files = uploaded_files
    validate_files!(uploaded_files)
    @ordered_members = work.ordered_members.to_a # Build array of ordered members
    depositor = proxy_or_depositor(work)
    user = User.find_by_user_key(depositor)
    add_uploaded_files(user, work_attributes, work)
    add_ordered_members(user, work)
  end

  private

  def add_uploaded_files(user, work_attributes, work)
    work_permissions = work.permissions.map(&:to_hash)
    uploaded_files.each do |uploaded_file|
      file_set_attributes = file_set_attrs(work_attributes, uploaded_file)
      metadata = visibility_attributes(work_attributes, file_set_attributes)
      actor = file_set_actor_class.new(FileSet.create, user)
      actor.file_set.permissions_attributes = work_permissions
      # begin monkey
      actor.create_metadata(metadata) do |fs|
        fs.ingest_begin( called_from: 'AttachFilesToWorkWithOrderedMembersJob.add_uploaded_files' )
      end
      # end monkey
      actor.create_content(uploaded_file)
      actor.attach_to_work(work, metadata)
      ordered_members << actor.file_set
      uploaded_file.update(file_set_uri: actor.file_set.uri)
    end
  end

  # Add all file_sets as ordered_members in a single action
  def add_ordered_members(user, work)
    actor = Hyrax::Actors::OrderedMembersActor.new(ordered_members, user)
    actor.attach_ordered_members_to_work(work)
  end

  class_attribute :file_set_actor_class
  self.file_set_actor_class = Hyrax::Actors::FileSetOrderedMembersActor
end
