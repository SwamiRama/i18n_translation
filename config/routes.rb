I18nTranslation::Engine.routes.draw do
  get 'translate/index', as: :translate_list
  get 'translate/translated', as: :translated
  get 'translate/untranslated', as: :untranslated
  get 'translate/changed', as: :changed
  post 'translate/translate', as: :translate
  get 'translate/reload' => 'translate#reload', :as => :translate_reload

  # get 'translate' => 'translate#index', :as => :translate_list
  # post 'translate' => 'translate#translate', :as => :translate
  # get 'translate/reload' => 'translate#reload', :as => :translate_reload
end
