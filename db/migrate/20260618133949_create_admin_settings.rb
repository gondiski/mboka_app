class CreateAdminSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_settings do |t|
      t.text :serpapi_key
      t.text :anthropic_api_key

      t.timestamps
    end
  end
end
