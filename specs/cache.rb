# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
require 'time'
require_relative '../percy/lib/cache'

# Test suite for the Percy::Cache class
class TestCache < Minitest::Test
  def setup
    @cache = Percy::Cache.new
    @session_id = 'session_id_123'
    @prop = 'window_size'
    @value = { 'top' => 'Top Value' }
    Percy::Cache.set_cache(@session_id, @prop, @value)
  end

  def test_set_cache
    assert_raises(Exception) { Percy::Cache.set_cache(123, 123, 123) }
    assert_raises(Exception) { Percy::Cache.set_cache(@session_id, 123, 123) }

    assert_includes @cache.cache, @session_id
    assert_equal @cache.cache[@session_id][@prop], @value
  end

  def test_get_cache_invalid_args
    assert_raises(Exception) { Percy::Cache.get_cache(123, 123) }
    assert_raises(Exception) { Percy::Cache.get_cache(@session_id, 123) }
  end

  def test_get_cache_success
    mock_cleanup_cache = Minitest::Mock.new
    mock_cleanup_cache.expect(:call, nil)

    Percy::Cache.stub(:cleanup_cache, -> { mock_cleanup_cache.call }) do
      window_size = Percy::Cache.get_cache(@session_id, @prop)
      assert_equal @value, window_size
      mock_cleanup_cache.verify
    end
  end

  def test_cleanup_cache
    previous_value = Percy::Cache::CACHE_TIMEOUT
    Percy::Cache.send(:remove_const, :CACHE_TIMEOUT)
    Percy::Cache.const_set(:CACHE_TIMEOUT, 1)

    cache_timeout = Percy::Cache::CACHE_TIMEOUT
    sleep(cache_timeout + 1)
    assert_includes @cache.cache, @session_id
    Percy::Cache.cleanup_cache
    refute_includes @cache.cache, @session_id

    Percy::Cache.send(:remove_const, :CACHE_TIMEOUT)
    Percy::Cache.const_set(:CACHE_TIMEOUT, previous_value)
  end
end
