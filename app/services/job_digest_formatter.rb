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
      <hr style="margin: 24px 0; border: none; border-top: 1px solid #e5e7eb;">
      <h3 style="color: #1e40af; font-size: 16px; margin-bottom: 12px;">
        Recent Kenya Job Openings
      </h3>
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse;">
        #{@jobs.map { |job| job_row(job) }.join}
      </table>
      <p style="font-size: 12px; color: #9ca3af; margin-top: 8px;">
        Jobs sourced via Google Jobs &middot; Updated #{@jobs.first&.dig(:posted_at) || "recently"}
      </p>
    HTML
  end

  private

  def job_row(job)
    <<~HTML
      <tr>
        <td style="padding: 8px 0; border-bottom: 1px solid #f3f4f6;">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
            <tr>
              <td>
                <a href="#{ERB::Util.html_escape(job[:link])}" style="color: #16a34a; font-weight: 600; text-decoration: none; font-size: 14px;">
                  #{ERB::Util.html_escape(job[:title])}
                </a>
                <br>
                <span style="color: #6b7280; font-size: 13px;">
                  #{ERB::Util.html_escape(job[:company])} &middot; #{ERB::Util.html_escape(job[:location])}
                  #{"&middot; <em>#{ERB::Util.html_escape(job[:posted_at])}</em>" if job[:posted_at].present?}
                </span>
                #{"<br><span style=\"color: #9ca3af; font-size: 12px;\">#{ERB::Util.html_escape(job[:description])}</span>" if job[:description].present?}
              </td>
            </tr>
          </table>
        </td>
      </tr>
    HTML
  end
end
