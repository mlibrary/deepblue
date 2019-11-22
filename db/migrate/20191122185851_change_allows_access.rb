class ChangeAllowsAccess < ActiveRecord::Migration[5.0]
  def change
    Sipity::Workflow.find_each do |wf|
      wf.allows_access_grant = true
      wf.save!
    end
  end
end
