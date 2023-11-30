require_relative '../exceptions/exceptions'
require_relative 'android_metadata'
require_relative 'ios_metadata'

class MetadataResolver
  def self.resolve(driver)
    capabilities = driver.capabilities
    capabilities = capabilities.as_json unless capabilities.is_a?(Hash)
    platform_name = capabilities.fetch('platformName', '').downcase
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
