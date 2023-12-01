# frozen_string_literal: true

require 'minitest/autorun'
# require 'webmock/minitest'
require_relative '../percy/lib/app_percy'
require_relative '../percy/metadata/android_metadata'
require_relative '../percy/metadata/ios_metadata'
require_relative '../percy/providers/app_automate'
require_relative '../percy/providers/generic_provider'
require_relative '../percy/lib/cli_wrapper'
require_relative 'mocks/mock_methods'

# Test suite for the Percy::AppPercy class
class TestAppPercy < Minitest::Test
  COMPARISON_RESPONSE = { 'link' => 'https://snapshot_url', 'success' => true }.freeze

  def setup
    @mock_android_webdriver = Minitest::Mock.new
    @mock_ios_webdriver = Minitest::Mock.new
    @bridge = Minitest::Mock.new
    @http = Minitest::Mock.new
    @server_url = Minitest::Mock.new
  end

  def test_android_on_app_automate
    3.times do
      @mock_android_webdriver.expect(:instance_variable_get, @bridge, [:@bridge])
      @http.expect(:instance_variable_get, @server_url, [:@server_url])
      @bridge.expect(:instance_variable_get, @http, [:@http])
      @server_url.expect(:to_s, 'url-of-browserstack-cloud')
    end
    @mock_android_webdriver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    5.times do
      @mock_android_webdriver.expect(:capabilities, get_android_capabilities)
    end

    ENV['PERCY_DISABLE_REMOTE_UPLOADS'] = 'true'

    app_percy = Percy::AppPercy.new(@mock_android_webdriver)

    assert_instance_of(Percy::AndroidMetadata, app_percy.metadata)
    assert_instance_of(Percy::AppAutomate, app_percy.provider)
  end

  def test_android_on_non_app_automate
    3.times do
      @mock_android_webdriver.expect(:instance_variable_get, @bridge, [:@bridge])
      @http.expect(:instance_variable_get, @server_url, [:@server_url])
      @bridge.expect(:instance_variable_get, @http, [:@http])
      @server_url.expect(:to_s, 'some-remote-url')
    end
    2.times do
      @mock_android_webdriver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    end
    5.times do
      @mock_android_webdriver.expect(:capabilities, get_android_capabilities)
    end
    app_percy = Percy::AppPercy.new(@mock_android_webdriver)
    assert_instance_of(Percy::AndroidMetadata, app_percy.metadata)
    assert_instance_of(Percy::GenericProvider, app_percy.provider)
  end

  def test_ios_on_app_automate
    mock_driver_remote_url(@mock_ios_webdriver, 'url-of-browserstack-cloud')
    @mock_ios_webdriver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    5.times do
      @mock_ios_webdriver.expect(:capabilities, get_ios_capabilities)
    end
    app_percy = Percy::AppPercy.new(@mock_ios_webdriver)
    assert_instance_of(Percy::IOSMetadata, app_percy.metadata)
    assert_instance_of(Percy::AppAutomate, app_percy.provider)
  end

  def test_ios_on_non_app_automate
    2.times do
      @mock_ios_webdriver.expect(:instance_variable_get, @bridge, [:@bridge])
      @http.expect(:instance_variable_get, @server_url, [:@server_url])
      @bridge.expect(:instance_variable_get, @http, [:@http])
      @server_url.expect(:to_s, 'some-remote-url')
    end
    @mock_ios_webdriver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    3.times do
      @mock_ios_webdriver.expect(:capabilities, get_ios_capabilities)
    end
    app_percy = Percy::AppPercy.new(@mock_ios_webdriver)
    assert_instance_of(Percy::IOSMetadata, app_percy.metadata)
    assert_instance_of(Percy::GenericProvider, app_percy.provider)
  end

  def test_screenshot_with_percy_options_disabled
    disable_percy_options(@mock_android_webdriver, num = 5)
    make_mock_driver_appium(@mock_android_webdriver)
    mock_driver_remote_url(@mock_android_webdriver, 'some-other-url', num = 2)
    app_percy = Percy::AppPercy.new(@mock_android_webdriver)
    assert_nil app_percy.screenshot('screenshot 1')
  end

  def test_screenshot_with_percyoptions_disabled
    disable_percy_options(@mock_android_webdriver, num = 5)
    make_mock_driver_appium(@mock_android_webdriver)
    mock_driver_remote_url(@mock_android_webdriver, 'some-other-url', num = 2)
    app_percy = Percy::AppPercy.new(@mock_android_webdriver)
    assert_nil app_percy.screenshot('screenshot 1')
  end

  def test_percy_options_ignore_errors
    @mock_android_webdriver.expect(:capabilities, {
                                     'platformName': 'android',
                                     'percy:options' => { 'ignoreErrors' => false }
                                   })

    assert_raises(Exception) do
      Percy::AppPercy.screenshot(@mock_android_webdriver, 'screenshot')
    end
  end

  def test_invalid_provider
    url = 'some-cloud-url'
    mock_driver_remote_url(@mock_android_webdriver, url, 2)
    @mock_android_webdriver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    caps = get_android_capabilities
    4.times do
      @mock_android_webdriver.expect(:capabilities, caps)
    end

    Percy::GenericProvider.stub(:supports, false) do
      assert_raises(UnknownProvider) do
        _provider = Percy::AppPercy.new(@mock_android_webdriver).provider
      end
    end
  end

  def test_invalid_driver
    assert_raises(DriverNotSupported) do
      Percy::AppPercy.new(Object.new)
    end
  end

  private

  def disable_percy_options(mock_webdriver, num = 1)
    num.times do
      mock_webdriver.expect(:capabilities, {
                              'platformName' => 'android',
                              'percy:options' => { 'enabled' => false }
                            })
    end
  end

  def mock_driver_remote_url(mock_webdriver, url, num = 1)
    num.times do
      mock_webdriver.expect(:instance_variable_get, @bridge, [:@bridge])
      @http.expect(:instance_variable_get, @server_url, [:@server_url])
      @bridge.expect(:instance_variable_get, @http, [:@http])
      @server_url.expect(:to_s, url)
    end
  end

  def make_mock_driver_appium(mock_driver)
    mock_driver.expect(:is_a?, true, [Appium::Core::Base::Driver])
  end

  def ignore_errors_test(mock_webdriver)
    mock_webdriver.expect(:capabilities, {
                            'platformName': 'android',
                            'percy:options' => { 'ignoreErrors' => false }
                          })

    assert_raises(Exception) do
      Percy::AppPercy.screenshot(mock_webdriver, 'screenshot')
    end
  end
end
