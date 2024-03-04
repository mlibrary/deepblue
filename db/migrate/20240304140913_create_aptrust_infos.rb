class CreateAptrustInfos < ActiveRecord::Migration[5.2]
  begin
    def change
      create_table :aptrust_infos do |t|
        t.datetime :timestamp, null: false, index: true
        t.string :system
        t.string :noid, null: false, index: true
        t.string :query, index: true
        t.text :results

        t.timestamps
      end
    end
  rescue Exception => ignore
  end
end
