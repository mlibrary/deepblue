class ChangeTrophyGenericFileIdToWorkId < ActiveRecord::Migration[5.0]
  def change
    rename_column :trophies, :generic_file_id, :work_id
  end
end
