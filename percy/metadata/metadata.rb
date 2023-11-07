require 'json'
require 'pathname'

DEVICE_INFO_FILE_PATH = File.join(File.dirname(__FILE__), '..', 'configs', 'devices.json')
DEVICE_INFO = JSON.parse(File.read(DEVICE_INFO_FILE_PATH))

class Metadata
  attr_reader :driver, :device_info

  def initialize(driver)
    @driver = driver
    @device_name = nil
    @os_version = nil
    @device_info = {}
  end

  def capabilities
    driver.capabilities
  end

  def session_id
    driver.session_id
  end

  def os_name
    capabilities['platformName']
  end

  def os_version
    os_version = capabilities['os_version'] || capabilities['platformVersion'] || ''
    os_version = @os_version || os_version
    begin
      os_version.to_f.to_i.to_s
    rescue
      ''
    end
  end

  def remote_url
    driver.command_executor.url
  end

  def get_orientation(**kwargs)
    orientation = kwargs[:orientation] || capabilities['orientation'] || 'PORTRAIT'
    orientation = orientation.downcase
    orientation = orientation == 'auto' ? self.orientation : orientation
    orientation.upcase
  end

  def orientation
    driver.orientation.downcase
  end

  def device_screen_size
    raise NotImplementedError
  end

  def device_name
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
    if os_version
      device_info = device_info[os_version] || {}
    end
    device_info[key].to_i || 0
  end

  def get_device_info(device_name)
    return @device_info unless @device_info.empty?
    @device_info = DEVICE_INFO[device_name.downcase] || {}
    if @device_info.empty?
      log("#{device_name.downcase} does not exist in config.")
    end
    @device_info
  end
end

