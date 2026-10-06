# frozen_string_literal: true

require_relative '../lib/cache'

module Percy
  class DriverMetadata
    def initialize(driver)
      @driver = driver
    end

    # Returns the hub URL the driver talks to. appium_lib_core <= 10 keeps it in
    # the HTTP client's @server_url; 11+ (selenium-webdriver ClientConfig) moved it
    # to client_config.server_url and leaves @server_url unset, which made every
    # BrowserStack session look like a generic remote (no AppAutomate provider,
    # no device name, empty executor URL for Percy on Automate).
    def self.server_url(driver)
      http = driver.instance_variable_get(:@bridge).instance_variable_get(:@http)
      url = http.instance_variable_get(:@server_url).to_s
      return url unless url.empty?

      client_config = http.respond_to?(:client_config) ? http.client_config : nil
      client_config ||= http.instance_variable_get(:@client_config)
      return '' unless client_config.respond_to?(:server_url)

      client_config.server_url.to_s.chomp('/')
    end

    def session_id
      @driver.session_id
    end

    def command_executor_url
      url = Percy::Cache.get_cache(session_id, Percy::Cache::COMMAND_EXECUTOR_URL)
      if url.nil?
        url = self.class.server_url(@driver)
        Percy::Cache.set_cache(session_id, Percy::Cache::COMMAND_EXECUTOR_URL, url)
      end
      url
    end

    def capabilities
      caps = Percy::Cache.get_cache(session_id, Percy::Cache::SESSION_CAPABILITIES)
      if caps.nil?
        caps = @driver.capabilities.dup # In Ruby, use dup to create a shallow copy of the hash
        Percy::Cache.set_cache(session_id, Percy::Cache::SESSION_CAPABILITIES, caps)
      end
      caps
    end

    def session_capabilities
      session_caps = Percy::Cache.get_cache(session_id, Percy::Cache::SESSION_CAPABILITIES)
      if session_caps.nil?
        session_caps = @driver.desired_capabilities.dup # Assuming there is a desired_capabilities method
        Percy::Cache.set_cache(session_id, Percy::Cache::SESSION_CAPABILITIES, session_caps)
      end
      session_caps
    end
  end
end
