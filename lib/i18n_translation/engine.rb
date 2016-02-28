module I18nTranslation
  class Engine < ::Rails::Engine
    isolate_namespace I18nTranslation
    require 'translate'
  end
end
