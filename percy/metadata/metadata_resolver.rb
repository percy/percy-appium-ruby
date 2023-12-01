# frozen_string_literal: true

require_relative '../exceptions/exceptions'
require_relative 'android_metadata'
require_relative 'ios_metadata'

module Percy
  class MetadataResolver
    def self.resolve(driver)
      capabilities = driver.capabilities
      capabilities = capabilities.as_json unless capabilities.is_a?(Hash)
      platform_name = capabilities.fetch('platformName', '').downcase
      case platform_name
      when 'android'
        Percy::AndroidMetadata.new(driver)
      when 'ios'
        Percy::IOSMetadata.new(driver)
      else
        raise PlatformNotSupported
      end
    end
  end
end
