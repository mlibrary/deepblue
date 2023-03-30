class CreateIngestStatuses < ActiveRecord::Migration[5.2]
  def change
    begin
    create_table :ingest_statuses do |t|
      t.string :cc_id, null: false
      t.string :cc_type, null: false
      t.string :status, null: false
      t.datetime :status_date, null: false
      t.text :additional_parameters

      t.timestamps null: false
    end
    rescue Exception => ignore
    end
    begin
    add_index :ingest_statuses, :cc_id
    rescue Exception => ignore
    end
    begin
    add_index :ingest_statuses, :cc_type
    rescue Exception => ignore
    end
    begin
    add_index :ingest_statuses, :status
    rescue Exception => ignore
    end
    begin
    add_index :ingest_statuses, :status_date
    rescue Exception => ignore
    end
  end
end
