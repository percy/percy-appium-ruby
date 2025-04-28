# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
require 'appium_lib'
require_relative 'mocks/mock_methods'
require_relative '../percy/metadata/android_metadata'

# Test suite for the Percy::AndroidMetadata class
class TestAndroidMetadata < Minitest::Test
  def setup
    @mock_webdriver = Minitest::Mock.new
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @android_metadata = Percy::AndroidMetadata.new(@mock_webdriver)
  end

  def test_android_execute_script
    command = 'some dummy command'
    output = 'some output'
    @mock_webdriver.expect(:execute_script, output, [command])

    assert_equal(output, @android_metadata.execute_script(command))
    @mock_webdriver.verify
  end

  def test_viewport
    viewport = { 'left' => 0, 'top' => 84, 'width' => 1440, 'height' => 2708 }
    android_capabilities = get_android_capabilities
    @mock_webdriver.expect(:capabilities, android_capabilities.merge('viewportRect' => viewport))

    assert(viewport, @android_metadata.viewport)
    @mock_webdriver.verify
  end

  def test_device_screen_size_when_device_screen_size_is_nil
    # Mock capabilities to return a hash without 'deviceScreenSize'
    android_capabilities = get_android_capabilities
    android_capabilities.delete('deviceScreenSize')
    @mock_webdriver.expect(:capabilities, android_capabilities)

    # Mock driver.window_size to return a double with width and height
    mock_window_size = Minitest::Mock.new
    mock_window_size.expect(:width, 1080)
    mock_window_size.expect(:height, 1920)
    @mock_webdriver.expect(:window_size, mock_window_size)

    # Call the method and assert the result
    result = @android_metadata.device_screen_size
    assert_equal({ width: 1080, height: 1920 }, result)

    # Verify mocks
    mock_window_size.verify
    @mock_webdriver.verify
  end

  def test_get_system_bars
    system_bars = {
      'statusBar' => { 'height' => 83 },
      'navigationBar' => { 'height' => 44 }
    }
    android_capabilities = get_android_capabilities
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:capabilities, android_capabilities.merge('viewportRect' => nil))
    @mock_webdriver.expect(:get_system_bars, system_bars)

    assert(system_bars, @android_metadata.get_system_bars)
    @mock_webdriver.verify
  end

  def test_status_bar
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    mock_get_system_bars = { 'statusBar' => { 'height' => 1 } }
    @android_metadata.stub(:get_system_bars, mock_get_system_bars) do
      assert_equal(0, @android_metadata.status_bar_height)
    end
  end

  def test_navigation_bar
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    mock_get_system_bars = { 'navigationBar' => { 'height' => 1 } }
    @android_metadata.stub(:get_system_bars, mock_get_system_bars) do
      assert_equal(0, @android_metadata.navigation_bar_height)
    end
  end

  def test_scale_factor
    assert_equal(1, @android_metadata.scale_factor)
  end
end
