class CreateFavorites < ActiveRecord::Migration[8.0]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :topic_digest, null: false, foreign_key: true

      t.timestamps
    end

    add_index :favorites, [:user_id, :topic_digest_id], unique: true
  end
end
