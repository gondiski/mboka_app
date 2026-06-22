# frozen_string_literal: true

class Admin::BulkOnboardUserJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 3

  def perform(full_name, email, designation)
    user = User.find_or_initialize_by(email: email)

    if user.persisted?
      Rails.logger.info "BulkOnboard: #{email} already exists, skipping."
      return
    end

    user.assign_attributes(
      full_name: full_name.presence || "New Colleague",
      designation: designation.presence || "Professional Ecosystem Partner",
      status: "active",
      password: SecureRandom.hex(16)
    )

    if user.save
      user.add_role(:subscriber)
      DesignationTopicMatcher.assign_to_user(user)
      token = user.generate_magic_link!
      UserMailer.account_setup_invitation(user, token).deliver_now
      Rails.logger.info "BulkOnboard: Created #{email} and sent invitation."
    else
      Rails.logger.error "BulkOnboard: Failed to create #{email} — #{user.errors.full_messages.join(', ')}"
    end
  end
end
