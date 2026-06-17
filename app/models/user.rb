# app/models/user.rb
class User < ApplicationRecord
  include Hashidable

  devise :database_authenticatable, :registerable, :validatable, :invitable,
         invite_for: 2.weeks,
         validate_on_invite: false

  rolify
  has_many :user_topics, dependent: :destroy
  has_many :topics, through: :user_topics
  has_many :messages, class_name: "Ahoy::Message", as: :user
  has_many :topic_digests, through: :topics
  has_many :favorites, dependent: :destroy
  has_many :favorited_digests, through: :favorites, source: :topic_digest

  validates :full_name, presence: true
  validates :status, inclusion: { in: %w[pending active suspended blocked] }
  validates :unsubscribe_token, uniqueness: true, allow_nil: true

  scope :subscribed_to_emails, -> { where(subscribed: true) }
  scope :unsubscribed_from_emails, -> { where(subscribed: false) }

  after_create_commit :generate_unsubscribe_token!

  # Skip password validation for passwordless system
  def password_required?
    false
  end

  # Devise Invitable: skip password on invitation acceptance
  def password_match?(password)
    true
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

  def generate_unsubscribe_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update_column(:unsubscribe_token, raw_token)
    raw_token
  end

  def unsubscribe_from_emails!
    update!(subscribed: false, unsubscribed_at: Time.current)
  end

  def resubscribe_to_emails!
    update!(subscribed: true, unsubscribed_at: nil)
  end

  def email_display_name
    full_name.presence || email
  end

  def subscribed_to_topic?(topic)
    topics.include?(topic)
  end

  def invited?
    invitation_token.present? && invitation_accepted_at.nil?
  end

  def accept_invitation!
    update!(
      invitation_accepted_at: Time.current,
      invitation_accepted_count: invitation_accepted_count + 1,
      status: "active"
    )
  end

  private

  def after_create_commit_generate_unsubscribe_token
    generate_unsubscribe_token! if unsubscribe_token.blank?
  end
end
