# coding: utf-8
percy = File.expand_path('../percy', __FILE__)
$LOAD_PATH.unshift(percy) unless $LOAD_PATH.include?(percy)
require 'version'

Gem::Specification.new do |spec|
  spec.name          = 'percy-appium-app'
  spec.version       = Percy::VERSION
  spec.authors       = ['BroswerStack']
  spec.email         = ['support@browserstack.com']
  spec.summary       = %q{Percy visual testing for Ruby Appium Mobile Apps}
  spec.description   = %q{}
  spec.homepage      = ''
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'


  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/percy/percy-appium-ruby/issues',
    'source_code_uri' => 'https://github.com/percy/percy-appium-ruby',
  }

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['percy']

  spec.add_runtime_dependency 'appium_lib', '>= 12', '< 14'
  spec.add_runtime_dependency 'dotenv', '~> 2.8'

  spec.add_development_dependency 'bundler', '~> 2.4'
  spec.add_development_dependency 'minitest', '~> 5.20'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'percy-style', '~> 0.7.0'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'webrick', '~> 1.3'

end
