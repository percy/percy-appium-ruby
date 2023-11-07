require 'appium_lib'
require_relative '../exceptions/exceptions'

IGNORE_ELEMENT_KEY = 'ignore_region_appium_elements'.freeze
IGNORE_ELEMENT_ALT_KEY = 'ignoreRegionAppiumElements'.freeze
CONSIDER_ELEMENT_KEY = 'consider_region_appium_elements'.freeze
CONSIDER_ELEMENT_ALT_KEY = 'considerRegionAppiumElements'.freeze


class PercyOnAutomate
    def initialize(driver)
      unless driver.is_a?(Appium::Core::Base::Driver)
        raise DriverNotSupported, "The provided driver instance is not supported."
      end
      @driver = driver
      @percy_options = PercyOptions.new(@driver.capabilities)
    end

    def screenshot(name, **options)
        return nil unless @percy_options.enabled?
        raise TypeError, 'Argument name should be a string' unless name.is_a?(String)
        raise KeyError, 'Please pass the last parameter as "options" key' unless options.has_key?(:options)
    
        metadata = DriverMetadata.new(@driver)
        options = options[:options] || {}
    
        begin
          if options.key?(IGNORE_ELEMENT_ALT_KEY)
            options[IGNORE_ELEMENT_KEY] = options.delete(IGNORE_ELEMENT_ALT_KEY)
          end
          if options.key?(CONSIDER_ELEMENT_ALT_KEY)
            options[CONSIDER_ELEMENT_KEY] = options.delete(CONSIDER_ELEMENT_ALT_KEY)
          end
    
          ignore_region_elements = options.fetch(IGNORE_ELEMENT_KEY, []).map { |element| element.id }
          consider_region_elements = options.fetch(CONSIDER_ELEMENT_KEY, []).map { |element| element.id }
          options.delete(IGNORE_ELEMENT_KEY)
          options.delete(CONSIDER_ELEMENT_KEY)
    
          additional_options = {
            "ignore_region_elements" => ignore_region_elements,
            "consider_region_elements" => consider_region_elements
          }
    
          CLIWrapper.new.post_poa_screenshots(
            name,
            metadata.session_id,
            metadata.command_executor_url,
            metadata.capabilities,
            metadata.session_capabilities,
            options.merge(additional_options)
          )
        rescue StandardError => e
          log("Could not take Screenshot '#{name}'")
          log(e.message, on_debug: true)
        end
        nil
    end
end