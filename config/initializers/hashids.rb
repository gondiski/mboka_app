# frozen_string_literal: true

Rails.application.config.after_initialize do
  HASHIDS = Hashids.new(
    ENV.fetch("HASHIDS_SALT", "mboka-digest-2026"),
    8,
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
  )
end
