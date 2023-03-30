class UpdateIngestStatuses < ActiveRecord::Migration[5.2]
  begin
    add_index :ingest_statuses, :cc_type
  rescue Exception => ignore
  end
end
