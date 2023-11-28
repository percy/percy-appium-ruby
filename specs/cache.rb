require 'minitest/autorun'
require 'minitest/mock'
require 'time'
require_relative '../percy/lib/cache'

class TestCache < Minitest::Test
  def setup
    @cache = Cache.new
    @session_id = 'session_id_123'
    @prop = 'window_size'
    @value = { 'top' => 'Top Value' }
    Cache.set_cache(@session_id, @prop, @value)
  end

  def test_set_cache
    assert_raises(Exception) { Cache.set_cache(123, 123, 123) }
    assert_raises(Exception) { Cache.set_cache(@session_id, 123, 123) }

    assert_includes @cache.cache, @session_id
    assert_equal @cache.cache[@session_id][@prop], @value
  end

  def test_get_cache_invalid_args
    assert_raises(Exception) { Cache.get_cache(123, 123) }
    assert_raises(Exception) { Cache.get_cache(@session_id, 123) }
  end

  def test_get_cache_success
    mock_cleanup_cache = Minitest::Mock.new
    mock_cleanup_cache.expect(:call, nil)

    Cache.stub(:cleanup_cache, -> { mock_cleanup_cache.call }) do
      window_size = Cache.get_cache(@session_id, @prop)
      assert_equal @value, window_size
      mock_cleanup_cache.verify
    end
  end

  def test_cleanup_cache
    cache_timeout = Cache::CACHE_TIMEOUT
    sleep(cache_timeout + 1)
    assert_includes @cache.cache, @session_id
    Cache.cleanup_cache
    refute_includes @cache.cache, @session_id
  end
end
