# frozen_string_literal: true

class Admin::BulkOnboardUserJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform(full_name, email, designation, extra_fields_json = "{}")
    user = User.find_or_initialize_by(email: email)

    if user.persisted?
      Rails.logger.info "BulkOnboard: #{email} already exists, skipping."
      return
    end

    extra = JSON.parse(extra_fields_json) rescue {}

    user.assign_attributes(
      full_name: full_name.presence || "New Colleague",
      designation: designation.presence || "Professional Ecosystem Partner",
      status: "active",
      password: SecureRandom.hex(16),
      phone: extra["phone"],
      country: extra["country"],
      age_range: extra["age_range"],
      education: extra["education"],
      status_description: extra["status_description"] || designation,
      opportunities: extra["opportunities"],
      sectors: extra["sectors"],
      receive_via: extra["receive_via"],
      telegram: extra["telegram"],
      looking_for: extra["looking_for"],
      events_consent: extra["events_consent"],
      consent: extra["consent"],
      form_submitted_at: parse_timestamp(extra["form_submitted_at"]),
      extra_data: extra["extra_data"] || {}
    )

    if user.save
      user.add_role(:subscriber)
      
      explicit_topics = [user.opportunities, user.sectors].compact.join(",").split(",").map(&:strip).reject(&:blank?).uniq
      if explicit_topics.any?
        topics = explicit_topics.map { |name| Topic.find_or_create_by!(name: name) }
        user.topics = topics
      else
        DesignationTopicMatcher.assign_to_user(user)
      end

      token = user.generate_magic_link!
      
      if user.receive_via.to_s.downcase.include?("telegram")
        UserMailer.telegram_welcome(user, token).deliver_now
      else
        UserMailer.account_setup_invitation(user, token).deliver_now
      end
      
      Rails.logger.info "BulkOnboard: Created #{email} and sent invitation."
    else
      Rails.logger.error "BulkOnboard: Failed to create #{email} — #{user.errors.full_messages.join(', ')}"
    end
  end

  private

  def parse_timestamp(value)
    return nil if value.blank?
    Time.parse(value.to_s) rescue nil
  end
end
