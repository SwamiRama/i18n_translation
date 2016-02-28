Rails.application.routes.draw do

  mount I18nTranslation::Engine => "/i18n_translation"
end
