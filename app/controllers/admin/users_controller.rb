# frozen_string_literal: true

require "csv"

class Admin::UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.includes(:topics, :roles).order(created_at: :desc)
    authorize @users, :index?, policy_class: Admin::UserPolicy

    apply_filters

    @per_page = (params[:per_page] || 10).to_i.clamp(5, 50)
    @pagy, @users = pagy(@users, items: @per_page)

    @topics = Topic.all.order(:name)
    @roles = ["admin", "moderator", "subscriber"]
  end

  def show
    user_id = User.decode_hashid(params[:id])
    @profile_user = User.includes(:topics, :roles, :favorites).find(user_id)
    authorize @profile_user, :show?, policy_class: Admin::UserPolicy
    favorited = @profile_user.favorited_digests.includes(:topic).order(week_of: :desc)
    @pagy_favorites, @favorited_digests = pagy(favorited, items: 10)
  end

  def update_status
    user_id = User.decode_hashid(params[:id])
    @user = User.find(user_id)
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
      result = Admin::CsvImportService.call(params[:file])
      redirect_to admin_users_path, notice: "#{result[:processed]} users queued for onboarding."
    else
      redirect_to admin_users_path, alert: "No file selected."
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
    role = params[:role].presence_in(%w[admin moderator subscriber]) || "subscriber"
    user.add_role(role) unless user.has_role?(role.to_sym)
    token = user.generate_magic_link!
    UserMailer.magic_link(user, token).deliver_later
    redirect_to admin_users_path, notice: "Invitation sent to #{user.email} with role: #{role}."
  end

  def update_role
    user_id = User.decode_hashid(params[:id])
    @user = User.find(user_id)
    authorize @user, :update_status?, policy_class: Admin::UserPolicy
    new_role = params[:role].presence_in(%w[admin moderator subscriber])
    if new_role && @user != current_user
      @user.roles.destroy_all
      @user.add_role(new_role)
      redirect_to admin_users_path, notice: "Role updated to #{new_role} for #{@user.email}."
    else
      redirect_to admin_users_path, alert: "Invalid role or cannot change your own role."
    end
  end

  def download_template
    authorize User, :import?, policy_class: Admin::UserPolicy
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ["fullname", "email", "designation"]
      csv << ["John Doe", "john@example.com", "Software Engineer"]
      csv << ["Jane Smith", "jane@example.com", "Product Designer"]
      csv << ["Bob Johnson", "bob@example.com", "NGO Program Manager"]
    end
    send_data csv_data, filename: "mboka_user_import_template_#{Date.current}.csv", type: "text/csv"
  end

  private

  def invite_params
    params.permit(:email, :full_name, :designation, :role)
  end

  def apply_filters
    if params[:search].present?
      search = "%#{params[:search]}%"
      @users = @users.where(
        "full_name ILIKE :search OR email ILIKE :search OR designation ILIKE :search",
        search: search
      )
    end

    if params[:role].present?
      @users = @users.joins(:roles).where(roles: { name: params[:role] })
    end

    if params[:topic_id].present?
      @users = @users.joins(:user_topics).where(user_topics: { topic_id: params[:topic_id] })
    end

    if params[:status].present?
      @users = @users.where(status: params[:status])
    end
  end
end
