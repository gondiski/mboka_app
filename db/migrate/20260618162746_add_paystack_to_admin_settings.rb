class AddPaystackToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :paystack_secret_key, :text
    add_column :admin_settings, :paystack_public_key, :text
    add_column :admin_settings, :total_price_cents, :integer, default: 200000
    add_column :admin_settings, :installment_count, :integer, default: 4
    add_column :admin_settings, :trial_start_at, :datetime
  end
end
