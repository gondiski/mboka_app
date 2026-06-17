# frozen_string_literal: true

class TopicDigest < ApplicationRecord
  include Hashidable

  belongs_to :topic
  belongs_to :moderated_by, class_name: "User", optional: true

  validates :topic_id, uniqueness: { scope: :week_of }
  validates :content, presence: true
  validates :week_of, presence: true

  attribute :status, :integer, default: 0

  enum :status, { draft: 0, approved: 1, rejected: 2, sent: 3 }

  scope :for_week, ->(date) { where(week_of: date.beginning_of_week) }
  scope :for_topics, ->(topic_ids) { where(topic_id: topic_ids) }
  scope :pending_review, -> { where(status: :draft) }
  scope :ready_to_send, -> { where(status: :approved) }
  scope :modifiable, -> { where(status: %w[draft rejected]) }

  def self.current_week
    for_week(Date.current)
  end

  def approve!(user)
    update!(status: :approved, moderated_at: Time.current, moderated_by: user, rejection_reason: nil)
  end

  def reject!(user, reason: nil)
    update!(status: :rejected, moderated_at: Time.current, moderated_by: user, rejection_reason: reason)
  end

  def reset_to_draft!(user)
    update!(status: :draft, moderated_at: Time.current, moderated_by: user, rejection_reason: nil)
  end

  def status_label
    case status
    when "draft" then "Pending Review"
    when "approved" then "Approved"
    when "rejected" then "Rejected"
    when "sent" then "Sent"
    end
  end

  def status_color
    case status
    when "draft" then "amber"
    when "approved" then "green"
    when "rejected" then "red"
    when "sent" then "blue"
    end
  end
end
