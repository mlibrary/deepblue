class UpdateAnonymousLinksColumnNames < ActiveRecord::Migration[5.2]
  def change
    begin
      remove_index :anonymous_links, :downloadKey
    rescue Exception => ignore  
    end
    begin
      remove_index :anonymous_links, :itemId
    rescue Exception => ignore
    end

    rename_column :anonymous_links, :downloadKey, :download_key
    rename_column :anonymous_links, :itemId, :item_id

    begin
      add_index :anonymous_links, :download_key
    rescue Exception => ignore
    end
    begin
      add_index :anonymous_links, :item_id
    rescue Exception => ignore
    end
  end

end
