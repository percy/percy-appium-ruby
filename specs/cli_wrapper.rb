# frozen_string_literal: true

require 'minitest/autorun'
require 'webmock/minitest'
require 'json'
require_relative '../percy/lib/cli_wrapper'
require_relative '../percy/lib/tile'

def mock_screenshot(fail: false)
  stub_request(:post, 'http://localhost:5338/percy/comparison')
    .to_return(body: '{"link": "snapshot-url-link", "success": true}', status: (fail ? 500 : 200))
end

def mock_poa_screenshot(fail: false)
  stub_request(:post, 'http://localhost:5338/percy/automateScreenshot')
    .to_return(body: "{\"success\": #{fail ? 'false, "error": "test"' : 'true'}}", status: (fail ? 500 : 200))
end

# Test suite for the Percy::CLIWrapper class
class TestCLIWrapper < Minitest::Test
  def setup
    @cli_wrapper = Percy::CLIWrapper.new
    @ignored_elements_data = {
      'ignore_elements_data' => {
        'selector' => 'xpath: some_xpath',
        'coOrdinates' => { 'top' => 123, 'bottom' => 234, 'left' => 234, 'right' => 455 }
      }
    }
    @considered_elements_data = {
      'consider_elements_data' => {
        'selector' => 'xpath: some_xpath',
        'coOrdinates' => { 'top' => 50, 'bottom' => 100, 'left' => 0, 'right' => 100 }
      }
    }
    WebMock.enable!
  end

  def teardown
    WebMock.disable!
  end

  def test_post_screenshot_throws_error
    mock_screenshot(fail: true)

    assert_raises(CLIException) do
      @cli_wrapper.post_screenshots('some-name', {}, [], 'some-debug-url')
    end
  end

  def test_post_failed_event
    mock_poa_screenshot(fail: true)
    @snapshot_name = 'test_snapshot'
    @session_id = 'test_session_id'
    @command_executor_url = 'http://example.com'
    @capabilities = { 'browser' => 'chrome' }
    @desired_capabilities = { 'platform' => 'Windows' }
    @options = { 'option_key' => 'option_value' }

    expected_request_body = {
      'sessionId' => @session_id,
      'commandExecutorUrl' => @command_executor_url,
      'capabilities' => @capabilities,
      'sessionCapabilities' => @desired_capabilities,
      'snapshotName' => @snapshot_name,
      'options' => @options,
      'client_info' => 'your_mocked_client_info',
      'environment_info' => 'your_mocked_environment_info'
    }

    assert_raises(CLIException, 'TestError') do
      @cli_wrapper.post_poa_screenshots(
        @snapshot_name,
        @session_id,
        @command_executor_url,
        @capabilities,
        @desired_capabilities,
        @options
      )
    end
  end

  def test_post_screenshot_with_ignore_region_null
    mock_screenshot

    assert_equal(
      @cli_wrapper.post_screenshots('some-name', {}, [Percy::Tile.new(10, 10, 20, 20, filepath: 'some-file-path')],
                                    'some-debug-url'),
      { 'link' => 'snapshot-url-link', 'success' => true }
    )
  end

  def test_post_screenshot_with_ignore_region_present
    mock_screenshot

    assert_equal(
      @cli_wrapper.post_screenshots('some-name', {}, [Percy::Tile.new(10, 10, 20, 20, filepath: 'some-file-path')],
                                    'some-debug-url', @ignored_elements_data),
      { 'link' => 'snapshot-url-link', 'success' => true }
    )
  end

  def test_request_body
    tile = Percy::Tile.new(10, 10, 20, 20, filepath: 'some-file-path')
    tag = { 'name' => 'Tag' }
    name = 'some-name'
    debug_url = 'debug-url'
    response = @cli_wrapper.request_body(name, tag, [tile], debug_url, @ignored_elements_data,
                                         @considered_elements_data)
    assert_equal response['name'], name
    assert_equal response['external_debug_url'], debug_url
    assert_equal response['tag'], tag
    assert_equal response['tiles'], [tile.to_h]
    assert_equal response['ignored_elements_data'], @ignored_elements_data
    assert_equal response['considered_elements_data'], @considered_elements_data
  end

  def test_request_body_when_optional_values_are_null
    tile = Percy::Tile.new(10, 10, 20, 20, filepath: 'some-file-path')
    tag = { 'name' => 'Tag' }
    name = 'some-name'
    debug_url = nil
    ignored_elements_data = nil
    considered_elements_data = nil
    response = @cli_wrapper.send(:request_body, name, tag, [tile], debug_url, ignored_elements_data,
                                 considered_elements_data)
    assert_equal response['name'], name
    assert_equal response['external_debug_url'], debug_url
    assert_equal response['tag'], tag
    assert_equal response['tiles'], [tile.to_h]
    assert_nil response['ignored_elements_data']
    assert_nil response['considered_elements_data']
  end
end
