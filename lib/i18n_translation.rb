require 'i18n_translation/engine'

module I18nTranslation
  # For configuring Google Translate API key
  mattr_accessor :api_key
  # For configuring Bing Application id
  mattr_accessor :app_id
end

Dir[File.join(File.dirname(__FILE__), "translate", "*.rb")].each do |file|
  require file
end
