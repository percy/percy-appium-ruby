require_relative '../exceptions/exceptions'
require_relative 'android_metadata'
require_relative 'ios_metadata'

class MetadataResolver
  def self.resolve(driver)
    platform_name = driver.capabilities.as_json['platformName'].downcase
    case platform_name
    when 'android'
      AndroidMetadata.new(driver)
    when 'ios'
      IOSMetadata.new(driver)
    else
      raise PlatformNotSupported
    end
  end
end
