# frozen_string_literal: true

require 'json'
require 'tempfile'
require 'pathname'
require 'base64'
require 'fileutils'
require_relative '../lib/cli_wrapper'
require_relative '../lib/tile'
require_relative '../common/common'

module Percy
  class GenericProvider
    attr_accessor :driver, :metadata, :debug_url

    def initialize(driver, metadata)
      @driver = driver
      @metadata = metadata
      @debug_url = ''
    end

    def self.supports(_remote_url)
      true
    end

    def screenshot(name, **kwargs)
      tiles = _get_tiles(**kwargs)
      tag = _get_tag(**kwargs)
      ignore_regions = {
        'ignoreElementsData' => _find_regions(
          xpaths: kwargs.fetch(:ignore_regions_xpaths, []),
          accessibility_ids: kwargs.fetch(:ignore_region_accessibility_ids, []),
          appium_elements: kwargs.fetch(:ignore_region_appium_elements, []),
          custom_locations: kwargs.fetch(:custom_ignore_regions, [])
        )
      }
      consider_regions = {
        'considerElementsData' => _find_regions(
          xpaths: kwargs.fetch(:consider_regions_xpaths, []),
          accessibility_ids: kwargs.fetch(:consider_region_accessibility_ids, []),
          appium_elements: kwargs.fetch(:consider_region_appium_elements, []),
          custom_locations: kwargs.fetch(:custom_consider_regions, [])
        )
      }
      sync = kwargs.fetch(:sync, nil)

      _post_screenshots(name, tag, tiles, get_debug_url, ignore_regions, consider_regions, sync)
    end

    def _get_tag(**kwargs)
      name = kwargs[:device_name] || metadata.device_name
      os_name = metadata.os_name
      os_version = metadata.os_version
      width = metadata.device_screen_size['width'] || 1
      height = metadata.device_screen_size['height'] || 1
      orientation = metadata.get_orientation(**kwargs).downcase

      {
        'name' => name,
        'os_name' => os_name,
        'os_version' => os_version,
        'width' => width,
        'height' => height,
        'orientation' => orientation
      }
    end

    def _get_tiles(**kwargs)
      fullpage_ss = kwargs[:fullpage] || false
      if fullpage_ss
        log('Full page screenshot is only supported on App Automate. Falling back to single page screenshot.')
      end

      png_bytes = driver.screenshot_as(:png)
      directory = _get_dir
      path = _write_screenshot(png_bytes, directory)

      fullscreen = kwargs[:full_screen] || false
      status_bar_height = kwargs[:status_bar_height] || metadata.status_bar_height
      nav_bar_height = kwargs[:nav_bar_height] || metadata.navigation_bar_height
      header_height = 0
      footer_height = 0
      [
        Percy::Tile.new(status_bar_height, nav_bar_height, header_height, footer_height, filepath: path, fullscreen: fullscreen)
      ]
    end

    def _find_regions(xpaths:, accessibility_ids:, appium_elements:, custom_locations:)
      elements_array = []
      get_regions_by_xpath(elements_array, xpaths)
      get_regions_by_ids(elements_array, accessibility_ids)
      get_regions_by_elements(elements_array, appium_elements)
      get_regions_by_location(elements_array, custom_locations)
      elements_array
    end

    def _post_screenshots(name, tag, tiles, debug_url, ignored_regions, considered_regions, sync)
      Percy::CLIWrapper.new.post_screenshots(name, tag, tiles, debug_url, ignored_regions, considered_regions, sync)
    end

    def _write_screenshot(png_bytes, directory)
      filepath = _get_path(directory)
      File.open(filepath, 'wb') { |f| f.write(png_bytes) }
      filepath
    end

    def get_region_object(selector, element)
      scale_factor = metadata.scale_factor
      location = hashed(element.location)
      size = hashed(element.size)
      coordinates = {
        'top' => location['y'] * scale_factor,
        'bottom' => (location['y'] + size['height']) * scale_factor,
        'left' => location['x'] * scale_factor,
        'right' => (location['x'] + size['width']) * scale_factor
      }
      { 'selector' => selector, 'coOrdinates' => coordinates }
    end

    def get_regions_by_xpath(elements_array, xpaths)
      xpaths.each do |xpath|
        element = driver.find_element(Appium::Core::Base::SearchContext::FINDERS[:xpath], xpath)
        selector = "xpath: #{xpath}"
        if element
          region = get_region_object(selector, element)
          elements_array << region
        end
      rescue Appium::Core::Error::NoSuchElementError => e
        log("Appium Element with xpath: #{xpath} not found. Ignoring this xpath.")
        log(e, on_debug: true)
      end
    end

    def get_regions_by_ids(elements_array, ids)
      ids.each do |id|
        element = driver.find_element(Appium::Core::Base::SearchContext::FINDERS[:accessibility_id], id)
        selector = "id: #{id}"
        region = get_region_object(selector, element)
        elements_array << region
      rescue Appium::Core::Error::NoSuchElementError => e
        log("Appium Element with id: #{id} not found. Ignoring this id.")
        log(e, on_debug: true)
      end
    end

    def get_regions_by_elements(elements_array, elements)
      elements.each_with_index do |element, index|
        class_name = element.attribute('class')
        selector = "element: #{index} #{class_name}"
        region = get_region_object(selector, element)
        elements_array << region
      rescue Appium::Core::Error::NoSuchElementError => e
        log("Correct Element not passed at index #{index}")
        log(e, on_debug: true)
      end
    end

    def get_regions_by_location(elements_array, custom_locations)
      custom_locations.each_with_index do |custom_location, index|
        screen_width = metadata.device_screen_size['width']
        screen_height = metadata.device_screen_size['height']
        if custom_location.valid?(screen_height, screen_width)
          region = {
            selector: "custom ignore region: #{index}",
            coOrdinates: {
              top: custom_location.top,
              bottom: custom_location.bottom,
              left: custom_location.left,
              right: custom_location.right
            }
          }
          elements_array << region
        else
          log("Values passed in custom ignored region at index: #{index} are not valid")
        end
      end
    end

    def log(message, on_debug: false)
      puts message if on_debug
    end

    def get_debug_url
      debug_url
    end

    def get_device_name
      ''
    end

    def _get_dir
      dir_path = ENV['PERCY_TMP_DIR'] || nil
      if dir_path
        Pathname.new(dir_path).mkpath
        return dir_path
      end
      Dir.mktmpdir
    end

    def _get_path(directory)
      suffix = '.png'
      prefix = 'percy-appium-'
      file = Tempfile.new([prefix, suffix], directory)
      file.close
      file.path
    end
  end
end
