require_relative 'metadata'
require_relative '../lib/cache'

class IOSMetadata < Metadata
  def initialize(driver)
    super(driver)
    @_viewport = {}
    @_window_size = {}
  end

  def device_screen_size
    height = viewport['top'] + viewport['height']
    width = viewport['width']
    unless height && width
      scale_factor = value_from_devices_info('scale_factor', device_name)
      height = get_window_size['height'] * scale_factor
      width = get_window_size['width'] * scale_factor
    end
    { 'width' => width, 'height' => height }
  end

  def status_bar
    height = 0
    if viewport['top']
      height = viewport['top']
    else
      scale_factor = value_from_devices_info('scale_factor', device_name)
      status_bar_height = value_from_devices_info('status_bar', device_name)
      height = status_bar_height.to_i * scale_factor.to_i
    end
    { 'height' => height }
  end

  def navigation_bar
    { 'height' => 0 }
  end

  def get_window_size
    @_window_size = Cache.get_cache(session_id, Cache::WINDOW_SIZE)
    unless @_window_size
      @_window_size = driver.get_window_size
      Cache.set_cache(session_id, Cache::WINDOW_SIZE, @_window_size)
    end
    @_window_size
  end

  def viewport
    @_viewport = Cache.get_cache(session_id, Cache::VIEWPORT)
    if @_viewport.nil?
      begin
        @_viewport = execute_script('mobile: viewportRect')
        Cache.set_cache(session_id, Cache::VIEWPORT, @_viewport)
      rescue StandardError
        log("Could not use viewportRect; using static config", on_debug: true)
        # setting `viewport` as empty hash so that it's not nil anymore
        Cache.set_cache(session_id, Cache::VIEWPORT, {})
      end
    end
    @_viewport || { 'top' => 0, 'height' => 0, 'width' => 0 }
  end

  def device_name
    if @device_name.nil?
      @device_name = capabilities['deviceName']
    end
    @device_name
  end

  def scale_factor
    scale_factor = value_from_devices_info('scale_factor', device_name)
    if scale_factor == 0
      return viewport['width'] / get_window_size['width']
    end
    scale_factor
  end
end

