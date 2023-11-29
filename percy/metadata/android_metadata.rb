require 'json'
require_relative 'metadata'
require_relative '../lib/cache'

class AndroidMetadata < Metadata
  def initialize(driver)
    super(driver)
    @_bars = nil
    @_viewport_rect = capabilities.to_json['viewportRect']
  end

  def device_screen_size
    caps = capabilities
    unless caps.is_a?(Hash)
      caps = caps.as_json
    end
    width, height = caps['deviceScreenSize'].split('x')
    { 'width' => width.to_i, 'height' => height.to_i }
  end

  def get_system_bars
    @_bars = Cache.get_cache(session_id, Cache::SYSTEM_BARS)
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
      Cache.set_cache(session_id, Cache::SYSTEM_BARS, @_bars)
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
    capabilities.to_json["viewportRect"]
  end

  def scale_factor
    1
  end

  def _device_name
    if @device_name.nil?
      desired_caps = capabilities.to_json['desired'] || {}
      device_name = desired_caps['deviceName']
      device = desired_caps['device']
      device_name ||= device
      device_model = capabilities.to_json['deviceModel']
      @device_name = device_name || device_model
    end
    @device_name
  end
end

