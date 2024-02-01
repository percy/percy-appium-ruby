# frozen_string_literal: true

require 'appium_lib'
require_relative '../exceptions/exceptions'
require_relative '../metadata/driver_metadata'
require_relative '../lib/cli_wrapper'

IGNORE_ELEMENT_KEY = 'ignore_region_appium_elements'
IGNORE_ELEMENT_ALT_KEY = 'ignoreRegionAppiumElements'
CONSIDER_ELEMENT_KEY = 'consider_region_appium_elements'
CONSIDER_ELEMENT_ALT_KEY = 'considerRegionAppiumElements'

module Percy
  class PercyOnAutomate
    def initialize(driver)
      unless driver.is_a?(Appium::Core::Base::Driver)
        raise DriverNotSupported, 'The provided driver instance is not supported.'
      end

      @driver = driver
      @percy_options = Percy::PercyOptions.new(@driver.capabilities)
    end

    def screenshot(name, **options)
      return nil unless @percy_options.enabled
      raise TypeError, 'Argument name should be a string' unless name.is_a?(String)
      raise KeyError, 'Please pass the last parameter as "options" key' unless options.key?(:options)

      metadata = Percy::DriverMetadata.new(@driver)
      options = options[:options] || {}

      begin
        options[IGNORE_ELEMENT_KEY] = options.delete(IGNORE_ELEMENT_ALT_KEY) if options.key?(IGNORE_ELEMENT_ALT_KEY)
        options[CONSIDER_ELEMENT_KEY] = options.delete(CONSIDER_ELEMENT_ALT_KEY) if options.key?(CONSIDER_ELEMENT_ALT_KEY)

        ignore_region_elements = options.fetch(IGNORE_ELEMENT_KEY, []).map(&:id)
        consider_region_elements = options.fetch(CONSIDER_ELEMENT_KEY, []).map(&:id)
        options.delete(IGNORE_ELEMENT_KEY)
        options.delete(CONSIDER_ELEMENT_KEY)

        additional_options = {
          'ignore_region_elements' => ignore_region_elements,
          'consider_region_elements' => consider_region_elements
        }

        response = Percy::CLIWrapper.new.post_poa_screenshots(
          name,
          metadata.session_id,
          metadata.command_executor_url,
          metadata.capabilities,
          metadata.session_capabilities,
          options.merge(additional_options)
        )
        response.body.to_json['data']
      rescue StandardError => e
        log("Could not take Screenshot '#{name}'")
        log(e.message, on_debug: true)
      end
      nil
    end
  end
end
