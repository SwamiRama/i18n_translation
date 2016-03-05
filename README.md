# Translate

Initially, this was a fork of the Gem translate-rails3 (Thanks a lot!)

This plugin provides a web interface for translating Rails I18n texts (requires Rails 3.0 or higher) from one locale to another. The plugin has been tested only with the simple I18n backend that ships with Rails. I18n texts are read from and written to YAML files under config/locales.

To translate to a new locale you need to add a YAML file for that locale that contains the locale as the top key and at least one translation.

Please note that there are certain I18n keys that map to Array objects rather than strings and those are currently not dealt with by the translation UI. This means that Rails built in keys such as date.day_names need to be translated manually directly in the YAML file.

The translation UI finds all I18n keys by extracting them from I18n lookups in your application source code. In addition it adds all :en and default locale keys from the I18n backend.

Strings in the UI can have an "Auto Translate" link (if configured, see below), which will send the original text to translation API and will input the returned translation into the form field for further clean up and review prior to saving.
