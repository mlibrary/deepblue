if Object.const_defined?('NewGoogleRecaptcha')
  NewGoogleRecaptcha.setup do |config|
    config.site_key   = Settings.new_google_recaptcha.site_key
    config.secret_key = Settings.new_google_recaptcha.secret_key
    config.minimum_score = Settings.new_google_recaptcha.minimum_score
  end
end
