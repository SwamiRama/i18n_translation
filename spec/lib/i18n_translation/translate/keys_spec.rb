require 'rails_helper'
require 'fileutils'

describe 'Keys' do
  before(:each) do
allow(    I18n).to receive_message_chain(:default_locale).and_return(:en)
    @keys = I18nTranslation::Translate::Keys.new
allow(    I18nTranslation::Translate::Storage).to receive_message_chain(:root_dir).and_return(i18n_files_dir)
  end

  describe "to_a" do
    it "extracts keys from I18n lookups in .rb, .html.erb, and .rhtml files" do
      @keys.to_a.map(&:to_s).sort.should == ['article.key1', 'article.key2', 'article.key3', 'article.key4', 'article.key5',
        'category_erb.key1', 'category_html_erb.key1', 'category_rhtml.key1', 'js.alert']
    end
  end

  describe "to_hash" do
    it "return a hash with I18n keys and file lists" do
      @keys.to_hash[:'article.key3'].should == ["vendor/plugins/translate/spec/files/translate/app/models/article.rb"]
    end
  end

  describe "i18n_keys" do
    before(:each) do
      I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    end

    it "should return all keys in the I18n backend translations hash" do
      I18n.backend.should_receive(:translations).and_return(translations)
      @keys.i18n_keys(:en).should == ['articles.new.page_title', 'categories.flash.created', 'empty', 'home.about']
    end

  describe "untranslated_keys" do
    before(:each) do
allow(      I18n.backend).to receive_message_chain(:translations).and_return(translations)
    end

    it "should return a hash with keys with missing translations in each locale" do
      @keys.untranslated_keys.should == {
        :sv => ['articles.new.page_title', 'categories.flash.created', 'empty']
      }
    end
  end

  describe "missing_keys" do
    before(:each) do
      @file_path = File.join(i18n_files_dir, "config", "locales", "en.yml")
      I18nTranslation::Translate::TranslationFile.new(@file_path).write({
        :en => {
          :home => {
            :page_title => false,
            :intro => {
              :one => "intro one",
              :other => "intro other"
            }
          }
        }
      })
    end

    after(:each) do
      FileUtils.rm(@file_path)
    end

    it "should return a hash with keys that are not in the locale file" do
allow(      @keys).to receive_message_chain(:files).and_return({
        :'home.page_title' => "app/views/home/index.rhtml",
        :'home.intro' => 'app/views/home/index.rhtml',
        :'home.signup' => "app/views/home/_signup.rhtml",
        :'about.index.page_title' => "app/views/about/index.rhtml"
      })
      @keys.missing_keys.should == {
        :'home.signup' => "app/views/home/_signup.rhtml",
        :'about.index.page_title' => "app/views/about/index.rhtml"
      }
    end
  end

  describe "contains_key?" do
    it "works" do
      hash = {
        :foo => {
          :bar => {
            :baz => false
          }
        }
      }
      I18nTranslation::Translate::Keys.contains_key?(hash, "").should be false
      I18nTranslation::Translate::Keys.contains_key?(hash, "foo").should be true
      I18nTranslation::Translate::Keys.contains_key?(hash, "foo.bar").should be true
      I18nTranslation::Translate::Keys.contains_key?(hash, "foo.bar.baz").should be true
      I18nTranslation::Translate::Keys.contains_key?(hash, :"foo.bar.baz").should be true
      I18nTranslation::Translate::Keys.contains_key?(hash, "foo.bar.baz.bla").should be false
    end
  end

  describe "translated_locales" do
    before(:each) do
allow(      I18n).to receive_message_chain(:default_locale).and_return(:en)
allow(      I18n).to receive_message_chain(:available_locales).and_return([:sv, :no, :en, :root])
    end

    it "returns all avaiable except :root and the default" do
      I18nTranslation::Translate::Keys.translated_locales.should == [:sv, :no]
    end
  end

  describe "to_deep_hash" do
    it "convert shallow hash with dot separated keys to deep hash" do
      I18nTranslation::Translate::Keys.to_deep_hash(shallow_hash).should == deep_hash
    end
  end

  describe "to_shallow_hash" do
    it "converts a deep hash to a shallow one" do
      I18nTranslation::Translate::Keys.to_shallow_hash(deep_hash).should == shallow_hash
    end
  end

  ##########################################################################
  #
  # Helper Methods
  #
  ##########################################################################

    def translations
      {
        :en => {
          :home => {
            :about => "This site is about making money"
          },
          :articles => {
           :new => {
             :page_title => "New Article"
            }
          },
          :categories => {
            :flash => {
             :created => "Category created"
            }
          },
          :empty => nil
        },
        :sv => {
          :home => {
            :about => false
          }
        }
      }
    end
  end

  def shallow_hash
    {
      'pressrelease.label.one' => "Pressmeddelande",
      'pressrelease.label.other' => "Pressmeddelanden",
      'article' => "Artikel",
      'category' => ''
    }
  end

  def deep_hash
    {
      :pressrelease => {
        :label => {
          :one => "Pressmeddelande",
          :other => "Pressmeddelanden"
        }
      },
      :article => "Artikel",
      :category => ''
    }
  end

  def i18n_files_dir
    File.join(ENV['PWD'], "spec", "files", "translate")
  end
end
