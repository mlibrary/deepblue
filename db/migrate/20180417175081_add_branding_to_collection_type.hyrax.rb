class AddBrandingToCollectionType < ActiveRecord::Migration[5.0]
  def change
    add_column :hyrax_collection_types, :brandable, :boolean, null: false, default: true
  end
end
