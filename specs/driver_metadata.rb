require 'minitest/autorun'
require 'minitest/mock'
require 'appium_lib'

require_relative '../percy/metadata/driver_metadata'

class TestDriverMetadata < Minitest::Test
  def setup
    @mock_webdriver = Minitest::Mock.new
    @http = Minitest::Mock.new
    @bridge = Minitest::Mock.new
    @server_url = Minitest::Mock.new

    @metadata = DriverMetadata.new(@mock_webdriver)
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
end
