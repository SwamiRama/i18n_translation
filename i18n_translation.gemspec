$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "i18n_translation/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "i18n_translation"
  s.version     = I18nTranslation::VERSION
  s.authors     = ["Jimmi"]
  s.email       = ["jimmi@rl-hosting.de"]
  s.homepage    = "asdf"
  s.summary     = "asdf."
  s.description = "asdf."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.2.0"
end
