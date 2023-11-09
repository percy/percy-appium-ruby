require 'appium_lib'
require_relative '../exceptions/exceptions'
require_relative 'percy_options'
require_relative '../providers/provider_resolver'
require_relative '../metadata/metadata_resolver'

class AppPercy
  def initialize(driver)
    raise DriverNotSupported unless driver.is_a?(Appium::Core::Base::Driver)

    @driver = driver
    @metadata = MetadataResolver.resolve(@driver)
    @provider = ProviderResolver.resolve(@driver)
    @percy_options = PercyOptions.new(@metadata.capabilities)
  end

  def screenshot(name, **kwargs)
    return nil unless @percy_options.enabled

    raise TypeError, 'Argument name should be a String' unless name.is_a?(String)

    device_name = kwargs[:device_name]
    raise TypeError, 'Argument device_name should be a String' if device_name && !device_name.is_a?(String)

    fullscreen = kwargs[:full_screen]
    raise TypeError, 'Argument fullscreen should be a Boolean' if fullscreen && !fullscreen.is_a?(TrueClass) && !fullscreen.is_a?(FalseClass)

    status_bar_height = kwargs[:status_bar_height]
    raise TypeError, 'Argument status_bar_height should be an Integer' if status_bar_height && !status_bar_height.is_a?(Integer)

    nav_bar_height = kwargs[:nav_bar_height]
    raise TypeError, 'Argument nav_bar_height should be an Integer' if nav_bar_height && !nav_bar_height.is_a?(Integer)

    orientation = kwargs[:orientation]
    raise TypeError, 'Argument orientation should be a String and portrait/landscape' if orientation && !orientation.is_a?(String)

    @provider.screenshot(name, **kwargs)
    nil
  end

  def percy_options
    @percy_options
  end
end
