# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    authorize @user, policy_class: ProfilePolicy
    @topics = Topic.all
    @tab = params[:tab] || "profile"
    load_digest_data if @tab == "digest"
  end

  def update
    @user = current_user
    authorize @user, policy_class: ProfilePolicy
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Tracking targets updated successfully."
    else
      @topics = Topic.all
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:full_name, :designation, topic_ids: [])
  end

  def load_digest_data
    topic_ids = @user.topic_ids
    @digests = TopicDigest.where(topic_id: topic_ids)
                          .includes(:topic)
                          .order(week_of: :desc, created_at: :desc)
    @favorited_ids = @user.favorites.pluck(:topic_digest_id)
  end
end
