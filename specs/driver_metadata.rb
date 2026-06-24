# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
require 'appium_lib'

require_relative '../percy/metadata/driver_metadata'
require_relative '../percy/lib/cache'

# Test suite for the Percy::DriverMetadata class
class TestDriverMetadata < Minitest::Test
  def setup
    @mock_webdriver = Minitest::Mock.new
    @http = Minitest::Mock.new
    @bridge = Minitest::Mock.new
    @server_url = Minitest::Mock.new

    @metadata = Percy::DriverMetadata.new(@mock_webdriver)
  end

  def test_session_id
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)

    assert(session_id, @metadata.session_id)
  end

  def test_command_executor_url
    url = 'https://example-hub:4444/wd/hub'
    session_id = 'session_id_123'
    2.times do
      @mock_webdriver.expect(:session_id, session_id)
    end
    @mock_webdriver.expect(:instance_variable_get, @bridge, [:@bridge])
    @http.expect(:instance_variable_get, @server_url, [:@server_url])
    @bridge.expect(:instance_variable_get, @http, [:@http])
    @server_url.expect(:to_s, url)

    assert(url, @metadata.command_executor_url)
  end

  def test_capabilities
    session_id = 'session_id_123'
    2.times do
      @mock_webdriver.expect(:session_id, session_id)
    end
    capabilities = { 'platform' => 'chrome_android', 'browserVersion' => '115.0.1' }
    @mock_webdriver.expect(:capabilities, capabilities)

    assert(capabilities, @metadata.capabilities)
  end

  def test_session_capabilities
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:desired_capabilities, {
                             'platform' => 'chrome_android',
                             'browserVersion' => '115.0.1',
                             'session_name' => 'abc'
                           })
    session_caps = {
      'platform' => 'chrome_android',
      'browserVersion' => '115.0.1',
      'session_name' => 'abc'
    }

    assert(session_caps, @metadata.session_capabilities)
  end

  def test_session_capabilities_caches_desired_capabilities_on_cache_miss
    # Force a clean cache and use a unique session id so the cache lookup misses
    # and the desired_capabilities branch (set_cache) is exercised.
    Percy::Cache.force_cleanup_cache
    session_id = 'session_id_session_caps_miss'
    desired_caps = {
      'platform' => 'chrome_android',
      'browserVersion' => '115.0.1',
      'session_name' => 'abc'
    }
    # session_id is read by session_capabilities, get_cache and set_cache.
    3.times { @mock_webdriver.expect(:session_id, session_id) }
    @mock_webdriver.expect(:desired_capabilities, desired_caps)

    fetched = @metadata.session_capabilities
    assert_equal(desired_caps, fetched)
    # Now the value is cached: read straight back without another driver call.
    @mock_webdriver.expect(:session_id, session_id)
    assert_equal(desired_caps, @metadata.session_capabilities)
  end
end
