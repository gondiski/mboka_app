# frozen_string_literal: true

class Webhooks::TelegramController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    # Extract message from the update
    message = params.dig(:message)
    return head :ok unless message

    text = message[:text]
    chat_id = message.dig(:chat, :id)

    if text&.start_with?("/start ")
      hashid = text.split("/start ").last.strip
      user_id = User.decode_hashid(hashid)
      
      if user_id.present?
        user = User.find_by(id: user_id)
        if user
          user.update!(telegram_chat_id: chat_id.to_s)
          TelegramDeliveryService.send_message(chat_id, "Welcome to Mboka! 🚀 Your Telegram account has been successfully linked. You will now receive your weekly intelligence digests right here.")
        end
      end
    elsif text == "/start"
      TelegramDeliveryService.send_message(chat_id, "Welcome to Mboka! 🚀 Please click the link in your email to securely link your account.")
    end

    head :ok
  rescue StandardError => e
    Rails.logger.error("Telegram webhook error: #{e.message}")
    head :ok # Always return 200 OK so Telegram doesn't retry
  end
end
