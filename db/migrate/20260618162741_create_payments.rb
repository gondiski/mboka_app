class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :admin_setting, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.integer :installment_number, null: false
      t.integer :status, default: 0, null: false
      t.string :paystack_reference
      t.datetime :paid_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :payments, :paystack_reference, unique: true
    add_index :payments, :status
    add_index :payments, [ :admin_setting_id, :installment_number ], unique: true
  end
end
