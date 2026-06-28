# frozen_string_literal: true

class JobDigestFormatter
  def self.format(jobs)
    new(jobs).to_html
  end

  def initialize(jobs)
    @jobs = jobs
  end

  def to_html
    return "" if @jobs.blank?

    <<~HTML
      <div style="background-color: #f8fafc; border-radius: 16px; padding: 24px; margin-top: 24px; border: 1px solid #f1f5f9;">
        <h3 style="color: #0f172a; font-size: 18px; margin: 0 0 16px; font-family: 'Outfit', sans-serif; font-weight: 700;">
          Top Jobs in Kenya
        </h3>
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse: separate; border-spacing: 0 8px;">
          #{@jobs.map { |job| job_row(job) }.join}
        </table>
        <p style="font-size: 13px; color: #94a3b8; margin: 16px 0 0; text-align: center;">
          Curated from Google Jobs &middot; Updated #{@jobs.first&.dig(:posted_at) || "recently"}
        </p>
      </div>
    HTML
  end

  private

  def job_row(job)
    <<~HTML
      <tr>
        <td style="padding: 16px; background-color: #ffffff; border-radius: 12px; border: 1px solid #e2e8f0; box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
            <tr>
              <td>
                <a href="#{ERB::Util.html_escape(job[:link])}" style="color: #059669; font-weight: 700; text-decoration: none; font-size: 15px; font-family: 'Inter', sans-serif; display: block; margin-bottom: 4px;">
                  #{ERB::Util.html_escape(job[:title])}
                </a>
                <span style="color: #475569; font-size: 14px; font-weight: 500;">
                  #{ERB::Util.html_escape(job[:company])}
                </span>
                <span style="color: #94a3b8; font-size: 13px; margin-left: 8px;">
                  &bull; #{ERB::Util.html_escape(job[:location])}
                  #{"&bull; <em>#{ERB::Util.html_escape(job[:posted_at])}</em>" if job[:posted_at].present?}
                </span>
                #{"<div style=\"color: #64748b; font-size: 13px; margin-top: 8px; line-height: 1.5;\">#{ERB::Util.html_escape(job[:description])}</div>" if job[:description].present?}
              </td>
            </tr>
          </table>
        </td>
      </tr>
    HTML
  end
end
