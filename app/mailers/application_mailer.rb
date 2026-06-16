class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM_ADDRESS", "noreply@mboka.dnrstudios.co.ke")
  layout "mailer"
end
