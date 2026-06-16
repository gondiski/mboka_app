# frozen_string_literal: true

class FavoritesController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_authorized

  def toggle
    digest = TopicDigest.find(params[:topic_digest_id])
    favorite = current_user.favorites.find_by(topic_digest: digest)

    if favorite
      favorite.destroy
      favorited = false
    else
      current_user.favorites.create!(topic_digest: digest)
      favorited = true
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "favorite_#{digest.id}",
          partial: "favorites/star",
          locals: { digest: digest, favorited: favorited }
        )
      end
      format.json { render json: { favorited: favorited } }
      format.html { redirect_back fallback_location: profile_path(tab: "digest") }
    end
  end
end
