# config/initializers/ahoy_email.rb
AhoyEmail.subscribers << AhoyEmail::DatabaseSubscriber
AhoyEmail.api = true
AhoyEmail.default_options[:message] = true
AhoyEmail.default_options[:click] = true

# Ensure tracking asset routes use the canonical production host URL
AhoyEmail.default_options[:url_options] = { host: "mboka.dnrstudios.co.ke" }
