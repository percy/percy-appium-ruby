# frozen_string_literal: true

require_relative 'metadata'
require_relative '../lib/cache'

module Percy
  class IOSMetadata < Percy::Metadata
    attr_reader :_window_size

    def initialize(driver)
      super(driver)
      @_viewport = {}
      @_window_size = {}
    end

    def device_screen_size
      vp = viewport
      height = vp.fetch('top', 0) + vp.fetch('height', 0)
      width = vp.fetch('width', 0)
      if  height.zero? && width.zero?
        scale_factor = value_from_devices_info('scale_factor', device_name)
        height = get_window_size['height'] * scale_factor
        width = get_window_size['width'] * scale_factor
      end
      { 'width' => width, 'height' => height }
    end

    def status_bar
      height = 0
      view_port = viewport
      if view_port.fetch('top', 0) != 0
        height = view_port['top']
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
      @_window_size = Percy::Cache.get_cache(session_id, Percy::Cache::WINDOW_SIZE)
      unless @_window_size
        @_window_size = driver.window_size
        Percy::Cache.set_cache(session_id, Percy::Cache::WINDOW_SIZE, @_window_size)
      end
      @_window_size
    end

    def viewport
      @_viewport = Percy::Cache.get_cache(session_id, Percy::Cache::VIEWPORT)
      if @_viewport.nil? || (@_viewport.is_a?(Hash) && @_viewport.empty?)
        begin
          @_viewport = execute_script('mobile: viewportRect')
          Percy::Cache.set_cache(session_id, Percy::Cache::VIEWPORT, @_viewport)
        rescue StandardError
          log('Could not use viewportRect; using static config', on_debug: true)
          # setting `viewport` as empty hash so that it's not nil anymore
          Percy::Cache.set_cache(session_id, Percy::Cache::VIEWPORT, {})
        end
      end
      @_viewport || { 'top' => 0, 'height' => 0, 'width' => 0 }
    end

    def device_name
      if @device_name.nil?
        caps = capabilities
        caps = caps.as_json unless caps.is_a?(Hash)
        @device_name = caps['deviceName']
      end
      @device_name
    end

    def scale_factor
      scale_factor = value_from_devices_info('scale_factor', device_name)
      return viewport['width'] / get_window_size['width'] if scale_factor.zero?

      scale_factor
    end
  end
end