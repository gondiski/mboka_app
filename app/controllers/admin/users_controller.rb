# app/controllers/admin/users_controller.rb
class Admin::UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.includes(:topics, :roles).all
    authorize @users, :index?
  end

  def update_status
    @user = User.find(params[:id])
    authorize @user, :update_status?
    if %w[active suspended blocked].include?(params[:status]) && @user != current_user
      @user.update!(status: params[:status])
      redirect_to admin_users_path, notice: "User status updated securely."
    else
      redirect_to admin_users_path, alert: "Illegal state transformation requested."
    end
  end

  def import
    authorize User, :import?
    if params[:file].present?
      Admin::CsvImportService.call(params[:file])
      redirect_to admin_users_path, notice: "CSV intake batch compiled and running in background."
    else
      redirect_to admin_users_path, alert: "Execution aborted: Missing target attachment."
    end
  end
end
