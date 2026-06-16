# app/sidekiq/admin/bulk_onboard_user_job.rb
class Admin::BulkOnboardUserJob
  include Sidekiq::Job
  queue_as :default

  def perform(full_name, email, designation)
    user = User.find_or_initialize_by(email: email)
    return unless user.new_record?

    user.assign_attributes(
      full_name: full_name || "New Colleague",
      designation: designation || "Professional Ecosystem Partner",
      status: "pending"
    )

    if user.save
      user.add_role(:subscriber)
      token = user.generate_magic_link!
      UserMailer.account_setup_invitation(user, token).deliver_now
    end
  end
end
