# frozen_string_literal: true

source 'https://rubygems.org'

# appium_lib defaults to the 12.x line so the Ruby 2.6/2.7/3.0 legs resolve
# appium_lib_core ~> 5.0. CI also runs a leg on the current major via
# APPIUM_LIB_VERSION, since appium_lib_core 11+ changed where the driver keeps its
# hub URL. appium_console 3.0.0 requires appium_lib = 12.0.0, so it only joins the
# 12.x resolution.
appium_lib_version = ENV.fetch('APPIUM_LIB_VERSION', '~> 12.0')
gem 'appium_console', '~> 3.0' if appium_lib_version.include?('12.')
gem 'appium_lib', appium_lib_version
gem 'dotenv'
# minitest 6 moved Minitest::Mock into the separate minitest-mock gem.
gem 'minitest', '~> 5.0'
gem 'rubocop', require: false
gem 'tempfile'
gem 'webmock', '~> 3.18', '>= 3.18.1'
gem 'webrick', '~> 1.3', '>= 1.3.1'
gem 'rake', '~> 13.0'
gem 'simplecov', require: false
