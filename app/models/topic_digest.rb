# frozen_string_literal: true

class TopicDigest < ApplicationRecord
  belongs_to :topic

  validates :topic_id, uniqueness: { scope: :week_of }
  validates :content, presence: true
  validates :week_of, presence: true

  scope :for_week, ->(date) { where(week_of: date.beginning_of_week) }
  scope :for_topics, ->(topic_ids) { where(topic_id: topic_ids) }

  def self.current_week
    for_week(Date.current)
  end
end
