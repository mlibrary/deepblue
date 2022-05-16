class UpdateAnonymousLinksColumnNames < ActiveRecord::Migration[5.2]
  def change
    # remove_index :anonymous_links, :downloadKey
    # remove_index :anonymous_links, :itemId

    rename_column :anonymous_links, :downloadKey, :download_key
    rename_column :anonymous_links, :itemId, :item_id

    add_index :anonymous_links, :download_key
    add_index :anonymous_links, :item_id
  end

end
