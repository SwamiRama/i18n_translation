require 'rails_helper'

describe I18nTranslation::TranslateController do
  routes { I18nTranslation::Engine.routes }

  describe 'index' do
    before(:each) do
      allow(controller).to receive(:per_page).and_return(1)
      allow(I18n.backend).to receive(:translations).and_return(i18n_translations)
      I18n.backend.instance_eval { @initialized = true }
      keys = double(:keys)
      allow(keys).to receive(:i18n_keys).and_return(['vendor.foobar'])
      expect(I18nTranslation::Translate::Keys).to receive(:new).and_return(keys)
      expect(I18nTranslation::Translate::Keys).to receive(:files).and_return(files)
      allow(I18n).to receive(:available_locales).and_return([:en, :de])
      allow(I18n).to receive(:default_locale).and_return(:de)
    end

    it 'shows sorted paginated keys from the translate from locale and extracted keys by default' do
      get :index
      expect(assigns(:from_locale)).to eq :de
      expect(assigns(:to_locale)).to eq :en
      expect(assigns(:files)).to eq files
      expect(assigns(:keys).sort).to eq ['articles.new.page_title', 'home.page_title', 'vendor.foobar']
      expect(assigns(:paginated_keys)).to eq ['articles.new.page_title']
    end

    it 'can be paginated with the page param' do
      get :index, page: 2
      expect(assigns(:files)).to eq files
      expect(assigns(:paginated_keys)).to eq ['home.page_title']
      expect(assigns(:paginated_keys)).to eq ['home.page_title']
    end

    it 'accepts a key_pattern param with key_type=starts_with' do
      get :index, key_pattern: 'articles', key_type: 'starts_with'
      expect(assigns(:files)).to eq files
      expect(assigns(:paginated_keys)).to eq ['articles.new.page_title']
      expect(assigns(:total_entries)).to eq 1
    end

    it 'accepts a key_pattern param with key_type=contains' do
      get :index, key_pattern: 'page_', key_type: 'contains'
      expect(assigns(:files)).to eq files
      expect(assigns(:total_entries)).to eq 2
      expect(assigns(:paginated_keys)).to eq ['articles.new.page_title']
    end

    it 'accepts a filter=untranslated param' do
      get :index, filter: 'untranslated'
      expect(assigns(:total_entries)).to eq 2
      expect(assigns(:paginated_keys)).to eq ['articles.new.page_title']
    end

    it 'accepts a filter=translated param' do
      get :index, filter: 'translated'
      expect(assigns(:total_entries)).to eq 1
      expect(assigns(:paginated_keys)).to eq ['vendor.foobar']
    end

    it 'accepts a filter=changed param' do
      log = double(:log)
      old_translations = { home: { page_title: 'Skapar ny artikel' } }
      # expect(log).to receive(:read).and_return(I18nTranslation::Translate::TranslationFile.deep_stringify_keys(old_translations))
      # expect(I18nTranslation::Translate::Log).to receive(:new).with(:sv, :en, {}).and_return(log)
      get :index, filter: 'changed'
      expect(assigns(:total_entries)).to eq(3)
      expect(assigns(:keys)).to eq(["articles.new.page_title", "home.page_title", "vendor.foobar"])
    end

    def i18n_translations
      HashWithIndifferentAccess.new(
        en: {
          vendor: {
            foobar: 'Foo Baar'
          }
        },
        de: {
          articles: {
            new: {
              page_title: 'Skapa ny artikel'
            }
          },
          home: {
            page_title: "Välkommen till I18n"
          },
          vendor: {
            foobar: 'Fobar'
          }
        })
    end

    def files
      HashWithIndifferentAccess.new(
        :'home.page_title' => ['app/views/home/index.rhtml'],
        :'general.back' => ['app/views/articles/new.rhtml', 'app/views/categories/new.rhtml'],
        :'articles.new.page_title' => ['app/views/articles/new.rhtml'])
    end
  end

  describe 'translate' do
    it 'should store translations to I18n backend and then write them to a YAML file' do
      session[:from_locale] = :de
      session[:to_locale] = :en
      translations = {
        articles: {
          new: {
            title: 'New Article'
          }
        },
        category: 'Category'
      }
      key_param = { 'articles.new.title' => 'New Article', 'category' => 'Category' }
      expect(I18n.backend).to receive(:store_translations).with(:en, translations)
      storage = double(:storage)
      expect(storage).to receive(:write_to_file)
      expect(I18nTranslation::Translate::Storage).to receive(:new).with(:en).and_return(storage)
      log = double(:log)
      expect(log).to receive(:write_to_file)
      expect(I18nTranslation::Translate::Log).to receive(:new).with(:de, :en, key_param.keys).and_return(log)
      post :translate, 'key' => key_param
      expect(response).to be_redirect
    end
  end
end
