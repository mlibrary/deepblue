# hyrax-orcid

class CreateOrcidWorks < ActiveRecord::Migration[5.2]
  def self.up
    return if table_exists?(:orcid_works)

    create_table :orcid_works do |t|
      t.references :orcid_identity
      t.string :work_uuid
      t.integer :put_code
      t.timestamps

      t.index :work_uuid
    end
  end

  def self.down
    drop_table(:orcid_works)
  end
end
