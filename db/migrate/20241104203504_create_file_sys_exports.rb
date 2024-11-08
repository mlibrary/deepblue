class CreateFileSysExports < ActiveRecord::Migration[6.0]
  def change
    begin
      #drop_table(:file_sys_exports) if table_exists?(:file_sys_exports)
      create_table :file_sys_exports do |t|
        t.string   :export_type,    null: false, index: true
        t.string   :noid,           null: false, index: true
        t.boolean  :published
        t.string   :export_status,  null: false, index: true
        t.datetime :export_status_timestamp
        t.text     :base_noid_path,              index: true
        t.text     :note

        t.timestamps
      end
    rescue Exception => ignore
    end
  end
end
