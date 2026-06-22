class AddUsernameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :username, :string unless column_exists?(:users, :username)
    add_column :users, :username_changed_at, :datetime unless column_exists?(:users, :username_changed_at)
    add_index :users, :username, unique: true unless index_exists?(:users, :username)
  end
end
