# frozen_string_literal: true

source 'https://rubygems.org'

# Pin appium_lib to the 12.x line so all Ruby legs (2.6/2.7/3.0) resolve
# appium_lib_core ~> 5.0, which still exposes Appium::Core::Base::SearchContext.
# Unpinned, Ruby 3.0 resolved appium_lib 15 / appium_lib_core 9.x, which removed
# that constant and broke the specs. appium_console 3.0.0 requires appium_lib = 12.0.0.
gem 'appium_console', '~> 3.0'
gem 'appium_lib', '~> 12.0'
gem 'dotenv'
gem 'minitest'
gem 'rubocop', require: false
gem 'tempfile'
gem 'webmock', '~> 3.18', '>= 3.18.1'
gem 'webrick', '~> 1.3', '>= 1.3.1'
gem 'rake', '~> 13.0'
gem 'simplecov', require: false
