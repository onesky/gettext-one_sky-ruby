# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gettext-one_sky/version"

Gem::Specification.new do |s|
  s.name        = "gettext-one_sky"
  s.version     = GetText::Onesky::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Eddie Lau"]
  s.email       = ["tatonlto@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/gettext-one_sky"
  s.summary     = %q{gettext extensions using OneSky -- the community-powered translation service.}
  s.description = %q{This is a backport of i18n-one_sky-ruby to support gettext. i18n is not included in Rails before Rails 2.2. This gem handles the downloading and uploading translation files (.po) to Onesky server by calling Onesky API.}

  s.rubyforge_project = "gettext-one_sky"

  s.add_dependency "gettext", "~> 2.0.0"
  s.add_dependency "one_sky", "~> 0.0.2"
  s.add_dependency "thor", "~> 0.14.4"

  s.add_development_dependency "rspec", "~> 2.2.0"
  s.add_development_dependency "bundler", "~> 1.0.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
