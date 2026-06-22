# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  def show
    @user = current_user
    authorize @user, policy_class: ProfilePolicy
    @topics = Topic.all
    @tab = params[:tab] || "profile"
    load_digest_data if @tab == "digest"
    load_favorites if @tab == "favorites"
  end

  def update
    @user = current_user
    authorize @user, policy_class: ProfilePolicy

    if username_changing?
      unless @user.can_change_username?
        @topics = Topic.all
        flash.now[:alert] = "Username can only be changed once every 48 hours. You can change it again in #{@user.username_cooldown_display}."
        render :show, status: :unprocessable_entity
        return
      end
    end

    if @user.update(profile_params.merge(username_change_timestamp))
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      @topics = Topic.all
      render :show, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:full_name, :username, :designation, topic_ids: [])
  end

  def username_changing?
    params.dig(:user, :username).present? && params.dig(:user, :username).strip != @user.username
  end

  def username_change_timestamp
    username_changing? ? { username_changed_at: Time.current } : {}
  end

  def load_digest_data
    topic_ids = @user.topic_ids
    digests = TopicDigest.where(topic_id: topic_ids)
                         .includes(:topic)
                         .order(week_of: :desc, created_at: :desc)
    @pagy_digests, @digests = pagy(digests, items: 10)
    @favorited_hashids = @user.favorites.joins(:topic_digest)
                               .pluck("topic_digests.id")
                               .map { |id| HASHIDS.encode(id) }
  end

  def load_favorites
    favorited = @user.favorited_digests
                     .includes(:topic)
                     .order(week_of: :desc, created_at: :desc)
    @pagy_favorites, @favorited_digests = pagy(favorited, items: 10)
  end
end
