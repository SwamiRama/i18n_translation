$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'i18n_translation/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'i18n_translation'
  s.version     = I18nTranslation::VERSION
  s.authors     = ['Jimmi']
  s.email       = ['jimmi@rl-hosting.de']
  s.homepage    = 'https://github.com/SwamiRama/i18n_translation'
  s.summary     = 'Gem to manage translation files.'
  s.description = 'Initially, this was a fork of the Gem translate-rails3 (Thanks a lot!). This plugin provides a web interface for translating Rails I18n texts (requires Rails 3.0 or higher) from one locale to another.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 4'
  s.test_files = Dir['spec/**/*']

  s.add_development_dependency 'rspec-rails', '~> 0'
end
