# app/controllers/subscribers_controller.rb
class SubscribersController < ApplicationController
  def new
    authorize :subscriber, :new?
  end

  def create
    authorize :subscriber, :create?
    @user = User.find_or_initialize_by(email: subscriber_params[:email].downcase)

    if @user.new_record?
      @user.full_name = subscriber_params[:full_name]
      @user.designation = subscriber_params[:designation]
      @user.status = "pending"
    end

    if @user.save
      if subscriber_params[:topic_ids].present?
        @user.topic_ids = subscriber_params[:topic_ids]
      else
        DesignationTopicMatcher.assign_to_user(@user)
      end
      @user.add_role(:subscriber) if @user.roles.blank?

      token = @user.generate_magic_link!
      UserMailer.magic_link(@user, token).deliver_now

      redirect_to check_email_path, notice: "Account pre-registered. Check your email to verify!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def subscriber_params
    params.require(:subscriber).permit(:email, :full_name, :designation, topic_ids: [])
  end
end
