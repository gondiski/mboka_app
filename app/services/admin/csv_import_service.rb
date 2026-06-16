# app/services/admin/csv_import_service.rb
require "csv"

class Admin::CsvImportService
  def self.call(file)
    CSV.foreach(file.path, headers: true) do |row|
      next unless row["email"].present?
      Admin::BulkOnboardUserJob.perform_async(
        row["fullname"]&.strip,
        row["email"]&.strip&.downcase,
        row["designation"]&.strip
      )
    end
  end
end
