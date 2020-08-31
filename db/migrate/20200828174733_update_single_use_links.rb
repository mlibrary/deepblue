class UpdateSingleUseLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :single_use_links, :user_id, :integer
    add_column :single_use_links, :user_comment, :text
  end
end
