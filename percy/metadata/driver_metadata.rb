# frozen_string_literal: true

require_relative '../lib/cache'

module Percy
  class DriverMetadata
    def initialize(driver)
      @driver = driver
    end

    def session_id
      @driver.session_id
    end

    def command_executor_url
      url = Percy::Cache.get_cache(session_id, Percy::Cache::COMMAND_EXECUTOR_URL)
      if url.nil?
        url = @driver.instance_variable_get(:@bridge).instance_variable_get(:@http).instance_variable_get(:@server_url).to_s
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
