# frozen_string_literal: true

require 'json'
require 'pathname'
require_relative '../common/common'

DEVICE_INFO_FILE_PATH = File.join(File.dirname(__FILE__), '..', 'configs', 'devices.json')
DEVICE_INFO = JSON.parse(File.read(DEVICE_INFO_FILE_PATH))

module Percy
  class Metadata
    attr_reader :driver, :device_info
    attr_accessor :device_name, :os_version, :device_info

    def initialize(driver)
      @driver = driver
      @device_name = nil
      @os_version = nil
      @device_info = {}
    end

    def capabilities
      caps = driver.capabilities
      caps = caps.as_json unless caps.is_a?(Hash)
      caps
    end

    def session_id
      driver.session_id
    end

    def os_name
      capabilities['platformName']
    end

    def os_version
      caps = capabilities
      caps = caps.as_json unless caps.is_a?(Hash)

      os_version = caps['os_version'] || caps['platformVersion'] || ''
      os_version = @os_version || os_version
      begin
        os_version.to_f.to_i.to_s
      rescue StandardError
        ''
      end
    end

    def remote_url
      driver.instance_variable_get(:@bridge).instance_variable_get(:@http).instance_variable_get(:@server_url).to_s
    end

    def get_orientation(**kwargs)
      orientation = kwargs[:orientation] || capabilities['orientation'] || 'PORTRAIT'
      orientation = orientation.downcase
      orientation = orientation == 'auto' ? _orientation : orientation
      orientation.upcase
    end

    def _orientation
      driver.orientation.downcase
    end

    def device_screen_size
      raise NotImplementedError
    end

    def _device_name
      raise NotImplementedError
    end

    def status_bar
      raise NotImplementedError
    end

    def status_bar_height
      status_bar['height']
    end

    def navigation_bar
      raise NotImplementedError
    end

    def navigation_bar_height
      navigation_bar['height']
    end

    def viewport
      raise NotImplementedError
    end

    def execute_script(command)
      driver.execute_script(command)
    end

    def value_from_devices_info(key, device_name, os_version = nil)
      device_info = get_device_info(device_name)
      device_info = device_info[os_version] || {} if os_version
      device_info[key].to_i || 0
    end

    def get_device_info(device_name)
      return @device_info unless @device_info.empty?

      @device_info = DEVICE_INFO[device_name.downcase] || {}
      log("#{device_name.downcase} does not exist in config.") if @device_info.empty?
      @device_info
    end
  end
end
