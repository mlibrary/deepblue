class AddOrcidToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :orcid, :string
  end
end
