class CreateUserTopics < ActiveRecord::Migration[8.0]
  def change
    create_table :user_topics do |t|
      t.timestamps
    end
  end
end
