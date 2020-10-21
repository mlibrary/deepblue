class AddCcIdToAhoyEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :ahoy_events, :cc_id, :string
  end

  add_index :ahoy_events, :cc_id
end
