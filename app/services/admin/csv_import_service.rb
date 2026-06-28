# frozen_string_literal: true

require "csv"

class Admin::CsvImportService
  HEADER_MAP = {
    "Full Name"                                        => :full_name,
    "Email Address"                                    => :email,
    "Email address"                                    => :email,
    "Phone / WhatsApp Number"                          => :phone,
    "Country"                                          => :country,
    "What is your age range?"                          => :age_range,
    "What is your current level of education or training?" => :education,
    "Which best describes you right now?"              => :status_description,
    "What kind of opportunities would you like to receive?" => :opportunities,
    "Which sectors are you most interested in?"        => :sectors,
    "How would you like to receive the Mboka Opportunity Radar? " => :receive_via,
    "How would you like to receive the Mboka Opportunity Radar?" => :receive_via,
    "If you selected Telegram, what is your Telegram username?  (optional)" => :telegram,
    "If you selected Telegram, what is your Telegram username? (optional)" => :telegram,
    "13. What is one opportunity you are currently looking for?  (optional)" => :looking_for,
    "13. What is one opportunity you are currently looking for? (optional)" => :looking_for,
    "Would you like Mboka to occasionally invite you to events, trainings, surveys, or youth opportunity programs? " => :events_consent,
    "Would you like Mboka to occasionally invite you to events, trainings, surveys, or youth opportunity programs?" => :events_consent,
    "Consent  (required to submit)"                    => :consent,
    "Consent (required to submit)"                     => :consent,
    "Timestamp"                                        => :form_submitted_at,
    # Legacy CSV headers
    "fullname"                                         => :full_name,
    "email"                                            => :email,
    "designation"                                      => :status_description
  }.freeze

  KNOWN_KEYS = HEADER_MAP.values.uniq.freeze

  def self.call(file)
    rows_processed = 0
    rows_skipped = 0
    seen_emails = Set.new

    rows = parse_file(file)

    rows.each do |row|
      mapped = map_headers(row)
      email = mapped[:email]&.strip&.downcase

      if email.blank? || !email.include?("@")
        rows_skipped += 1
        next
      end

      if seen_emails.include?(email)
        rows_skipped += 1
        next
      end
      seen_emails.add(email)

      # Collect any unmapped columns into extra_data
      extra = row.each_with_object({}) do |(k, v), h|
        next if k.blank?
        next if HEADER_MAP.key?(k)
        h[k] = v if v.present?
      end

      mapped[:extra_data] = extra if extra.present?

      # Convert Excel serial timestamp to proper Time (only for CSV; Creek handles xlsx timestamps natively)
      ts = mapped[:form_submitted_at]
      if ts.is_a?(String) && ts.match?(/\A\d{5}\.\d+\z/)
        mapped[:form_submitted_at] = excel_serial_to_time(ts)
      elsif ts.is_a?(Numeric)
        mapped[:form_submitted_at] = excel_serial_to_time(ts)
      end

      Admin::BulkOnboardUserJob.perform_async(
        mapped[:full_name]&.strip,
        email,
        mapped[:status_description]&.strip,
        mapped.except(:full_name, :email, :status_description).to_json
      )
      rows_processed += 1
    end

    Rails.logger.info "CSV Import: #{rows_processed} rows queued, #{rows_skipped} skipped."
    { processed: rows_processed, skipped: rows_skipped }
  end

  def self.parse_file(file)
    path = file.respond_to?(:path) ? file.path : file.to_s

    if path.to_s.end_with?(".xlsx")
      parse_xlsx(path)
    else
      parse_csv(path)
    end
  end

  def self.parse_xlsx(path)
    rows = []
    creek = Creek::Book.new(path)
    sheet = creek.sheets.first

    headers = nil
    sheet.simple_rows.each do |row|
      if headers.nil?
        # First row: map column letters to header names
        headers = row.transform_keys { |k| k.to_s.gsub(/\d+/, "") }
                    .to_a
                    .sort_by { |k, _| k }
                    .map { |_, v| v }
        next
      end

      record = {}
      row.each do |col_letter, value|
        col = col_letter.to_s.gsub(/\d+/, "")
        idx = ("A".."Z").to_a.index(col)
        next if idx.nil? || headers[idx].blank?
        record[headers[idx]] = value
      end
      rows << record
    end
    rows
  end

  def self.parse_csv(path)
    rows = []
    CSV.foreach(path, headers: true) do |row|
      rows << row.to_h
    end
    rows
  end

  def self.map_headers(row)
    mapped = {}
    row.each do |original_header, value|
      next if original_header.blank?
      key = HEADER_MAP[original_header]
      mapped[key] = value if key
    end
    mapped
  end

  EXCEL_EPOCH = Time.new(1899, 12, 30)

  def self.excel_serial_to_time(serial)
    return nil if serial.blank?
    serial = serial.to_f
    days = serial.to_i
    fractional = serial - days
    seconds = (fractional * 86_400).round
    EXCEL_EPOCH + (days * 86_400) + seconds
  rescue
    nil
  end
end
