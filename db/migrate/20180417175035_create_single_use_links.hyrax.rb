class CreateSingleUseLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :single_use_links do |t|
      t.string :download_key
      t.string :path
      t.string :item_id
      t.datetime :expires

      t.timestamps null: false
    end
  end
end
