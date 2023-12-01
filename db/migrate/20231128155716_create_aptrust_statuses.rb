class CreateAptrustStatuses < ActiveRecord::Migration[5.2]
  def change
    begin
      #drop_table(:aptrust_events) if table_exists?(:aptrust_events)
      #drop_table(:aptrust_statuses) if table_exists?(:aptrust_statuses)
      create_table :aptrust_statuses do |t|
        t.datetime :timestamp, null: false, index: true
        t.string :event, null: false, index: true
        t.text :event_note
        t.string :noid, null: false, index: true, unique: true

        t.timestamps null: false
      end
    rescue Exception => ignore
    end
  end
end
