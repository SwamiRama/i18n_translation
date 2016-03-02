require 'rails_helper'
require 'fileutils'

describe I18nTranslation::Translate::TranslationFile do
  describe "write" do
    before(:each) do
      @file = I18nTranslation::Translate::TranslationFile.new(file_path)
    end

    after(:each) do
      FileUtils.rm(file_path)
    end

    it "writes all I18n messages for a locale to YAML file" do
      @file.write(translations)
      @file.read.should == I18nTranslation::Translate::TranslationFile.deep_stringify_keys(translations)
    end

    def translations
      {
        :en => {
          :article => {
            :title => "One Article"
          },
          :category => "Category"
        }
      }
    end
  end

  describe "deep_stringify_keys" do
    it "should convert all keys in a hash to strings" do
      I18nTranslation::Translate::TranslationFile.deep_stringify_keys({
        :en => {
          :article => {
            :title => "One Article"
          },
          :category => "Category"
        }
      }).should == {
        "en" => {
          "article" => {
            "title" => "One Article"
          },
          "category" => "Category"
        }
      }
    end
  end

  def file_path
    File.join(File.dirname(__FILE__), "files", "en.yml")
  end
end
