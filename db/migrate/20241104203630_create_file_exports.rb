class CreateFileExports < ActiveRecord::Migration[6.0]
  def change
    begin
      #drop_table(:file_exports) if table_exists?(:file_exports)
      create_table :file_exports do |t|
        t.string   :export_type,    null: false, index: true
        t.string   :export_noid,    null: false, index: true
        t.string   :noid,           null: false, index: true
        t.string   :export_status,  null: false, index: true
        t.datetime :export_status_timestamp
        t.text     :base_noid_path,              index: true
        t.text     :export_file_name,            index: true
        t.string   :checksum_value
        t.string   :checksum_algorithm
        t.datetime :checksum_validated,          index: true
        t.text     :note

        t.timestamps

        t.belongs_to :file_sys_exports
      end
    rescue Exception => ignore
    end
  end
end
