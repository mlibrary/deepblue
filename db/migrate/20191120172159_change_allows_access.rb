class ChangeAllowsAccess < ActiveRecord::Migration[5.0]
  def change
    change_column :sipity_workflows, :allows_access_grant, :boolean, :default => true

    Sipity::Workflow.find_each do |wf|
      wf.allows_access_grant = true
      wf.save!
    end

  end
end
