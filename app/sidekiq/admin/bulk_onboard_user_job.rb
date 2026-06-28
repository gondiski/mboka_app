# frozen_string_literal: true

class Admin::BulkOnboardUserJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform(full_name, email, designation, extra_fields_json = "{}")
    user = User.find_or_initialize_by(email: email)

    is_new_user = user.new_record?

    extra = if extra_fields_json.is_a?(Hash)
              extra_fields_json
            else
              JSON.parse(extra_fields_json) rescue {}
            end

    # Only assign password for new records to avoid invalidating existing sessions
    user.password = SecureRandom.hex(16) if is_new_user

    user.assign_attributes(
      full_name: full_name.presence || user.full_name || "New Colleague",
      designation: designation.presence || user.designation || "Professional Ecosystem Partner",
      status: "active",
      phone: extra["phone"] || user.phone,
      country: extra["country"] || user.country,
      age_range: extra["age_range"] || user.age_range,
      education: extra["education"] || user.education,
      status_description: extra["status_description"] || user.status_description || designation,
      opportunities: extra["opportunities"] || user.opportunities,
      sectors: extra["sectors"] || user.sectors,
      receive_via: extra["receive_via"] || user.receive_via,
      telegram: extra["telegram"] || user.telegram,
      looking_for: extra["looking_for"] || user.looking_for,
      events_consent: extra["events_consent"] || user.events_consent,
      consent: extra["consent"] || user.consent,
      form_submitted_at: parse_timestamp(extra["form_submitted_at"]) || user.form_submitted_at,
      extra_data: user.extra_data.merge(extra["extra_data"] || {})
    )

    if user.save
      user.add_role(:subscriber)
      
      explicit_topics = [user.opportunities, user.sectors].compact.join(",").split(",").map(&:strip).reject(&:blank?).uniq
      if explicit_topics.any?
        topics = explicit_topics.map { |name| Topic.find_or_create_by!(name: name) }
        user.topics = topics
      else
        DesignationTopicMatcher.assign_to_user(user) if is_new_user || user.topics.empty?
      end

      if is_new_user
        token = user.generate_magic_link!
        
        if user.receive_via.to_s.downcase.include?("telegram")
          UserMailer.telegram_welcome(user, token).deliver_now
        else
          UserMailer.account_setup_invitation(user, token).deliver_now
        end
        
        Rails.logger.info "BulkOnboard: Created #{email} and sent invitation."
      else
        Rails.logger.info "BulkOnboard: Updated #{email} with explicit topics."
      end
    else
      Rails.logger.error "BulkOnboard: Failed to #{is_new_user ? 'create' : 'update'} #{email} — #{user.errors.full_messages.join(', ')}"
    end
  end

  private

  def parse_timestamp(value)
    return nil if value.blank?
    Time.parse(value.to_s) rescue nil
  end
end
