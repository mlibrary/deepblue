# hyrax-orcid

class ModifyOrcidIdentities < ActiveRecord::Migration[5.2]
  def change
    return unless table_exists?(:orcid_identities)
    return if column_exists?(:orcid_identities, :profile_sync_preference, :text)
    remove_column :orcid_identities, :profile_sync_preference
    add_column :orcid_identities, :profile_sync_preference, :text
  rescue Exception => ignore
  end
end
