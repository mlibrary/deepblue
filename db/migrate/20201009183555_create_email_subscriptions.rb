class CreateEmailSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :email_subscriptions do |t|
      t.integer :user_id
      t.string :email
      t.string :subscription_name, null: false
      t.text :subscription_parameters
      t.timestamps null: false
    end

    add_index :email_subscriptions, :user_id
    add_index :email_subscriptions, :subscription_name

  end
end
