class CreateJobStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :job_statuses do |t|
      t.string :job_class, null: false
      t.string :job_id, null: false
      t.string :parent_job_id
      t.string :status
      t.text :state
      t.text :message
      t.text :error
      t.string :main_cc_id
      t.integer :user_id

      t.timestamps
    end

    add_index :job_statuses, :job_id
    add_index :job_statuses, :parent_job_id
    add_index :job_statuses, :status
    add_index :job_statuses, :main_cc_id
    add_index :job_statuses, :user_id
  end
end
