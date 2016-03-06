module I18nTranslation
  class Filter
    attr_reader :keys, :params

    def initialize(keys, params)
      @keys = keys
      @params = params
    end

    def all_keys
      set_filter('all', @keys)
      @keys
    end

    def translated_keys
      set_filter('translated', @keys)
      @keys
    end

    def untranslated_keys
      set_filter('untranslated', @keys)
      @keys
    end

    def changed_keys
      set_filter('changed', @keys)
      @keys
    end

    private

    def set_filter(filter, found_keys)
      filter_by_key_pattern(found_keys)
      filter_by_text_pattern(found_keys)
      filter_by_translated_text_pattern(found_keys)
      filter_by_translated_or_changed(filter, found_keys)
      sort_keys(found_keys)
    end

    def filter_by_translated_or_changed(filter = 'all', found_keys)
      return if filter == 'all'
      found_keys.reject! do |key|
        case filter
        when 'untranslated'
          lookup(@to_locale, key).present?
        when 'translated'
          lookup(@to_locale, key).blank?
        when 'changed'
          lookup(@from_locale, key).to_s == lookup(@to_locale, key).to_s
        when 'list_changed'
          fr = lookup(@from_locale, key).to_s.squish
          to = lookup(@to_locale, key).to_s.squish
          if fr.downcase != to.downcase
            p '--'
            p 'c:' + fr
            p 'g:' + to
          end
          fr.downcase == to.downcase
        else
          fail "Unknown filter '#{filter}'"
        end
      end
    end

    def filter_by_key_pattern(found_keys)
      return if params[:key_pattern].blank?
      found_keys.reject! do |key|
        case params[:key_type]
        when 'starts_with'
          !key.starts_with?(params[:key_pattern])
        when 'contains'
          key.index(params[:key_pattern]).nil?
        else
          fail "Unknown key_type '#{params[:key_type]}'"
        end
      end
    end

    def filter_by_text_pattern(found_keys)
      filter_by_pattern(:text_pattern, found_keys, :text_type)
    end

    def filter_by_translated_text_pattern(found_keys)
      filter_by_pattern(:translate_text_pattern, found_keys, :translated_text_type)
    end

    def filter_by_pattern(pattern, found_keys, type)
      return if params[pattern].blank?
      found_keys.reject! do |key|
        case params[type]
        when 'contains' then
          !lookup(@to_locale, key).present? || !lookup(@to_locale, key).to_s.downcase.index(params[pattern].downcase)
        when 'equals' then
          !lookup(@to_locale, key).present? || lookup(@to_locale, key).to_s.downcase != params[pattern].downcase
        else
          fail "Unknown translated_text_type '#{params[type]}'"
        end
      end
    end

    def lookup(locale, key)
      I18n.backend.send(:lookup, locale, key)
    end

    def sort_keys(found_keys)
      params[:sort_by] ||= 'key'
      case params[:sort_by]
      when 'key'
        found_keys.sort!
      when 'text'
        found_keys.sort! do |key1, key2|
          if lookup(@from_locale, key1).present? && lookup(@from_locale, key2).present?
            lookup(@from_locale, key1).to_s.downcase <=> lookup(@from_locale, key2).to_s.downcase
          elsif lookup(@from_locale, key1).present?
            -1
          else
            1
          end
        end
      else
        fail "Unknown sort_by '#{params[:sort_by]}'"
      end
    end
  end
end
