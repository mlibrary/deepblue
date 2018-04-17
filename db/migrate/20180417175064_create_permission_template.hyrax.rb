class CreatePermissionTemplate < ActiveRecord::Migration[5.0]
  def change
    create_table :permission_templates do |t|
      t.belongs_to :workflow
      t.string :admin_set_id
      t.string :visibility
      t.timestamps
    end
    add_index :permission_templates, :admin_set_id
  end
end
