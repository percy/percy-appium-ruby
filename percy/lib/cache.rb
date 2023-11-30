# frozen_string_literal: true
module Percy
  class Cache
    attr_reader :cache

    @@cache = {}
    CACHE_TIMEOUT = 5 * 60 # 5 * 60 seconds
    TIMEOUT_KEY = 'last_access_time'

    SESSION_DETAILS = 'session_details'
    SYSTEM_BARS = 'system_bars'
    WINDOW_SIZE = 'window_size'
    VIEWPORT = 'viewport'
    SESSION_CAPABILITIES = 'session_capabilities'
    CAPABILITIES = 'capabilities'
    COMMAND_EXECUTOR_URL = 'command_executor_url'

    def cache
      @@cache
    end

    def self.set_cache(session_id, property, value)
      raise TypeError, 'Argument session_id should be a String' unless session_id.is_a?(String)
      raise TypeError, 'Argument property should be a String' unless property.is_a?(String)

      session = @@cache.fetch(session_id, {})
      session[TIMEOUT_KEY] = Time.now.to_i
      session[property] = value
      @@cache[session_id] = session
    end

    def self.get_cache(session_id, property)
      cleanup_cache

      raise TypeError, 'Argument session_id should be a String' unless session_id.is_a?(String)
      raise TypeError, 'Argument property should be a String' unless property.is_a?(String)

      session = @@cache.fetch(session_id, {})
      session.fetch(property, nil)
    end

    def self.cleanup_cache
      now = Time.now.to_i
      session_ids = []

      @@cache.each do |session_id, session|
        timestamp = session[TIMEOUT_KEY]
        session_ids << session_id if now - timestamp >= CACHE_TIMEOUT
      end

      session_ids.each { |session_id| @@cache.delete(session_id) }
    end
  end
end