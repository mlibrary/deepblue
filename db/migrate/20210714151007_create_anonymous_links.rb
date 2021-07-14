class CreateAnonymousLinks < ActiveRecord::Migration[5.2]

  def change
    create_table :anonymous_links do |t|
      t.string :downloadKey
      t.string :path
      t.string :itemId
      # t.integer :user_id # probably not useful for anonymous links
      # t.text :user_comment # probably not useful for anonymous links

      t.timestamps null: false
    end

    add_index :anonymous_links, :downloadKey
    add_index :anonymous_links, :itemId
    add_index :anonymous_links, :path

  end

end
