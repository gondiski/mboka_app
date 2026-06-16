# frozen_string_literal: true

class DigestSchedule < ApplicationRecord
  validates :days, presence: true
  validates :send_time, presence: true
  validate :singleton_record, on: :create

  scope :active_schedule, -> { where(active: true).last }

  DAYS_OF_WEEK = {
    "Sunday" => 0,
    "Monday" => 1,
    "Tuesday" => 2,
    "Wednesday" => 3,
    "Thursday" => 4,
    "Friday" => 5,
    "Saturday" => 6
  }.freeze

  def should_send_today?(date = Date.current)
    days.include?(date.wday)
  end

  def cron_expression
    return nil if send_time.blank? || days.blank?

    minute = send_time.min
    hour = send_time.hour
    day_names = days.map { |d| DAY_NAMES[d] }.compact.join(",")

    "#{minute} #{hour} * * #{day_names}"
  end

  def days=(value)
    clean_days = Array(value).reject(&:blank?).map(&:to_i)
    write_attribute(:days, clean_days)
  end

  private

  def singleton_record
    if DigestSchedule.exists?
      errors.add(:base, "Only one digest schedule is allowed")
    end
  end

  DAY_NAMES = {
    0 => "SUN",
    1 => "MON",
    2 => "TUE",
    3 => "WED",
    4 => "THU",
    5 => "FRI",
    6 => "SAT"
  }.freeze
end
