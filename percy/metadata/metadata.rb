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

    # Normalizes a capability key so lookups are resilient to the differences
    # across appium_lib_core versions and protocols: camelCase ("platformName"),
    # snake_case ("platform_name", as returned by appium_lib_core 13+),
    # SCREAMING ("PLATFORM_NAME") and the W3C vendor prefix ("appium:platformName").
    # Note: all colons are stripped, not just the vendor-prefix one. This is safe
    # for every known Appium capability (e.g. "bstack:options" -> "bstackoptions").
    def self.normalize_capability_key(key)
      key.to_s.downcase.gsub(/[_:]/, '').sub(/\Aappium/, '')
    end

    # Builds a {normalized_key => value} view of a capabilities hash. First key
    # wins, so a camelCase key (e.g. "platformName") takes precedence over a
    # snake_case duplicate ("platform_name") when both are present, matching the
    # previous MetadataResolver semantics.
    def self.normalize_hash(hash)
      normalized = {}
      (hash || {}).each do |k, v|
        nk = normalize_capability_key(k)
        normalized[nk] = v unless normalized.key?(nk)
      end
      normalized
    end

    # Builds a {normalized_key => value} view of the driver's capabilities,
    # coercing the appium_lib_core Capabilities object into a plain Hash first.
    def self.normalized_capabilities(driver)
      caps = driver.capabilities
      caps = caps.as_json if caps.respond_to?(:as_json) && !caps.is_a?(Hash)
      caps = caps.to_h if caps.respond_to?(:to_h) && !caps.is_a?(Hash)
      normalize_hash(caps)
    end

    # Reads capabilities fresh on every call (no memoization) so callers always
    # observe the driver's current capabilities, matching the prior behaviour.
    def get_capability_value(name)
      self.class.normalized_capabilities(driver)[self.class.normalize_capability_key(name)]
    end

    def session_id
      driver.session_id
    end

    def os_name
      get_capability_value('platformName')
    end

    def os_version
      os_version = get_capability_value('os_version') || get_capability_value('platformVersion') || ''
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
      orientation = kwargs[:orientation] || get_capability_value('orientation') || 'PORTRAIT'
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
      if @device_info.empty?
        log("#{device_name.downcase} does not exist in config. Making driver call to get the device info.",
            on_debug: true)
      end
      @device_info
    end
  end
end
