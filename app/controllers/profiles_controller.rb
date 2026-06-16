# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    authorize @user
    @topics = Topic.all
  end

  def update
    @user = current_user
    authorize @user
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
end
