# frozen_string_literal: true

require_relative '../exceptions/exceptions'
require_relative 'android_metadata'
require_relative 'ios_metadata'

module Percy
  class MetadataResolver
    def self.resolve(driver)
      capabilities = driver.capabilities
      capabilities = capabilities.as_json unless capabilities.is_a?(Hash)
      key = capabilities.keys.find { |k| k.downcase.gsub('_', '') == 'platformname' }
      platform_name = capabilities[key]&.downcase
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
