# frozen_string_literal: true

require 'json'
require_relative 'metadata'
require_relative '../lib/cache'

module Percy
  class AndroidMetadata < Percy::Metadata
    def initialize(driver)
      super(driver)
      @_bars = nil
      # Intentionally left as the original lookup: this path already degrades to
      # driver.get_system_bars consistently across all appium_lib_core versions
      # (the rect read yields a non-Hash, so the rect arithmetic in
      # get_system_bars rescues to nil and falls back), so it is out of scope for
      # the snake_case capability fix.
      @_viewport_rect = capabilities.to_json['viewportRect']
    end

    def device_screen_size
      # Use string keys to match the IosMetadata implementation and every
      # consumer (generic_provider, app_automate, _get_tag), all of which read
      # device_screen_size['width'] / ['height'].
      device_screen_size_cap = get_capability_value('deviceScreenSize')
      if device_screen_size_cap.nil?
        size = driver.window_size
        { 'width' => size.width.to_i, 'height' => size.height.to_i }
      else
        width, height = device_screen_size_cap.split('x')
        { 'width' => width.to_i, 'height' => height.to_i }
      end
    end

    def get_system_bars
      @_bars = Percy::Cache.get_cache(session_id, Percy::Cache::SYSTEM_BARS)
      if @_viewport_rect
        begin
          @_bars = {
            'statusBar' => { 'height' => @_viewport_rect['top'] },
            'navigationBar' => {
              'height' => device_screen_size['height'] - @_viewport_rect['height'] - @_viewport_rect['top']
            }
          }
        rescue StandardError
          @_bars = nil
        end
      end
      if @_bars.nil?
        @_bars = driver.get_system_bars
        Percy::Cache.set_cache(session_id, Percy::Cache::SYSTEM_BARS, @_bars)
      end
      @_bars
    end

    def status_bar
      status_bar = get_system_bars['statusBar']
      if status_bar['height'] == 1
        response = value_from_devices_info('status_bar', _device_name.upcase, os_version)
        return { 'height' => response }
      end
      status_bar
    end

    def navigation_bar
      navigation_bar = get_system_bars['navigationBar']
      if navigation_bar['height'] == 1
        response = { 'height' => value_from_devices_info('nav_bar', _device_name.upcase, os_version) }
        return response
      end
      navigation_bar
    end

    def viewport
      capabilities.to_json['viewportRect']
    end

    def scale_factor
      1
    end

    def _device_name
      if @device_name.nil?
        # Normalize the nested desired-caps hash too, so its keys are matched
        # regardless of casing (camelCase or appium_lib_core 13+ snake_case).
        desired_caps = Percy::Metadata.normalize_hash(get_capability_value('desired'))
        device_name = desired_caps['devicename']
        device = desired_caps['device']
        device_name ||= device
        device_model = get_capability_value('deviceModel')
        @device_name = device_name || device_model
      end
      @device_name
    end
  end
end
