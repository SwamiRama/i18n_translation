module I18nTranslation
  class Filter
    attr_reader :params

    def initialize(keys, params, from, to)
      @keys = keys
      @params = params
      @from_locale = from
      @to_locale = to
    end

    def all_keys
      set_filter('all', @keys, @from_locale, @to_locale)
      @keys
    end

    def translated_keys
      set_filter('translated', @keys, @from_locale, @to_locale)
      @keys
    end

    def untranslated_keys
      set_filter('untranslated', @keys, @from_locale, @to_locale)
      @keys
    end

    def changed_keys
      set_filter('changed', @keys, @from_locale, @to_locale)
      @keys
    end

    private

    def set_filter(filter, found_keys, from, to)
      filter_by_key_pattern(found_keys)
      filter_by_text_pattern(found_keys, to)
      filter_by_translated_text_pattern(found_keys, to)
      filter_by_translated_or_changed(filter, found_keys, from, to)
      sort_keys(found_keys, from)
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

    def filter_by_text_pattern(found_keys, to)
      filter_by_pattern(:text_pattern, found_keys, :text_type, to)
    end

    def filter_by_translated_text_pattern(found_keys, to)
      filter_by_pattern(:translate_text_pattern, found_keys, :translated_text_type, to)
    end

    def filter_by_pattern(pattern, found_keys, type, to)
      return if params[pattern].blank?
      found_keys.reject! do |key|
        case params[type]
        when 'contains' then
          !lookup(to, key).present? || !lookup(to, key).to_s.downcase.index(params[pattern].downcase)
        when 'equals' then
          !lookup(to, key).present? || lookup(to, key).to_s.downcase != params[pattern].downcase
        else
          fail "Unknown translated_text_type '#{params[type]}'"
        end
      end
    end

    def filter_by_translated_or_changed(filter = 'all', found_keys, from, to)
      return if filter == 'all'
      found_keys.reject! do |key|
        case filter
        when 'untranslated'
          lookup(to, key).present?
        when 'translated'
          lookup(to, key).blank?
        when 'changed'
          lookup(from, key).to_s == lookup(to, key).to_s
        when 'list_changed'
          fr = lookup(from, key).to_s.squish
          to = lookup(to, key).to_s.squish
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

    def lookup(locale, key)
      I18n.backend.send(:lookup, locale, key)
    end

    def sort_keys(found_keys, from)
      params[:sort_by] ||= 'key'
      case params[:sort_by]
      when 'key'
        found_keys.sort!
      when 'text'
        found_keys.sort! do |key1, key2|
          if lookup(from, key1).present? && lookup(from, key2).present?
            lookup(from, key1).to_s.downcase <=> lookup(from, key2).to_s.downcase
          elsif lookup(from, key1).present?
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
