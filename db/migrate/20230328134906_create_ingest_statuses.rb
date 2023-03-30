class CreateIngestStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :ingest_statuses do |t|
      t.string :cc_id, null: false
      t.string :cc_type, null: false
      t.string :status, null: false
      t.datetime :status_date, null: false
      t.text :additional_parameters

      t.timestamps null: false
    end
    add_index :ingest_statuses, :cc_id
    add_index :ingest_statuses, :cc_type
    add_index :ingest_statuses, :status
    add_index :ingest_statuses, :status_date
  end
end
