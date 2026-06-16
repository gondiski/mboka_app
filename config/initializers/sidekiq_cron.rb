# frozen_string_literal: true

require "sidekiq/cron"

Sidekiq::Cron::Job.create(
  name: "digest-scheduler",
  cron: "* * * * *",
  class: "DigestSchedulerJob"
)
