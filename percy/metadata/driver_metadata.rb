require_relative '../lib/cache'

class DriverMetadata
  def initialize(driver)
    @driver = driver
  end

  def session_id
    @driver.session_id
  end

  def command_executor_url
    url = Cache.get_cache(session_id, Cache::COMMAND_EXECUTOR_URL)
    if url.nil?
      url = @driver.instance_variable_get(:@bridge).instance_variable_get(:@http).instance_variable_get(:@server_url).to_s
      Cache.set_cache(session_id, Cache::COMMAND_EXECUTOR_URL, url)
    end
    url
  end

  def capabilities
    caps = Cache.get_cache(session_id, Cache::SESSION_CAPABILITIES)
    if caps.nil?
      caps = @driver.capabilities.dup # In Ruby, use dup to create a shallow copy of the hash
      Cache.set_cache(session_id, Cache::SESSION_CAPABILITIES, caps)
    end
    caps
  end

  def session_capabilities
    session_caps = Cache.get_cache(session_id, Cache::SESSION_CAPABILITIES)
    if session_caps.nil?
      session_caps = @driver.desired_capabilities.dup # Assuming there is a desired_capabilities method
      Cache.set_cache(session_id, Cache::SESSION_CAPABILITIES, session_caps)
    end
    session_caps
  end
end
