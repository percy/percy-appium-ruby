require_relative '../lib/cache'

class DriverMetadata
  def initialize(driver)
    @driver = driver
  end

  def session_id
    @driver.session_id
  end

  def command_executor_url
    url = Cache.get_cache(session_id, Cache.command_executor_url)
    if url.nil?
      url = @driver.command_executor.url # Assume that the Ruby equivalent has a url attribute
      Cache.set_cache(session_id, Cache.command_executor_url, url)
    end
    url
  end

  def capabilities
    caps = Cache.get_cache(session_id, Cache.capabilities)
    if caps.nil?
      caps = @driver.capabilities.dup # In Ruby, use dup to create a shallow copy of the hash
      Cache.set_cache(session_id, Cache.capabilities, caps)
    end
    caps
  end

  def session_capabilities
    session_caps = Cache.get_cache(session_id, Cache.session_capabilities)
    if session_caps.nil?
      session_caps = @driver.desired_capabilities.dup # Assuming there is a desired_capabilities method
      Cache.set_cache(session_id, Cache.session_capabilities, session_caps)
    end
    session_caps
  end
end
