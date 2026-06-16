# frozen_string_literal: true

class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :topic_digest

  validates :user_id, uniqueness: { scope: :topic_digest_id }
end
