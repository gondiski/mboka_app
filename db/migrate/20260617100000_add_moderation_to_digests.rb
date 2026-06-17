# frozen_string_literal: true

class AddModerationToDigests < ActiveRecord::Migration[8.0]
  def change
    add_column :topic_digests, :status, :integer, default: 0, null: false
    add_column :topic_digests, :moderated_at, :datetime
    add_column :topic_digests, :moderated_by, :bigint
    add_column :topic_digests, :rejection_reason, :text

    add_index :topic_digests, :status
    add_foreign_key :topic_digests, :users, column: :moderated_by

    add_column :digest_schedules, :generation_day, :integer, default: 0, null: false
  end
end
