require 'rails_helper'

describe I18nTranslation::Translate::Storage do
  describe "write_to_file" do
    before(:each) do
      @storage = I18nTranslation::Translate::Storage.new(:en)
    end

    it "writes all I18n messages for a locale to YAML file" do
      I18n.backend.should_receive(:translations).and_return(translations)
allow(      @storage).to receive_message_chain(:file_path).and_return(file_path)
      file = double(:file)
      file.should_receive(:write).with(translations)
      I18nTranslation::Translate::TranslationFile.should_receive(:new).with(file_path).and_return(file)
      @storage.write_to_file
    end

    def file_path
      File.join(File.dirname(__FILE__), "files", "en.yml")
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
end
