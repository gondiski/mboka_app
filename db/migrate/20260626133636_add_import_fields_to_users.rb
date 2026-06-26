class AddImportFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :country, :string
    add_column :users, :age_range, :string
    add_column :users, :education, :string
    add_column :users, :status_description, :string
    add_column :users, :opportunities, :string
    add_column :users, :sectors, :string
    add_column :users, :receive_via, :string
    add_column :users, :telegram, :string
    add_column :users, :looking_for, :string
    add_column :users, :events_consent, :string
    add_column :users, :consent, :string
    add_column :users, :form_submitted_at, :datetime
    add_column :users, :extra_data, :jsonb, default: {}
  end
end
