class AddTelegramChatIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :telegram_chat_id, :string
  end
end
