class CreateProvenances < ActiveRecord::Migration[5.2]
  def change
    begin
      create_table :provenances do |t|
        t.datetime :timestamp, null: false
        t.string :event, null: false
        t.text :event_note
        t.string :class_name
        t.string :cc_id
        t.text :key_values

        t.timestamps
      end
    rescue Exception => ignore
    end
    begin
      add_index :provenances, :timestamp
    rescue Exception => ignore
    end
    begin
      add_index :provenances, :event
    rescue Exception => ignore
    end
    begin
      add_index :provenances, :event_note
    rescue Exception => ignore
    end
    begin
      add_index :provenances, :class_name
    rescue Exception => ignore
    end
    begin
      add_index :provenances, :cc_id
    end
  end
end
