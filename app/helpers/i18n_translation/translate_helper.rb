module I18nTranslation
  module TranslateHelper
    def simple_filter(labels, param_name = 'filter', selected_value = nil)
      selected_value ||= params[param_name]
      filter = []
      labels.each do |item|
        if item.is_a?(Array)
          type, label = item
        else
          type = label = item
        end
        if type.to_s == selected_value.to_s
          filter << "<div class='btn btn-success btn-block'>#{label}</div>"
        else
          link_params = params.merge(param_name.to_s => type)
          link_params['page'] = nil if param_name.to_s != 'page'
          filter << link_to(label, link_params, {class: 'btn btn-default btn-block'})
        end
      end
      filter.join('</br> ')
    end

    def n_lines(text, line_size)
      n_lines = 1
      if text.present?
        n_lines = text.split("\n").size
        if n_lines == 1 && text.length > line_size
          n_lines = text.length / line_size + 1
        end
      end
      n_lines
    end

    def translate_javascript_includes
      if File.exist?(File.join(Rails.root, 'public', 'javascripts', 'prototype.js'))
        javascript_include_tag('prototype.js')
      else
        javascript_include_tag('http://ajax.googleapis.com/ajax/libs/prototype/1.7.0.0/prototype.js')
      end
    end

    def translate_link(key, text, from, to)
      #TODO delte me
      return nil
      method = if Translate.app_id
                 'getBingTranslation'
               elsif Translate.api_key
                 'getGoogleTranslation'
               end
      return nil unless method
      link_to_function 'Auto Translate', "#{method}('#{key}', \"#{escape_javascript(text)}\", '#{from}', '#{to}')", style: 'padding: 0; margin: 0;'
    end
  end
end
