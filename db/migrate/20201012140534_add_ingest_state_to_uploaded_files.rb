class AddIngestStateToUploadedFiles < ActiveRecord::Migration[5.2]
  def change
    add_column :uploaded_files, :ingest_state, :text
  end
end
