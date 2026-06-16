class CreateTopicDigests < ActiveRecord::Migration[8.0]
  def change
    create_table :topic_digests do |t|
      t.references :topic, null: false, foreign_key: true
      t.text :content, null: false
      t.text :scraped_data
      t.date :week_of, null: false
      t.timestamps
    end

    add_index :topic_digests, [:topic_id, :week_of], unique: true
  end
end
