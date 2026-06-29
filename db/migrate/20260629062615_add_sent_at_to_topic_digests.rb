class AddSentAtToTopicDigests < ActiveRecord::Migration[8.0]
  def change
    add_column :topic_digests, :sent_at, :datetime
  end
end
