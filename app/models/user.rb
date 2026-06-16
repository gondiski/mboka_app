# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :validatable

  rolify
  has_many :user_topics, dependent: :destroy
  has_many :topics, through: :user_topics
  has_many :messages, class_name: "Ahoy::Message", as: :user
  has_many :topic_digests, through: :topics
  has_many :favorites, dependent: :destroy
  has_many :favorited_digests, through: :favorites, source: :topic_digest

  validates :full_name, presence: true
  validates :status, inclusion: { in: %w[pending active suspended blocked] }

  # Passwordless setup configuration
  def password_required?
    false
  end

  def active_for_authentication?
    super && status == "active"
  end

  def inactive_message
    status == "active" ? super : "Your account is currently #{status}."
  end

  def generate_magic_link!
    raw_token = SecureRandom.hex(24)
    update!(
      magic_link_token: Devise.token_generator.digest(self.class, :magic_link_token, raw_token),
      magic_link_expires_at: 15.minutes.from_now
    )
    raw_token
  end
end
