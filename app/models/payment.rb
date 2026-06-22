# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :admin_setting

  enum :status, { pending: 0, success: 1, failed: 2 }

  scope :completed, -> { where(status: :success) }
  scope :active, -> { completed.where("expires_at > ?", Time.current) }
  scope :expired, -> { completed.where("expires_at <= ?", Time.current) }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :installment_number, presence: true,
            numericality: { greater_than: 0 },
            uniqueness: { scope: :admin_setting_id }
  validates :paystack_reference, uniqueness: true, allow_nil: true

  def amount_dollars
    amount_cents / 100.0
  end

  def active?
    success? && expires_at&.future?
  end

  def mark_success!(reference:, paid_at: Time.current)
    update!(
      status: :success,
      paystack_reference: reference,
      paid_at: paid_at,
      expires_at: paid_at + 30.days
    )
  end

  def mark_failed!(reference: nil)
    update!(status: :failed, paystack_reference: reference)
  end
end
