# frozen_string_literal: true

class Admin::DigestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic_digest, only: [:show, :edit, :update, :approve, :reject, :reset_to_draft]

  def index
    authorize :digest, :index?, policy_class: Admin::DigestPolicy
    @topic_digests = TopicDigest.includes(:topic, :moderated_by).order(week_of: :desc, created_at: :asc)

    apply_filters

    @pagy, @topic_digests = pagy(@topic_digests, items: 10)

    @stats = {
      total: TopicDigest.count,
      draft: TopicDigest.draft.count,
      approved: TopicDigest.approved.count,
      rejected: TopicDigest.rejected.count,
      sent: TopicDigest.sent.count
    }
  end

  def show
    authorize @topic_digest, :show?, policy_class: Admin::DigestPolicy
  end

  def edit
    authorize @topic_digest, :edit?, policy_class: Admin::DigestPolicy
  end

  def update
    authorize @topic_digest, :update?, policy_class: Admin::DigestPolicy

    if @topic_digest.update(digest_params)
      redirect_to admin_digest_path(@topic_digest), notice: "Digest content updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve
    authorize @topic_digest, :approve?, policy_class: Admin::DigestPolicy

    @topic_digest.approve!(current_user)
    clear_analytics_cache
    redirect_to admin_digests_path, notice: "Digest approved for sending."
  end

  def reject
    authorize @topic_digest, :reject?, policy_class: Admin::DigestPolicy

    @topic_digest.reject!(current_user, reason: params[:rejection_reason])
    clear_analytics_cache
    redirect_to admin_digests_path, alert: "Digest rejected."
  end

  def reset_to_draft
    authorize @topic_digest, :reject?, policy_class: Admin::DigestPolicy

    @topic_digest.reset_to_draft!(current_user)
    redirect_to admin_digest_path(@topic_digest), notice: "Digest reset to draft for re-review."
  end

  def bulk_approve
    authorize :digest, :approve?, policy_class: Admin::DigestPolicy

    digest_ids = params[:digest_ids]&.split(",")&.map { |id| TopicDigest.decode_hashid(id) }.compact || []
    week_of = params[:week_of]

    scope = TopicDigest.pending_review
    scope = scope.for_week(Date.parse(week_of)) if week_of.present?
    scope = scope.where(id: digest_ids) if digest_ids.any?

    count = 0
    scope.find_each do |digest|
      digest.approve!(current_user)
      count += 1
    end

    redirect_to admin_digests_path, notice: "#{count} digests approved."
  end

  def run_now
    authorize :digest, :run_now?, policy_class: Admin::DigestPolicy

    week_of = Date.current.beginning_of_week.to_s
    IntelligenceGatheringJob.perform_async(week_of)

    redirect_to admin_digests_path, notice: "Digest generation queued for this week."
  end

  private

  def set_topic_digest
    id = TopicDigest.decode_hashid(params[:id])
    @topic_digest = TopicDigest.includes(:topic, :moderated_by).find(id)
  end

  def digest_params
    params.require(:topic_digest).permit(:content)
  end

  def apply_filters
    if params[:status].present?
      @topic_digests = @topic_digests.where(status: params[:status])
    end

    if params[:topic_id].present?
      @topic_digests = @topic_digests.where(topic_id: params[:topic_id])
    end

    if params[:week].present?
      @topic_digests = @topic_digests.for_week(Date.parse(params[:week]))
    end

    if params[:search].present?
      search = "%#{params[:search]}%"
      @topic_digests = @topic_digests.joins(:topic).where("topics.name ILIKE :search OR topic_digests.content ILIKE :search", search: search)
    end
  end

  def clear_analytics_cache
    Rails.cache.delete("dashboard_stats")
    Rails.cache.delete_matched("reports/*")
  end
end
