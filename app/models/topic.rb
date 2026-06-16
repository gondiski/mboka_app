# app/models/topic.rb
class Topic < ApplicationRecord
  has_many :user_topics, dependent: :destroy
  has_many :users, through: :user_topics
  has_many :topic_digests, dependent: :destroy
  validates :name, presence: true, uniqueness: true
end
