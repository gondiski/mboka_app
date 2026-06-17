# frozen_string_literal: true

class AddInvitedByTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :invited_by_type, :string
    add_index :users, [:invited_by_type, :invited_by_id]
  end
end
