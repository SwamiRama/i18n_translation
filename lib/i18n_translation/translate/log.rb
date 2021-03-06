module I18nTranslation
  module Translate
    class Log
      attr_accessor :from_locale, :to_locale, :keys

      def initialize(from_locale, to_locale, keys)
        self.from_locale = from_locale
        self.to_locale = to_locale
        self.keys = keys
      end

      def write_to_file
        current_texts = File.exist?(file_path) ? file.read : {}
        current_texts.merge!(from_texts)
        file.write(current_texts)
      end

      def read
        file.read
      end

      private

      def file
        @file ||= I18nTranslation::Translate::TranslationFile.new(file_path)
      end

      def from_texts
        I18nTranslation::Translate::TranslationFile.deep_stringify_keys(I18nTranslation::Translate::Keys.unflatten_key(keys.inject({}) do |hash, key|
          hash[key] = I18n.backend.send(:lookup, from_locale, key)
          hash
        end))
      end

      def file_path
        File.join(Rails.root, 'config', 'locales', 'log', "from_#{from_locale}_to_#{to_locale}.yml")
      end
    end
  end
end
