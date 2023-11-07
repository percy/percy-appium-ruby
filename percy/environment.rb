require 'appium_lib'
require 'appium_lib/version'
from version import SDK_VERSION

class Environment
  @percy_build_id = nil
  @percy_build_url = nil
  @session_type = nil

  class << self
    attr_accessor :percy_build_id, :percy_build_url, :session_type

    def get_client_info(flag = false)
      sdk_version = SDK_VERSION
      flag ? "percy-appium-app-ruby/#{sdk_version}" : "percy-appium-app/#{sdk_version}"
    end

    def get_env_info
      appium_version = Appium::VERSION # This assumes the 'appium_lib' gem provides a VERSION constant.
      ["appium/#{appium_version}", "ruby/#{RUBY_VERSION}"]
    end
  end
end
