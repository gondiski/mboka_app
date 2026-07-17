# frozen_string_literal: true

class TopicDigestsController < ApplicationController
  # Allow both logged-in and signed-out users to view digests
  def show
    digest_id = TopicDigest.decode_hashid(params[:id])
    @digest = TopicDigest.includes(:topic).find(digest_id)
    authorize @digest
    @user = current_user
    @favorited = @user&.favorites&.exists?(topic_digest: @digest) || false
  end
end
