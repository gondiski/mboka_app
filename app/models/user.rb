# app/models/user.rb
class User < ApplicationRecord
  include Hashidable

  RESERVED_USERNAMES = %w[
    admin administrator superadmin superuser root system
    god moderator mod support help staff team owner
    database db postgres redis cache
    api bot webapp app service
    null undefined none false true
    login logout signin signup register auth
    profile account settings config
    www mail email ftp ssh ssl tls
    test staging production dev
    mboka official security
    hack exploit abuse spam troll
    anonymous guest user default
  ].freeze

  USERNAME_FORMAT = /\A[a-zA-Z0-9_]+\z/
  USERNAME_MIN_LENGTH = 3
  USERNAME_MAX_LENGTH = 24
  USERNAME_COOLDOWN = 48.hours

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

  validates :username, uniqueness: { case_sensitive: false, allow_nil: true },
            format: { with: USERNAME_FORMAT, message: "can only contain letters, numbers, and underscores", allow_nil: true },
            length: { minimum: USERNAME_MIN_LENGTH, maximum: USERNAME_MAX_LENGTH, allow_nil: true }
  validate :username_not_reserved
  validate :username_change_cooldown

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
      magic_link_expires_at: 1.hour.from_now
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
    username.presence || full_name.presence || email
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

  def can_change_username?
    return true if username_changed_at.nil?
    username_changed_at + USERNAME_COOLDOWN < Time.current
  end

  def username_cooldown_remaining
    return 0 if username_changed_at.nil?
    remaining = (username_changed_at + USERNAME_COOLDOWN - Time.current).to_i
    [remaining, 0].max
  end

  def username_cooldown_display
    seconds = username_cooldown_remaining
    return "now" if seconds <= 0
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end

  private

  def username_not_reserved
    return if username.blank?
    if RESERVED_USERNAMES.include?(username.downcase.strip)
      errors.add(:username, "is reserved and cannot be used")
    end
  end

  def username_change_cooldown
    return unless will_save_change_to_attribute?(:username)
    return if username_changed_at.nil?
    return if username_was.nil?
    unless can_change_username?
      remaining = username_cooldown_display
      errors.add(:username, "can only be changed once every 48 hours. Try again in #{remaining}")
    end
  end

  def after_create_commit_generate_unsubscribe_token
    generate_unsubscribe_token! if unsubscribe_token.blank?
  end
end
