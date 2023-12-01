class CreateAptrustEvents < ActiveRecord::Migration[5.2]
  def change
    begin
      create_table :aptrust_events do |t|
        t.datetime :timestamp, null: false, index: true
        t.string :event, null: false, index: true
        t.string :event_note
        t.string :noid, null: false, index: true

        t.timestamps null: false

        t.belongs_to :aptrust_status
      end
    rescue Exception => ignore
    end
  end
end
