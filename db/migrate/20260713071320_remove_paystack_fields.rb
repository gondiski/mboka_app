class RemovePaystackFields < ActiveRecord::Migration[8.0]
  def change
    remove_index :payments, :paystack_reference, if_exists: true
    remove_column :payments, :paystack_reference, :string
    remove_column :admin_settings, :paystack_secret_key, :text
    remove_column :admin_settings, :paystack_public_key, :text
  end
end
