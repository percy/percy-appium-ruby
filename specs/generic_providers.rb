# frozen_string_literal: true

require 'minitest/autorun'
require 'securerandom'
require 'appium_lib'
require_relative '../percy/providers/generic_provider'
require_relative '../percy/metadata/android_metadata'
require_relative '../percy/lib/region'
require_relative 'mocks/mock_methods'

# Test suite for the Percy::GenericProvider class
class TestGenericProvider < Minitest::Test
  include Appium
  COMPARISON_RESPONSE = { 'comparison' => { 'id' => 123, 'url' => 'https://percy-build-url' } }.freeze
  LocationStruct = Struct.new(:x, :y)
  SizeStruct = Struct.new(:width, :height)

  def setup
    @existing_dir = 'existing-dir'
    teardown
    Dir.mkdir(@existing_dir)

    @mock_webdriver = Minitest::Mock.new
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:orientation, 'PorTrait')
    @mock_webdriver.expect(:get_system_bars, {
                             'statusBar' => { 'height' => 10, 'width' => 20 },
                             'navigationBar' => { 'height' => 10, 'width' => 20 }
                           })

    png_bytes = 'some random bytes'
    @mock_webdriver.expect(:screenshot_as, png_bytes, [:png])

    @android_metadata = Percy::AndroidMetadata.new(@mock_webdriver)
    @generic_provider = Percy::GenericProvider.new(@mock_webdriver, @android_metadata)
  end

  def teardown
    if Dir.exist?(@existing_dir)
      FileUtils.remove_dir(@existing_dir, force: true)
    end
  end

  def test_get_dir_without_env_variable
    ENV.delete('PERCY_TMP_DIR')
    result = @generic_provider._get_dir
    assert File.directory?(result), 'Directory should exist'
  end

  def test_get_dir_with_env_variable
    ENV['PERCY_TMP_DIR'] = '/tmp/percy-apps'
    result = @generic_provider._get_dir
    assert_equal '/tmp/percy-apps', result
    assert File.directory?(result), 'Directory should exist'
    Dir.rmdir(result)
    ENV.delete('PERCY_TMP_DIR')
  end

  def test_get_path
    count = 1000
    png_paths = Array.new(count) { @generic_provider._get_path(@existing_dir) }
    assert_equal png_paths.uniq.length, count
  end

  def test_write_screenshot
    png_bytes = 'some random bytes'
    filepath = @generic_provider._write_screenshot(png_bytes, @existing_dir)
    assert(File.exist?(filepath))
  end

  def test_get_debug_url
    assert_equal @generic_provider.get_debug_url, ''
  end

  def test_get_tag
    10.times do
      @mock_webdriver.expect(:capabilities, get_android_capabilities)
    end
    tag = @generic_provider._get_tag
    assert_includes tag, 'name'
    assert_equal tag['name'], @android_metadata.device_name
    assert_includes tag, 'os_name'
    assert_equal tag['os_name'], @android_metadata.os_name
    assert_includes tag, 'os_version'
    assert_equal tag['os_version'], @android_metadata.os_version
    assert_includes tag, 'width'
    assert_equal tag['width'], @android_metadata.device_screen_size['width']
    assert_includes tag, 'height'
    assert_equal tag['height'], @android_metadata.device_screen_size['height']
    assert_includes tag, 'orientation'
    assert_equal tag['orientation'], @android_metadata.get_orientation.downcase
  end

  def test_get_tag_kwargs
    10.times do
      @mock_webdriver.expect(:capabilities, get_android_capabilities)
    end
    device_name = 'some-device-name'
    tag = @generic_provider._get_tag(device_name: device_name)
    assert_includes tag, 'name'
    assert_equal tag['name'], device_name

    orientation = 'Some-Orientation'
    tag = @generic_provider._get_tag(orientation: orientation)
    assert_includes tag, 'orientation'
    assert_equal tag['orientation'], orientation.downcase
  end

  def test_get_tiles
    session_id = 'session_id_123'
    10.times do
      @mock_webdriver.expect(:session_id, session_id)
    end
    10.times do
      @mock_webdriver.expect(:get_system_bars, {
                               'statusBar' => { 'height' => 10, 'width' => 20 },
                               'navigationBar' => { 'height' => 10, 'width' => 20 }
                             })
    end
    tile = @generic_provider._get_tiles[0]
    dict_tile = tile.to_h
    assert_includes dict_tile, 'filepath'
    assert_instance_of String, dict_tile['filepath']
    assert(File.exist?(dict_tile['filepath']))
    assert_includes dict_tile, 'status_bar_height'
    assert_equal dict_tile['status_bar_height'], @android_metadata.status_bar_height
    assert_includes dict_tile, 'nav_bar_height'
    assert_equal dict_tile['nav_bar_height'], @android_metadata.navigation_bar_height
    assert_includes dict_tile, 'header_height'
    assert_equal dict_tile['header_height'], 0
    assert_includes dict_tile, 'footer_height'
    assert_equal dict_tile['footer_height'], 0
    assert_includes dict_tile, 'fullscreen'
    assert_equal dict_tile['fullscreen'], false
    File.delete(tile.filepath)
  end

  def test_get_tiles_kwargs
    status_bar_height = 135
    nav_bar_height = 246
    tile = @generic_provider._get_tiles(
      status_bar_height: status_bar_height,
      nav_bar_height: nav_bar_height,
      full_screen: true
    )[0]
    dict_tile = tile.to_h
    assert_includes dict_tile, 'status_bar_height'
    assert_equal dict_tile['status_bar_height'], status_bar_height
    assert_includes dict_tile, 'nav_bar_height'
    assert_equal dict_tile['nav_bar_height'], nav_bar_height
    assert_includes dict_tile, 'fullscreen'
    assert_equal dict_tile['fullscreen'], true
  end

  def test_post_screenshots
    session_id = 'session_id_123'

    mock = Minitest::Mock.new
    mock.expect(:post_screenshots, COMPARISON_RESPONSE, [String, Hash, Hash, String, Array, Array])
    mock.expect(:session_id, session_id)
    10.times do
      mock.expect(:get_system_bars, {
                    'statusBar' => { 'height' => 10, 'width' => 20 },
                    'navigationBar' => { 'height' => 10, 'width' => 20 }
                  })
    end
    6.times do
      @mock_webdriver.expect(:capabilities, get_android_capabilities)
    end

    Percy::Metadata.class_eval do
      define_method(:session_id) do
        mock.session_id
      end
    end

    Percy::AndroidMetadata.class_eval do
      6.times do
        define_method(:get_system_bars) do
          mock.get_system_bars
        end
      end
    end

    tag = @generic_provider._get_tag
    tiles = @generic_provider._get_tiles

    @generic_provider.stub(:_post_screenshots, COMPARISON_RESPONSE) do
      response = @generic_provider._post_screenshots(
        'screenshot 1', tag, tiles, '', [], []
      )
      assert_equal response, COMPARISON_RESPONSE
    end
  end

  def test_supports
    assert Percy::GenericProvider.supports('some-dummy-url')
  end

  def test_non_app_automate
    session_id = 'session_id_123'
    mock = Minitest::Mock.new
    4.times do
      mock.expect(:session_id, session_id)
    end

    Percy::Metadata.class_eval do
      4.times do
        define_method(:session_id) do
          mock.session_id
        end
      end
    end

    7.times do
      @mock_webdriver.expect(:capabilities, get_android_capabilities)
    end
    6.times do
      @mock_webdriver.expect(:get_system_bars, {
                               'statusBar' => { 'height' => 10, 'width' => 20 },
                               'navigationBar' => { 'height' => 10, 'width' => 20 }
                             })
    end

    @generic_provider.stub(:_post_screenshots, COMPARISON_RESPONSE) do
      response = @generic_provider.screenshot('screenshot 1')
      assert_equal response, COMPARISON_RESPONSE
    end
  end

  def test_get_device_name
    device_name = @generic_provider.get_device_name
    assert_equal device_name, ''
  end

  def test_get_region_object
    mock_element = Minitest::Mock.new
    2.times do
      mock_element.expect(:location, LocationStruct.new(10, 20))
      mock_element.expect(:size, SizeStruct.new(100, 200))
    end

    result = @generic_provider.get_region_object('my-selector', mock_element)
    expected_result = {
      'selector' => 'my-selector',
      'coOrdinates' => { 'top' => 20, 'bottom' => 220, 'left' => 10, 'right' => 110 }
    }

    assert_equal result, expected_result
    mock_element.verify
  end

  def test_get_regions_by_xpath
    mock_element = Minitest::Mock.new
    2.times do
      mock_element.expect(:location, LocationStruct.new(10, 20))
      mock_element.expect(:size, SizeStruct.new(100, 200))
    end

    @mock_webdriver.expect(:find_element, mock_element,
                           [Appium::Core::Base::SearchContext::FINDERS[:xpath], '//path/to/element'])

    elements_array = []
    xpaths = ['//path/to/element']
    @generic_provider.get_regions_by_xpath(elements_array, xpaths)

    expected_elements_array = [{
      'selector' => 'xpath: //path/to/element',
      'coOrdinates' => { 'top' => 20, 'bottom' => 220, 'left' => 10, 'right' => 110 }
    }]

    assert_equal elements_array, expected_elements_array
  end

  def test_get_regions_by_xpath_with_non_existing_element
    @mock_webdriver.expect(:find_element, [Appium::Core::Base::SearchContext::FINDERS[:xpath], '//path/to/element']) do
      raise Appium::Core::Error::NoSuchElementError, 'Test error'
    end
    elements_array = []
    xpaths = ['//path/to/element']
    @generic_provider.get_regions_by_xpath(elements_array, xpaths)

    assert_empty elements_array
  end

  def test_get_regions_by_ids
    mock_element = Minitest::Mock.new
    2.times do
      mock_element.expect(:location, LocationStruct.new(10, 20))
      mock_element.expect(:size, SizeStruct.new(100, 200))
    end

    @mock_webdriver.expect(:find_element, mock_element,
                           [Appium::Core::Base::SearchContext::FINDERS[:accessibility_id], 'some_id'])

    elements_array = []
    ids = ['some_id']
    @generic_provider.get_regions_by_ids(elements_array, ids)

    expected_elements_array = [{
      'selector' => 'id: some_id',
      'coOrdinates' => { 'top' => 20, 'bottom' => 220, 'left' => 10, 'right' => 110 }
    }]

    assert_equal elements_array, expected_elements_array
  end

  def test_get_regions_by_ids_with_non_existing_element
    mock_element = Minitest::Mock.new
    2.times do
      mock_element.expect(:location, LocationStruct.new(10, 20))
      mock_element.expect(:size, SizeStruct.new(100, 200))
    end

    @mock_webdriver.expect(:find_element, [Appium::Core::Base::SearchContext::FINDERS[:accessibility_id], 'id1']) do
      raise Appium::Core::Error::NoSuchElementError, 'Test error'
    end

    elements_array = []
    ids = ['id1']
    @generic_provider.get_regions_by_ids(elements_array, ids)

    assert_empty elements_array
  end

  def test_get_regions_by_elements
    mock_element = Minitest::Mock.new
    2.times do
      mock_element.expect(:location, LocationStruct.new(10, 20))
      mock_element.expect(:size, SizeStruct.new(100, 200))
    end
    mock_element.expect(:attribute, 'textView', ['class'])

    elements_array = []
    elements = [mock_element]
    @generic_provider.get_regions_by_elements(elements_array, elements)

    expected_elements_array = [{
      'selector' => 'element: 0 textView',
      'coOrdinates' => { 'top' => 20, 'bottom' => 220, 'left' => 10, 'right' => 110 }
    }]

    assert_equal elements_array, expected_elements_array
    mock_element.verify
  end

  def test_get_regions_by_elements_with_non_existing_element
    element_mock = Minitest::Mock.new
    element_mock.expect(:attribute, 'class') do
      raise Appium::Core::Error::NoSuchElementError, 'Test error'
    end

    elements_array = []
    elements = [element_mock]

    @generic_provider.get_regions_by_elements(elements_array, elements)

    assert_equal 0, elements_array.length
  end

  def test_get_regions_by_location
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    valid_ignore_region = Percy::Region.new(100, 200, 200, 300)
    invalid_ignore_region = Percy::Region.new(100, 2390, 200, 300)

    elements_array = []
    custom_locations = [valid_ignore_region, invalid_ignore_region]
    @generic_provider.get_regions_by_location(elements_array, custom_locations)

    expected_elements_array = [{
      selector: 'custom ignore region: 0',
      coOrdinates: { top: 100, bottom: 200, left: 200, right: 300 }
    }]

    assert_equal elements_array, expected_elements_array
  end
end
