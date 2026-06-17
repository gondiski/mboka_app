# frozen_string_literal: true

class AddInvitedByToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :invited_by_id, :integer
    add_index :users, :invited_by_id
  end
end
