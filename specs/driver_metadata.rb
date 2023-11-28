require 'minitest/autorun'
require 'minitest/mock'
require 'appium_lib'

require_relative '../percy/metadata/driver_metadata.rb' 

class TestDriverMetadata < Minitest::Test
  def setup
    @mock_webdriver = Minitest::Mock.new
    # @mock_webdriver.expect(:class, Appium::Core::Base::Driver) # Mocking __class__ attribute
    # @mock_webdriver.expect(:orientation, 'PORTRAIT')
    # @mock_webdriver.expect(:execute_script, nil) { |command| command == 'return window.navigator.userAgent;' }
    # @mock_webdriver.expect(:session_id, 'session_id_123')
    # @mock_webdriver.expect(:session_id, 'session_id_123')
    # @mock_webdriver.expect(:session_id, 'session_id_123')
    # @mock_webdriver.expect(:command_executor, OpenStruct.new(_url: 'https://example-hub:4444/wd/hub'))
    # @mock_webdriver.expect(:capabilities, { 'platform' => 'chrome_android', 'browserVersion' => '115.0.1' })

    # @mock_webdriver.expect(:desired_capabilities, {
    #   'platform' => 'chrome_android',
    #   'browserVersion' => '115.0.1',
    #   'session_name' => 'abc'
    # })

    @metadata = DriverMetadata.new(@mock_webdriver)
  end

  def test_session_id
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)

    assert(session_id, @metadata.session_id)
    @mock_webdriver.verify
  end

  def test_command_executor_url
    url = 'https://example-hub:4444/wd/hub'
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:command_executor, OpenStruct.new(_url: url))
    
    assert(url, @metadata.command_executor_url)
    @mock_webdriver.verify
  end

  def test_capabilities
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    capabilities = { 'platform' => 'chrome_android', 'browserVersion' => '115.0.1' }
    @mock_webdriver.expect(:capabilities, capabilities)

    assert(capabilities, @metadata.capabilities)
    @mock_webdriver.verify
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
    @mock_webdriver.verify
  end
end
