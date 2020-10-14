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

      t.timestamps
    end
    add_index :job_statuses, :job_id
    add_index :job_statuses, :parent_job_id
    add_index :job_statuses, :status
  end
end
