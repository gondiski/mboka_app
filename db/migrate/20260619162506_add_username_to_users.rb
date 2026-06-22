class AddUsernameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :username, :string
    add_column :users, :username_changed_at, :datetime
    add_index :users, :username, unique: true
  end
end
