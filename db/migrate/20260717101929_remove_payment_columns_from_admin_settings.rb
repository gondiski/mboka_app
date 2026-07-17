class RemovePaymentColumnsFromAdminSettings < ActiveRecord::Migration[8.0]
  def change
    remove_column :admin_settings, :trial_start_at, :datetime
    remove_column :admin_settings, :total_price_cents, :integer
    remove_column :admin_settings, :installment_count, :integer
  end
end
