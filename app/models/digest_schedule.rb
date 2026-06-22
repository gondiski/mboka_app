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

  DAY_NAMES = {
    0 => "SUN",
    1 => "MON",
    2 => "TUE",
    3 => "WED",
    4 => "THU",
    5 => "FRI",
    6 => "SAT"
  }.freeze

  GENERATION_DAY_OPTIONS = {
    "Same day as delivery" => -1,
    "1 day before" => -2,
    "2 days before" => -3,
    "3 days before" => -4,
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

  def should_generate_today?(date = Date.current)
    return false unless active?
    return false if days.blank?

    if generation_day == -1
      # Same day as delivery
      should_send_today?(date)
    elsif generation_day_negative?
      # Relative days before delivery (e.g., -2 = 2 days before)
      offset = generation_day.abs - 1
      days.any? do |send_day|
        generate_day = (send_day - offset) % 7
        date.wday == generate_day
      end
    else
      # Specific day of week (0-6)
      date.wday == generation_day
    end
  end

  def generation_day_name
    return "Same day as delivery" if generation_day == -1
    return "#{generation_day.abs - 1} day(s) before delivery" if generation_day_negative?
    DAYS_OF_WEEK.key(generation_day) || "Unknown"
  end

  # Cron expression for the delivery days
  def cron_expression
    return nil if send_time.blank? || days.blank?

    minute = send_time.min
    hour = send_time.hour
    day_names = days.map { |d| DAY_NAMES[d] }.compact.join(",")

    "#{minute} #{hour} * * #{day_names}"
  end

  # Cron expression for the generation day
  def generation_cron_expression
    return nil if send_time.blank?
    return nil unless active?

    minute = send_time.min
    # Generate 2 hours before delivery time
    hour = [send_time.hour - 2, 0].max

    if generation_day == -1
      # Same day as delivery - use same cron as delivery
      return cron_expression
    elsif generation_day_negative?
      # Relative days before delivery
      offset = generation_day.abs - 1
      gen_days = days.map { |d| (d - offset) % 7 }
      day_names = gen_days.map { |d| DAY_NAMES[d] }.compact.join(",")
      return "#{minute} #{hour} * * #{day_names}"
    else
      # Specific day of week
      day_name = DAY_NAMES[generation_day]
      return "#{minute} #{hour} * * #{day_name}"
    end
  end

  def days=(value)
    clean_days = Array(value).reject(&:blank?).map(&:to_i)
    write_attribute(:days, clean_days)
  end

  private

  def generation_day_negative?
    generation_day.present? && generation_day < -1
  end

  def singleton_record
    if DigestSchedule.exists?
      errors.add(:base, "Only one digest schedule is allowed")
    end
  end
end
