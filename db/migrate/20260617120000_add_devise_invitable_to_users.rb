# frozen_string_literal: true

class AddDeviseInvitableToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :invitation_token
      t.datetime :invitation_created_at
      t.datetime :invitation_sent_at
      t.datetime :invitation_accepted_at
      t.integer :invitation_accepted_count, default: 0
    end

    add_index :users, :invitation_token, unique: true
  end
end
