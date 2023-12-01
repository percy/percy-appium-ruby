# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../percy/metadata/metadata'

# Test suite for the Percy::Metadata class
class TestMetadata < Minitest::Test
  def setup
    @mock_webdriver = Minitest::Mock.new
    @metadata = Percy::Metadata.new(@mock_webdriver)
  end

  def test_metadata_properties
    assert_raises(NotImplementedError) { @metadata._device_name }
    assert_raises(NotImplementedError) { @metadata.device_screen_size }
    assert_raises(NotImplementedError) { @metadata.navigation_bar }
    assert_raises(NotImplementedError) { @metadata.navigation_bar_height }
    assert_raises(NotImplementedError) { @metadata.status_bar }
    assert_raises(NotImplementedError) { @metadata.status_bar_height }
    assert_raises(NotImplementedError) { @metadata.viewport }

    assert_equal({}, @metadata.device_info)

    device_config = @metadata.get_device_info('iPhone 6')
    refute_equal({}, @metadata.device_info)
    assert_equal(device_config, @metadata.get_device_info('iPhone 6'))

    ENV['PERCY_LOGLEVEL'] = 'debug'
  end

  def test_get_device_info_device_not_present
    device_name = 'Some Phone 123'
    assert_output(/#{Regexp.escape(device_name.downcase)} does not exist in config\./) do
      @metadata.get_device_info(device_name)
    end
  end

  def test_metadata_get_orientation
    orientation = 'PRTRT'
    @mock_webdriver.expect(:get_orientation, orientation, [{ "orientation": orientation }])
    assert(orientation, @metadata.get_orientation(orientation: orientation))

    orientation = 'prtrt'
    @mock_webdriver.expect(:get_orientation, orientation, [{ "orientation": orientation }])
    assert_equal(orientation.upcase, @metadata.get_orientation(orientation: orientation))

    orientation = 'OriENTation'
    @mock_webdriver.expect(:get_orientation, orientation, [{ "orientation": 'AUTO' }])

    @mock_webdriver.expect(:orientation, orientation)
    assert(orientation.upcase, @metadata.get_orientation(orientation: 'AUTO'))

    @mock_webdriver.expect(:orientation, orientation)
    assert(orientation.upcase, @metadata.get_orientation(orientation: 'auto'))

    @mock_webdriver.expect(:orientation, orientation)
    assert(orientation.upcase, @metadata.get_orientation(orientation: 'Auto'))

    orientation = 'OriEntaTion'
    @mock_webdriver.expect(:capabilities, { 'orientation' => orientation })
    assert_equal(orientation.upcase, @metadata.get_orientation)

    @mock_webdriver.expect(:capabilities, {})
    assert_equal('PORTRAIT', @metadata.get_orientation)
  end

  def test_metadata_session_id
    session_id = 'Some Totally random session ID'
    @mock_webdriver.expect(:session_id, session_id)
    assert_equal(session_id, @metadata.session_id)
    @mock_webdriver.verify
  end

  def test_metadata_os_version
    capabilities = { 'os_version' => '10' }
    @mock_webdriver.expect(:capabilities, capabilities)
    @mock_webdriver.expect(:capabilities, capabilities)
    @mock_webdriver.expect(:capabilities, capabilities)
    os_ver = @metadata.os_version
    assert_equal('10', os_ver)
  end

  def test_metadata_value_from_devices_info_for_android
    android_device = 'google pixel 7'
    android_device_info = { '13' => { 'status_bar' => '118', 'nav_bar' => '63' } }

    @metadata.instance_variable_set(:@device_name, nil)
    assert_equal(android_device_info['13']['status_bar'].to_i,
                 @metadata.value_from_devices_info('status_bar', android_device, '13'))
  end

  def test_metadata_value_from_devices_info_for_ios
    ios_device = 'iphone 12 pro max'
    ios_device_info = { 'scale_factor' => '3', 'status_bar' => '47' }

    @metadata.instance_variable_set(:@device_name, nil)
    assert_equal(
      ios_device_info['scale_factor'].to_i,
      @metadata.value_from_devices_info('scale_factor', ios_device)
    )
  end
end
