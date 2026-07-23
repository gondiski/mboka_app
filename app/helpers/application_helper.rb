# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend
  def inject_utm_links(html_content, source: "digest", medium: "email", campaign: "", content: "", user_id: nil, mailer: nil)
    return html_content if html_content.blank?

    doc = Nokogiri::HTML.fragment(html_content)

    doc.css("a[href]").each do |link|
      href = link["href"]
      next if href.blank? || href.start_with?("#") || href.start_with?("mailto:")

      uri = URI.parse(href) rescue nil
      next unless uri

      existing_params = Rack::Utils.parse_nested_query(uri.query || "")
      existing_params["utm_source"] = source
      existing_params["utm_medium"] = medium
      existing_params["utm_campaign"] = campaign if campaign.present?
      existing_params["utm_content"] = content.to_s if content.present?

      uri.query = URI.encode_www_form(existing_params)
      
      final_url = uri.to_s
      
      if user_id.present? && mailer.present?
        final_url = Rails.application.routes.url_helpers.track_click_url(
          url: final_url, 
          user_id: user_id, 
          mailer: mailer, 
          host: ActionMailer::Base.default_url_options[:host] || "mboka.dnrstudios.co.ke"
        )
      end

      link["href"] = final_url
    end

    doc.to_html
  end

  def truncate_html(text, length: 200, omission: "...")
    return text if text.blank?

    doc = Nokogiri::HTML.fragment(text)
    plain_text = doc.text.strip

    if plain_text.length <= length
      text
    else
      truncated = plain_text.truncate(length, omission: omission)
      "<p>#{ERB::Util.html_escape(truncated)}</p>".html_safe
    end
  end

  AVATAR_THEMES = [
    { bg: "fef3c7", hex: "#fef3c7", bright: "#fbbf24", light: "#fef9c3" },
    { bg: "fde68a", hex: "#fde68a", bright: "#f59e0b", light: "#fef3c7" },
    { bg: "dcfce7", hex: "#dcfce7", bright: "#22c55e", light: "#f0fdf4" },
    { bg: "b6e3f4", hex: "#b6e3f4", bright: "#38bdf8", light: "#e0f2fe" },
    { bg: "c0aede", hex: "#c0aede", bright: "#a78bfa", light: "#ede9fe" },
    { bg: "d1d4f9", hex: "#d1d4f9", bright: "#818cf8", light: "#eef2ff" },
    { bg: "ffd5dc", hex: "#ffd5dc", bright: "#fb7185", light: "#fff1f2" },
    { bg: "fed7aa", hex: "#fed7aa", bright: "#f97316", light: "#fff7ed" },
    { bg: "fecdd3", hex: "#fecdd3", bright: "#f43f5e", light: "#fff1f2" }
  ].freeze

  def avatar_theme(user)
    AVATAR_THEMES[user.id % AVATAR_THEMES.length]
  end

  def avatar_bg_colors(user)
    AVATAR_THEMES.map { |t| t[:bg] }.join(",")
  end

  def topographic_pattern_svg(user, pattern_id: "topo-waves")
    theme = avatar_theme(user)
    bright = theme[:bright]
    light = theme[:light]

    r, g, b = hex_to_rgb(bright)

    content_tag(:div, class: "h-48 relative overflow-hidden", style: "background-color: #{light}") do
      svg = <<~SVG.html_safe
        <svg class="absolute inset-0 w-full h-full" viewBox="0 0 900 240" preserveAspectRatio="xMidYMid slice" xmlns="http://www.w3.org/2000/svg">
          <!-- Deep contour — broad, faint -->
          <path d="M-20,200 C40,180 100,210 170,185 C240,160 310,195 380,170 C450,145 520,185 590,160 C660,135 730,175 800,150 C870,125 930,165 970,140" fill="none" stroke="rgba(#{r},#{g},#{b},0.18)" stroke-width="5" stroke-linecap="round"/>
          <path d="M-30,40 C40,20 110,55 180,30 C250,5 320,45 390,20 C460,-5 530,40 600,15 C670,-10 740,30 810,5 C880,-20 940,25 980,5" fill="none" stroke="rgba(#{r},#{g},#{b},0.14)" stroke-width="4" stroke-linecap="round"/>

          <!-- Mid contour — defined, flowing -->
          <path d="M-10,165 C30,150 70,175 120,158 C170,141 220,170 270,153 C320,136 370,165 420,148 C470,131 520,160 570,143 C620,126 670,155 720,138 C770,121 820,150 870,133 C920,116 960,145 990,128" fill="none" stroke="rgba(#{r},#{g},#{b},0.28)" stroke-width="3.5" stroke-linecap="round"/>
          <path d="M-15,115 C25,100 65,128 115,110 C165,92 215,122 265,104 C315,86 365,116 415,98 C465,80 515,110 565,92 C615,74 665,104 715,86 C765,68 815,98 865,80 C915,62 955,92 990,74" fill="none" stroke="rgba(#{r},#{g},#{b},0.32)" stroke-width="3" stroke-linecap="round"/>
          <path d="M-10,72 C30,58 65,85 115,68 C165,51 215,80 265,63 C315,46 365,75 415,58 C465,41 515,70 565,53 C615,36 665,65 715,48 C765,31 815,60 865,43 C915,26 955,55 990,38" fill="none" stroke="rgba(#{r},#{g},#{b},0.24)" stroke-width="2.5" stroke-linecap="round"/>

          <!-- Tight contour lines — topographic detail -->
          <path d="M0,225 C20,218 40,228 60,221 C80,214 100,226 120,219 C140,212 160,224 180,217 C200,210 220,222 240,215 C260,208 280,220 300,213 C320,206 340,218 360,211 C380,204 400,216 420,209 C440,202 460,214 480,207 C500,200 520,212 540,205 C560,198 580,210 600,203 C620,196 640,208 660,201 C680,194 700,206 720,199 C740,192 760,204 780,197 C800,190 820,202 840,195 C860,188 880,200 900,193" fill="none" stroke="rgba(#{r},#{g},#{b},0.4)" stroke-width="1.8" stroke-linecap="round"/>
          <path d="M0,190 C25,182 50,194 75,186 C100,178 125,190 150,182 C175,174 200,186 225,178 C250,170 275,182 300,174 C325,166 350,178 375,170 C400,162 425,174 450,166 C475,158 500,170 525,162 C550,154 575,166 600,158 C625,150 650,162 675,154 C700,146 725,158 750,150 C775,142 800,154 825,146 C850,138 875,150 900,142" fill="none" stroke="rgba(#{r},#{g},#{b},0.38)" stroke-width="1.5" stroke-linecap="round"/>
          <path d="M0,140 C25,132 50,144 75,136 C100,128 125,140 150,132 C175,124 200,136 225,128 C250,120 275,132 300,124 C325,116 350,128 375,120 C400,112 425,124 450,116 C475,108 500,120 525,112 C550,104 575,116 600,108 C625,100 650,112 675,104 C700,96 725,108 750,100 C775,92 800,104 825,96 C850,88 875,100 900,92" fill="none" stroke="rgba(#{r},#{g},#{b},0.42)" stroke-width="1.5" stroke-linecap="round"/>
          <path d="M0,90 C25,82 50,94 75,86 C100,78 125,90 150,82 C175,74 200,86 225,78 C250,70 275,82 300,74 C325,66 350,78 375,70 C400,62 425,74 450,66 C475,58 500,70 525,62 C550,54 575,66 600,58 C625,50 650,62 675,54 C700,46 725,58 750,50 C775,42 800,54 825,46 C850,38 875,50 900,42" fill="none" stroke="rgba(#{r},#{g},#{b},0.35)" stroke-width="1.2" stroke-linecap="round"/>
          <path d="M0,42 C25,34 50,46 75,38 C100,30 125,42 150,34 C175,26 200,38 225,30 C250,22 275,34 300,26 C325,18 350,30 375,22 C400,14 425,26 450,18 C475,10 500,22 525,14 C550,6 575,18 600,10 C625,2 650,14 675,6 C700,-2 725,10 750,2 C775,-6 800,6 825,-2 C850,-10 875,2 900,-6" fill="none" stroke="rgba(#{r},#{g},#{b},0.3)" stroke-width="1" stroke-linecap="round"/>

          <!-- Vertical wisps — terrain ridges -->
          <path d="M120,-10 C125,50 115,100 122,150 C129,200 118,240 125,250" fill="none" stroke="rgba(#{r},#{g},#{b},0.12)" stroke-width="6" stroke-linecap="round"/>
          <path d="M380,-10 C385,45 375,95 382,145 C389,195 378,240 385,250" fill="none" stroke="rgba(#{r},#{g},#{b},0.1)" stroke-width="5" stroke-linecap="round"/>
          <path d="M620,-10 C625,55 615,105 622,155 C629,205 618,240 625,250" fill="none" stroke="rgba(#{r},#{g},#{b},0.14)" stroke-width="5.5" stroke-linecap="round"/>
          <path d="M820,-10 C823,40 815,85 822,130 C829,175 818,220 825,250" fill="none" stroke="rgba(#{r},#{g},#{b},0.09)" stroke-width="4" stroke-linecap="round"/>
        </svg>
      SVG

      svg + content_tag(:div, "", class: "absolute bottom-0 left-0 right-0 h-20 bg-gradient-to-t from-white to-transparent") +
        content_tag(:div, "", class: "absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-brand-300/40 to-transparent")
    end
  end

  def render_trend(trend_value)
    if trend_value > 0
      <<~HTML.html_safe
        <span class="text-sm font-medium text-green-600 flex items-center mb-1">
          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path></svg>
          #{trend_value}%
        </span>
      HTML
    elsif trend_value < 0
      <<~HTML.html_safe
        <span class="text-sm font-medium text-red-600 flex items-center mb-1">
          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 17h8m0 0v-8m0 8l-8-8-4 4-6-6"></path></svg>
          #{trend_value.abs}%
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="text-sm font-medium text-gray-500 flex items-center mb-1">0%</span>
      HTML
    end
  end

  private

  def hex_to_rgb(hex)
    hex = hex.delete("#")
    [hex[0..1].to_i(16), hex[2..3].to_i(16), hex[4..5].to_i(16)]
  end
end
