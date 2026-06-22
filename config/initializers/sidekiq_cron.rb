# frozen_string_literal: true

require "sidekiq/cron"

# Cron jobs are now managed dynamically by Admin::DigestSchedulesController
# They are created/updated when the admin changes the schedule settings.
#
# delivery job: "digest-delivery" - runs on configured delivery days
# generation job: "digest-generation" - runs on configured generation days
