# frozen_string_literal: true

require "sidekiq/cron"

if Sidekiq.server?
  Sidekiq::Cron::Job.create(
    name: "digest-scheduler",
    cron: "* * * * *",
    class: "DigestSchedulerJob"
  )
end
