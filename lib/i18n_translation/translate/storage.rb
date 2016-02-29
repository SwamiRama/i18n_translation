module I18nTranslation
  module Translate
    class Storage
      attr_accessor :locale

      def initialize(locale)
        self.locale = locale.to_sym
      end

      def write_to_file
        I18nTranslation::Translate::TranslationFile.new(file_path).write(keys)
      end

      def self.file_paths(locale)
        Dir.glob(File.join(root_dir, 'config', 'locales', '**', "#{locale}.yml"))
      end

      def self.root_dir
        Rails.root.to_s
      end

      private

      def keys
        { locale => I18n.backend.send(:translations)[locale] }
      end

      def file_path
        File.join(I18nTranslation::Translate::Storage.root_dir.to_s, 'config', 'locales', "#{locale}.yml")
      end
    end
  end
end
