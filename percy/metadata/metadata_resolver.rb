# frozen_string_literal: true

require_relative '../exceptions/exceptions'
require_relative 'metadata'
require_relative 'android_metadata'
require_relative 'ios_metadata'

module Percy
  class MetadataResolver
    def self.resolve(driver)
      # Resolve via normalized capability keys so platformName is found
      # regardless of casing/prefix (camelCase, snake_case as in appium_lib_core
      # 13+, or the appium: vendor prefix).
      platform_name = Percy::Metadata.normalized_capabilities(driver)['platformname']&.to_s&.downcase
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
