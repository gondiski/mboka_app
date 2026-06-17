# frozen_string_literal: true

class AddEmailPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :unsubscribe_token
      t.boolean :subscribed, default: true, null: false
      t.datetime :unsubscribed_at
    end

    add_index :users, :unsubscribe_token, unique: true
  end
end
