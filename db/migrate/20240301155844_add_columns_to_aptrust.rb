class AddColumnsToAptrust < ActiveRecord::Migration[5.2]
  def change
    begin
      add_column :aptrust_events, :service, :string
      add_column :aptrust_statuses, :service, :string
    rescue Exception => ignore
    end
  end
end
