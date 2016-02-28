module I18nTranslation
  class Engine < ::Rails::Engine
    isolate_namespace I18nTranslation
    # For configuring Google Translate API key
    mattr_accessor :api_key
    # For configuring Bing Application id
    mattr_accessor :app_id
  end
end
