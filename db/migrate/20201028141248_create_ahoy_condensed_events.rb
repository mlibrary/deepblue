class CreateAhoyCondensedEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :ahoy_condensed_events do |t|
      t.string :name
      t.string :cc_id
      t.datetime :date_begin
      t.datetime :date_end
      t.text :condensed_event

      t.timestamps
    end

    add_index :ahoy_condensed_events, :name
    add_index :ahoy_condensed_events, :cc_id
    add_index :ahoy_condensed_events, :date_begin
    add_index :ahoy_condensed_events, :date_end
  end
end
