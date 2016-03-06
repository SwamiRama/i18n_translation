require_dependency 'i18n_translation/application_controller'

module I18nTranslation
  class TranslateController < ApplicationController
    # It seems users with active_record_store may get a "no :secret given" error if we don't disable csrf protection,
    skip_before_filter :verify_authenticity_token

    before_filter :init_translations
    before_filter :set_locale

    helper_method :lookup
    helper_method :from_locales
    helper_method :to_locales
    helper_method :per_page

    # GET /translate
    def index
      @files = initialize_files
      @keys = initialize_keys(@files, @from_locale, @to_locale)
      set_filter('all', @keys)
      @total_entries = @keys.size
      @translated_entries
      @page_title = page_title
    end

    def translated
      @files = initialize_files
      @keys = initialize_keys(@files, @from_locale, @to_locale)
      set_filter('translated', @keys)
      @total_entries = @keys.size
      @page_title = page_title
    end

    def untranslated
      @files = initialize_files
      @keys = initialize_keys(@files, @from_locale, @to_locale)
      set_filter('untranslated', @keys)
      @total_entries = @keys.size
      @page_title = page_title
    end

    def changed
      @files = initialize_files
      @keys = initialize_keys(@files, @from_locale, @to_locale)
      set_filter('changed', @keys)
      @total_entries = @keys.size
      @page_title = page_title
    end

    # POST /translate
    def translate
      processed_parameters = process_array_parameters(params[:key])
      I18n.backend.store_translations(
        @to_locale,
        I18nTranslation::Translate::Keys.unflatten_key(processed_parameters)
      )
      I18nTranslation::Translate::Storage.new(@to_locale).write_to_file
      I18nTranslation::Translate::Log.new(
        @from_locale,
        @to_locale,
        params[:key].keys
      ).write_to_file
      force_init_translations # Force reload from YAML file
      flash[:notice] = 'Translations stored'
      redirect_to url_for(slice_params.merge(action: :index))
    end

    # GET /translate/reload
    def reload
      I18nTranslation::Translate::Keys.files = nil
      redirect_to action: 'index'
    end

    private

    def slice_params
      params.slice(
        :filter,
        :sort_by,
        :key_type,
        :key_pattern,
        :text_type,
        :text_pattern,
        :translated_text_type,
        :translated_text_pattern
      )
    end

    def set_filter(filter, found_keys)
      filter_by_key_pattern(found_keys)
      filter_by_text_pattern(found_keys)
      filter_by_translated_text_pattern(found_keys)
      filter_by_translated_or_changed(filter, found_keys, @from_locale, @to_locale)
      sort_keys(found_keys)
      paginate_keys(found_keys)
    end

    def initialize_files
      I18nTranslation::Translate::Keys.files
    end

    def initialize_keys(files, from, to)
      found_keys = (files.keys.map(&:to_s) + I18nTranslation::Translate::Keys.new.i18n_keys(from)).uniq
      found_keys.reject do |key|
        from_text = lookup(from, key)
        # When translating from one language to another, make sure there is a text to translate from.
        # The only supported formats are String and Array. We don't support other formats
        (from != to && !from_text.present?) || (from_text.present? && !from_text.is_a?(String) && !from_text.is_a?(Array))
      end
    end

    def page_title
      'Translate'
    end

    def lookup(locale, key)
      I18n.backend.send(:lookup, locale, key)
    end

    def from_locales
      locales(:from_locales)
    end

    def to_locales
      locales(:to_locales)
    end

    def locales(local)
      loc = Rails.application.config.send(local) if Rails.application.config.respond_to?(local)
      return I18n.available_locales if loc.blank?
      fail StandardError, 'to_locales expected to be an array' if local.class != Array
      loc
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

    def paginate_keys(found_keys)
      params[:page] ||= 1
      @paginated_keys = found_keys[offset, per_page]
    end

    def offset
      (params[:page].to_i - 1) * per_page
    end

    def per_page
      50
    end

    def init_translations
      I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    end

    def force_init_translations
      I18n.backend.send(:init_translations)
    end

    def default_locale
      I18n.default_locale
    end

    def default_to_locale
      :en
    end

    def set_locale
      session[:from_locale] ||= default_locale
      session[:to_locale] ||= default_to_locale
      session[:from_locale] = params[:from_locale] if params[:from_locale].present?
      session[:to_locale] = params[:to_locale] if params[:to_locale].present?
      @from_locale = session[:from_locale].to_sym
      @to_locale = session[:to_locale].to_sym
    end

    def process_array_parameters(parameter)
      reconstructed_hash = {}

      parameter.each do |key, value|
        if value.is_a?(String)
          reconstructed_hash[key] = value
        elsif value.is_a?(Hash)
          reconstructed_hash[key] = I18nTranslation::Translate::Keys.arraylize(value)
        end
      end
      reconstructed_hash
    end
  end
end
