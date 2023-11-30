# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
require_relative '../percy/providers/app_automate'
require_relative '../percy/metadata/android_metadata'
require_relative 'mocks/mock_methods'

# Test suite for the Percy::AppAutomate class
class TestAppAutomate < Minitest::Test
  COMPARISON_RESPONSE = { 'success' => true, 'link' => 'https://snapshots-url' }.freeze

  def setup
    @mock_webdriver = Minitest::Mock.new
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @metadata = Percy::AndroidMetadata.new(@mock_webdriver)
    @app_automate = Percy::AppAutomate.new(@mock_webdriver, @metadata)
  end

  def test_app_automate_get_debug_url
    @app_automate.set_debug_url('deviceName' => 'Google Pixel 4', 'osVersion' => '12.0', 'buildHash' => 'abc',
                                'sessionHash' => 'def')
    debug_url = @app_automate.get_debug_url
    assert_equal 'https://app-automate.browserstack.com/dashboard/v2/builds/abc/sessions/def', debug_url
  end

  def test_app_automate_supports_with_correct_url
    app_automate_session = Percy::AppAutomate.supports('https://hub-cloud.browserstack.com/wd/hub')
    assert_equal true, app_automate_session
  end

  def test_app_automate_supports_with_incorrect_url
    app_automate_session = Percy::AppAutomate.supports('https://hub-cloud.generic.com/wd/hub')
    assert_equal false, app_automate_session
  end

  def test_app_automate_supports_with_AA_DOMAIN
    ENV['AA_DOMAIN'] = 'bsstag'
    app_automate_session = Percy::AppAutomate.supports('bsstag.com')
    assert_equal true, app_automate_session
    ENV['AA_DOMAIN'] = nil
  end

  def test_app_automate_execute_percy_screenshot_begin
    @mock_webdriver.expect(:execute_script, '{}', [String])
    assert_empty @app_automate.execute_percy_screenshot_begin('Screebshot 1')
    @mock_webdriver.verify
  end

  def test_app_automate_execute_percy_screenshot_end
    @mock_webdriver.expect(:execute_script, '{}', [String])
    assert_equal '{}',
                 @app_automate.execute_percy_screenshot_end('Screenshot 1', COMPARISON_RESPONSE['link'], 'success')
    @mock_webdriver.verify
  end

  def test_app_automate_execute_percy_screenshot
    @mock_webdriver.expect(:execute_script, '{"result": "result"}', [String])
    @app_automate.execute_percy_screenshot(1080, 'singlepage', 5)
    @mock_webdriver.verify
  end

  def test_execute_percy_screenshot_end_throws_error
    @mock_webdriver.expect(:execute_script, proc { raise 'SomeException' }, [String])
    @app_automate.execute_percy_screenshot_end('Screenshot 1', 'snapshot-url', 'success')
    @mock_webdriver.verify
  end

  def test_execute_percy_screenshot_end
    @app_automate.stub(:execute_percy_screenshot_begin, 'deviceName' => 'abc', 'osVersion' => '123') do
      @app_automate.stub(:execute_percy_screenshot_end, nil) do
        @app_automate.stub(:screenshot, 'link' => 'https://link') do
          @app_automate.screenshot('name')
        end
      end
    end
  end

  def test_get_tiles
    # Mocking Percy::Metadata's session_id method
    metadata_mock = Minitest::Mock.new
    metadata_mock.expect(:session_id, 'session_id_123')

    # Mocking Percy::AndroidMetadata's methods
    android_metadata_mock = Minitest::Mock.new
    android_metadata_mock.expect(:device_screen_size, { 'width' => 1080, 'height' => 1920 })
    android_metadata_mock.expect(:navigation_bar_height, 150)
    android_metadata_mock.expect(:status_bar_height, 100)

    Percy::Metadata.class_eval do
      define_method(:session_id) do
        metadata_mock.session_id
      end
    end

    Percy::AndroidMetadata.class_eval do
      define_method(:device_screen_size) do
        android_metadata_mock.device_screen_size
      end

      define_method(:navigation_bar_height) do
        android_metadata_mock.navigation_bar_height
      end

      define_method(:status_bar_height) do
        android_metadata_mock.status_bar_height
      end
    end

    @app_automate.stub(:execute_percy_screenshot, {
                         'result' => '[{"sha":"sha-25568755","status_bar":null,"nav_bar":null,"header_height":120,"footer_height":80,"index":0}]'
                       }) do
      result = @app_automate._get_tiles(fullpage: true)[0]
      assert_equal('sha', result.sha)
      assert_equal(100, result.status_bar_height)
      assert_equal(150, result.nav_bar_height)
      assert_equal(120, result.header_height)
      assert_equal(80, result.footer_height)
    end
  end
end
