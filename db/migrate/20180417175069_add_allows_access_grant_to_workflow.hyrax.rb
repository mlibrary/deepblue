class AddAllowsAccessGrantToWorkflow < ActiveRecord::Migration[5.0]
  def change
    add_column :sipity_workflows, :allows_access_grant, :boolean
  end
end
