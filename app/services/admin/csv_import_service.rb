# frozen_string_literal: true

require "csv"

class Admin::CsvImportService
  def self.call(file)
    rows_processed = 0
    rows_skipped = 0

    CSV.foreach(file.path, headers: true) do |row|
      if row["email"].blank?
        rows_skipped += 1
        next
      end

      Admin::BulkOnboardUserJob.perform_async(
        row["fullname"]&.strip,
        row["email"]&.strip&.downcase,
        row["designation"]&.strip
      )
      rows_processed += 1
    end

    Rails.logger.info "CSV Import: #{rows_processed} rows queued, #{rows_skipped} skipped."
    { processed: rows_processed, skipped: rows_skipped }
  end
end
