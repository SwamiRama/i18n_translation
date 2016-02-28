I18nTranslation::Engine.routes.draw do
  get 'translate/index'

  get 'translate/translate'

  get 'translate' => 'translate#index', :as => :translate_list
  post 'translate' => 'translate#translate', :as => :translate
  get 'translate/reload' => 'translate#reload', :as => :translate_reload
end
