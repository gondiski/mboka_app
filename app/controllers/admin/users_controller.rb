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

  def preview_digest
    user_id = User.decode_hashid(params[:id])
    @profile_user = User.includes(:topics).find(user_id)
    authorize @profile_user, :show?, policy_class: Admin::UserPolicy

    topic_ids = @profile_user.topics.pluck(:id)
    
    if topic_ids.empty?
      render plain: "This user is not subscribed to any topics.", status: :not_found
      return
    end

    current_week = Date.current.beginning_of_week
    # Fetch the digest for the current week for each of the user's topics
    digests = TopicDigest.where(topic_id: topic_ids, week_of: current_week)
                         .to_a

    if digests.empty?
      render plain: "No digests have been generated for this user's topics yet.", status: :not_found
      return
    end

    # Sort them by week_of descending (the DISTINCT ON query sorts by topic_id first)
    digests = digests.sort_by { |d| d.week_of }.reverse

    mail = UserMailer.topic_digest(@profile_user, digests)
    html_content = mail.html_part ? mail.html_part.body.decoded : mail.body.decoded
    render html: html_content.html_safe
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
      respond_to do |format|
        format.json { render json: { processed: result[:processed], skipped: result[:skipped] } }
        format.html { redirect_to admin_users_path, notice: "#{result[:processed]} users queued for onboarding." }
      end
    else
      respond_to do |format|
        format.json { render json: { processed: 0, skipped: 0, error: "No file selected" }, status: :unprocessable_entity }
        format.html { redirect_to admin_users_path, alert: "No file selected." }
      end
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
    UserMailer.magic_link(user, token).deliver_now
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
