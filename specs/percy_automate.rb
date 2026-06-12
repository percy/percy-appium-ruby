# frozen_string_literal: true

require 'minitest/autorun'
require 'json'
require 'webmock/minitest'
require 'appium_lib'

require_relative '../percy/lib/percy_automate'
require_relative '../percy/lib/percy_options'
require_relative '../percy/lib/cli_wrapper'
require_relative 'mocks/mock_methods'

def mock_poa_screenshot(fail: false)
  stub_request(:post, 'http://localhost:5338/percy/automateScreenshot')
    .to_return(body: "{\"success\": #{fail ? 'false, "error": "test"' : 'true'}}", status: (fail ? 500 : 200))
end

# Test suite for the Percy::PercyOnAutomate class
class TestPercyOnAutomate < Minitest::Test
  def setup
    @mock_driver = Minitest::Mock.new
    @bridge = Minitest::Mock.new
    @http = Minitest::Mock.new
    @server_url = Minitest::Mock.new
    WebMock.enable!
  end

  def teardown
    WebMock.disable!
  end

  # Targets percy_automate.rb line 17: an unsupported driver raises DriverNotSupported.
  def test_initialize_raises_for_unsupported_driver
    assert_raises(DriverNotSupported) do
      Percy::PercyOnAutomate.new(Object.new)
    end
  end

  # Targets percy_automate.rb lines 56-58: when the screenshot post fails, the error
  # is rescued and logged rather than propagated.
  def test_screenshot_rescues_and_logs_on_failure
    mock_poa_screenshot(fail: true)

    @mock_driver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    @mock_driver.expect(:capabilities, { 'percy:options' => { 'enabled' => true } })

    5.times do
      @mock_driver.expect(:session_id, 'Dummy_session_id')
    end
    @mock_driver.expect(:instance_variable_get, @bridge, [:@bridge])
    @http.expect(:instance_variable_get, @server_url, [:@server_url])
    @bridge.expect(:instance_variable_get, @http, [:@http])
    @server_url.expect(:to_s, 'https://hub-cloud.browserstack.com/wd/hub')
    @mock_driver.expect(:capabilities, { 'key' => 'value' })
    @mock_driver.expect(:desired_capabilities, { 'key' => 'value' })

    percy = Percy::PercyOnAutomate.new(@mock_driver)

    result = nil
    assert_output(/Could not take Screenshot 'Snapshot 1'/) do
      result = percy.screenshot('Snapshot 1', options: {})
    end
    assert_nil result
  end
end
