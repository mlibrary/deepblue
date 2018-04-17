class CreateProxyDepositRights < ActiveRecord::Migration[5.0]
  def change
    create_table :proxy_deposit_rights do |t|
      t.references :grantor
      t.references :grantee
      t.timestamps null: false
    end
    
  end
end
