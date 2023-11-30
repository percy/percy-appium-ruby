# frozen_string_literal: true

require 'appium_lib'
require_relative '../exceptions/exceptions'
require_relative 'percy_options'
require_relative '../providers/provider_resolver'
require_relative '../metadata/metadata_resolver'

module Percy
  class AppPercy
    attr_accessor :metadata, :provider

    def initialize(driver)
      raise DriverNotSupported unless driver.is_a?(Appium::Core::Base::Driver)

      @driver = driver
      @metadata = Percy::MetadataResolver.resolve(@driver)
      @provider = Percy::ProviderResolver.resolve(@driver)
      @percy_options = Percy::PercyOptions.new(@metadata.capabilities)
    end

    def screenshot(name, **kwargs)
      return nil unless @percy_options.enabled

      raise TypeError, 'Argument name should be a String' unless name.is_a?(String)

      device_name = kwargs[:device_name]
      raise TypeError, 'Argument device_name should be a String' if device_name && !device_name.is_a?(String)

      fullscreen = kwargs[:full_screen]
      if fullscreen && !fullscreen.is_a?(TrueClass) && !fullscreen.is_a?(FalseClass)
        raise TypeError,
              'Argument fullscreen should be a Boolean'
      end

      status_bar_height = kwargs[:status_bar_height]
      if status_bar_height && !status_bar_height.is_a?(Integer)
        raise TypeError,
              'Argument status_bar_height should be an Integer'
      end

      nav_bar_height = kwargs[:nav_bar_height]
      raise TypeError, 'Argument nav_bar_height should be an Integer' if nav_bar_height && !nav_bar_height.is_a?(Integer)

      orientation = kwargs[:orientation]
      if orientation && !orientation.is_a?(String)
        raise TypeError,
              'Argument orientation should be a String and portrait/landscape'
      end

      @provider.screenshot(name, **kwargs)
      nil
    end

    attr_reader :percy_options
  end
end
