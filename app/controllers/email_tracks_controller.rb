class EmailTracksController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def open
    if params[:user_id].present? && params[:mailer].present?
      # Find the latest un-opened message for this user and mailer within the last 7 days
      msg = Ahoy::Message.where(user_id: params[:user_id], mailer: params[:mailer], opened_at: nil)
                         .where("sent_at >= ?", 7.days.ago)
                         .order(sent_at: :desc)
                         .first
      
      msg.update(opened_at: Time.current) if msg
    end

    # Return a 1x1 transparent GIF
    send_data Base64.decode64("R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="), 
              type: "image/gif", disposition: "inline"
  end
end
