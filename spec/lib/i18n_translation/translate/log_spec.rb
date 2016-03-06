require 'rails_helper'
require 'fileutils'

describe 'Log' do
  describe 'write_to_file' do
    before(:each) do
      I18n.locale = :de
      I18n.backend.store_translations(:de, from_texts)
      keys = I18nTranslation::Translate::Keys.new
      @log = I18nTranslation::Translate::Log.new(:de, :en, I18nTranslation::Translate::Keys.flatten_key(from_texts).keys)
      allow(@log).to receive(:file_path).and_return(file_path)
      FileUtils.rm_f file_path
    end

    after(:each) do
      FileUtils.rm_f file_path
    end

    it 'writes new log file with from texts' do
      expect(File.exist?(file_path)).to be false
      @log.write_to_file
      expect(File.exist?(file_path)).to be true
      expect(I18nTranslation::Translate::TranslationFile.new(file_path).read).to eq I18nTranslation::Translate::TranslationFile.deep_stringify_keys(from_texts)
    end

    it 'merges from texts with current texts in log file and re-writes the log file' do
      @log.write_to_file
      I18n.backend.store_translations(:de, category: 'Kategori ny')
      @log.keys = ['category']
      @log.write_to_file
      expect(I18nTranslation::Translate::TranslationFile.new(file_path).read['category']).to eq 'Kategori ny'
    end

    def file_path
      File.join(File.dirname(__FILE__), 'files', 'from_de_to_en.yml')
    end

    def from_texts
      {
        article: {
          title: 'En artikel'
        },
        category: 'Kategori'
      }
    end
  end
end
