class AddGoogleAnalyticsIdToAdminSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :admin_settings, :google_analytics_id, :string
  end
end
