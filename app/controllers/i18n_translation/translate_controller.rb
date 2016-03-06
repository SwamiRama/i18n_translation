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
      @keys = I18nTranslation::Filter.new(initialize_keys(@files, @from_locale, @to_locale), params, @from_locale, @to_locale).all_keys
      @total_entries = @keys.size
      @translated_entries
      @page_title = page_title
      @paginated_keys = paginate_keys(@keys)
    end

    def translated
      @files = initialize_files
      @keys = I18nTranslation::Filter.new(initialize_keys(@files, @from_locale, @to_locale), params, @from_locale, @to_locale).translated_keys
      @total_entries = @keys.size
      @page_title = page_title
      @paginated_keys = paginate_keys(@keys)
    end

    def untranslated
      @files = initialize_files
      @keys = I18nTranslation::Filter.new(initialize_keys(@files, @from_locale, @to_locale), params, @from_locale, @to_locale).untranslated_keys
      @total_entries = @keys.size
      @page_title = page_title
      @paginated_keys = paginate_keys(@keys)
    end

    def changed
      @files = initialize_files
      @keys = I18nTranslation::Filter.new(initialize_keys(@files, @from_locale, @to_locale), params, @from_locale, @to_locale).changed_keys
      @total_entries = @keys.size
      @page_title = page_title
      @paginated_keys = paginate_keys(@keys)
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

    def paginate_keys(found_keys)
      params[:page] ||= 1
      found_keys[offset, per_page]
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
