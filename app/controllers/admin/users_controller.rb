# app/controllers/admin/users_controller.rb
class Admin::UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.includes(:topics, :roles).order(created_at: :desc)
    authorize @users, :index?, policy_class: Admin::UserPolicy
    @pagy, @users = pagy(@users)
  end

  def update_status
    @user = User.find(params[:id])
    authorize @user, :update_status?, policy_class: Admin::UserPolicy
    if %w[active suspended blocked].include?(params[:status]) && @user != current_user
      @user.update!(status: params[:status])
      redirect_to admin_users_path, notice: "User status updated securely."
    else
      redirect_to admin_users_path, alert: "Illegal state transformation requested."
    end
  end

  def import
    authorize User, :import?, policy_class: Admin::UserPolicy
    if params[:file].present?
      Admin::CsvImportService.call(params[:file])
      redirect_to admin_users_path, notice: "CSV intake batch compiled and running in background."
    else
      redirect_to admin_users_path, alert: "Execution aborted: Missing target attachment."
    end
  end

  def invite
    authorize User, :import?, policy_class: Admin::UserPolicy
    user = User.find_or_initialize_by(email: params[:email]&.downcase)
    if user.new_record?
      user.full_name = params[:full_name] || params[:email]&.split("@")&.first
      user.designation = params[:designation] || "Invited User"
      user.status = "pending"
      user.password = SecureRandom.hex(16)
      user.save!
    end
    role = params[:role].presence_in?(%w[admin moderator subscriber]) ? params[:role] : "subscriber"
    user.add_role(role) unless user.has_role?(role.to_sym)
    token = user.generate_magic_link!
    UserMailer.magic_link(user, token).deliver_later
    redirect_to admin_users_path, notice: "Invitation sent to #{user.email} with role: #{role}."
  end

  private

  def invite_params
    params.permit(:email, :full_name, :designation, :role)
  end
end
