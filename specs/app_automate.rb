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
    # Wrap the stub return hashes in explicit braces. Under Ruby 3 keyword
    # argument separation, a bare trailing hash is otherwise parsed as keyword
    # args to Minitest's stub, raising ArgumentError.
    @app_automate.stub(:execute_percy_screenshot_begin, { 'deviceName' => 'abc', 'osVersion' => '123' }) do
      @app_automate.stub(:execute_percy_screenshot_end, nil) do
        @app_automate.stub(:screenshot, { 'link' => 'https://link' }) do
          @app_automate.screenshot('name')
        end
      end
    end
  end

  # Covers app_automate.rb lines 34-36: the rescue branch in #screenshot where the
  # super call fails, #execute_percy_screenshot_end is invoked with 'failure', and the
  # error is re-raised.
  def test_screenshot_failure_calls_end_and_reraises
    captured = {}
    @app_automate.stub(:execute_percy_screenshot_begin, nil) do
      # super (GenericProvider#screenshot) calls _get_tiles first; make it blow up.
      @app_automate.stub(:_get_tiles, ->(**_kwargs) { raise StandardError, 'boom' }) do
        @app_automate.stub(:execute_percy_screenshot_end,
                           lambda do |name, url, status, sync = nil, message = nil|
                             captured[:name] = name
                             captured[:url] = url
                             captured[:status] = status
                             captured[:sync] = sync
                             captured[:message] = message
                           end) do
          error = assert_raises(StandardError) { @app_automate.screenshot('failing-shot') }
          assert_equal 'boom', error.message
        end
      end
    end
    assert_equal 'failing-shot', captured[:name]
    assert_equal 'failure', captured[:status]
    assert_equal 'boom', captured[:message]
  end

  # Covers app_automate.rb lines 24-26: when begin returns session details, the device
  # metadata and debug url are set before the super screenshot (driven through the stubbed
  # collaborators _get_tiles/_find_regions/_post_screenshots) succeeds.
  def test_screenshot_success_sets_metadata_and_debug_url
    session_details = {
      'deviceName' => 'Google Pixel 7',
      'osVersion' => '13.0',
      'buildHash' => 'bhash',
      'sessionHash' => 'shash'
    }
    post_response = { 'link' => 'https://link', 'data' => { 'ok' => true } }
    @app_automate.stub(:execute_percy_screenshot_begin, session_details) do
      @app_automate.stub(:_get_tiles, []) do
        @app_automate.stub(:_get_tag, {}) do
          @app_automate.stub(:_find_regions, []) do
            @app_automate.stub(:_post_screenshots, post_response) do
              @app_automate.stub(:execute_percy_screenshot_end, nil) do
                result = @app_automate.screenshot('shot')
                assert_equal({ 'ok' => true }, result)
              end
            end
          end
        end
      end
    end
    assert_equal 'Google Pixel 7', @metadata.device_name
    @mock_webdriver.expect(:capabilities, get_android_capabilities)
    assert_equal '13', @metadata.os_version
    assert_equal 'https://app-automate.browserstack.com/dashboard/v2/builds/bhash/sessions/shash',
                 @app_automate.get_debug_url
  end

  # Covers app_automate.rb line 50: when PERCY_DISABLE_REMOTE_UPLOADS=true and the
  # screenshot is NOT fullpage, _get_tiles falls back to the generic provider's _get_tiles
  # (run for real against the mock webdriver), returning a single file-backed tile.
  def test_get_tiles_disable_remote_uploads_non_fullpage_falls_back_to_super
    ENV['PERCY_DISABLE_REMOTE_UPLOADS'] = 'true'
    @mock_webdriver.expect(:screenshot_as, 'png-bytes', [:png])

    tiles = nil
    @metadata.stub(:status_bar_height, 100) do
      @metadata.stub(:navigation_bar_height, 150) do
        tiles = @app_automate._get_tiles(fullpage: false)
      end
    end

    assert_equal 1, tiles.length
    dict_tile = tiles[0].to_h
    assert_includes dict_tile, 'filepath'
    assert(File.exist?(dict_tile['filepath']))
    assert_equal 100, dict_tile['status_bar_height']
    assert_equal 150, dict_tile['nav_bar_height']
    File.delete(tiles[0].filepath)
  ensure
    ENV.delete('PERCY_DISABLE_REMOTE_UPLOADS')
  end

  # Covers app_automate.rb lines 49 (fullpage warning puts) and the path that does NOT
  # fall back to super (line 50 skipped because fullpage_ss is true): full remote
  # screenshot orchestration continues with PERCY_DISABLE_REMOTE_UPLOADS=true.
  def test_get_tiles_disable_remote_uploads_fullpage_warns_and_continues
    ENV['PERCY_DISABLE_REMOTE_UPLOADS'] = 'true'
    metadata_mock = Minitest::Mock.new
    metadata_mock.expect(:device_screen_size, { 'width' => 1080, 'height' => 1920 })
    metadata_mock.expect(:scale_factor, 1)
    metadata_mock.expect(:status_bar_height, 100)
    metadata_mock.expect(:navigation_bar_height, 150)

    @metadata.stub(:device_screen_size, { 'width' => 1080, 'height' => 1920 }) do
      @metadata.stub(:scale_factor, 1) do
        @metadata.stub(:status_bar_height, 100) do
          @metadata.stub(:navigation_bar_height, 150) do
            @app_automate.stub(:execute_percy_screenshot, {
                                 'result' => '[{"sha":"abc-1234","header_height":10,"footer_height":20}]'
                               }) do
              tiles = @app_automate._get_tiles(fullpage: true)
              assert_equal 1, tiles.length
              assert_equal 'abc', tiles[0].sha
              assert_equal 100, tiles[0].status_bar_height
              assert_equal 150, tiles[0].nav_bar_height
              assert_equal 10, tiles[0].header_height
              assert_equal 20, tiles[0].footer_height
            end
          end
        end
      end
    end
  ensure
    ENV.delete('PERCY_DISABLE_REMOTE_UPLOADS')
  end

  # Covers app_automate.rb lines 100-104: the rescue in #execute_percy_screenshot_begin
  # when execute_script raises; it logs and returns nil.
  def test_execute_percy_screenshot_begin_handles_error_returns_nil
    @mock_webdriver.expect(:execute_script, nil) do
      raise StandardError, 'begin failed'
    end
    result = @app_automate.execute_percy_screenshot_begin('Screenshot 1')
    assert_nil result
    @mock_webdriver.verify
  end

  # Covers app_automate.rb lines 123-125: the rescue in #execute_percy_screenshot_end
  # when execute_script raises; it logs and swallows the error (returns nil).
  def test_execute_percy_screenshot_end_handles_error
    @mock_webdriver.expect(:execute_script, nil) do
      raise StandardError, 'end failed'
    end
    result = @app_automate.execute_percy_screenshot_end('Screenshot 1', 'snapshot-url', 'success')
    assert_nil result
    @mock_webdriver.verify
  end

  # Covers app_automate.rb lines 156-159: the rescue in #execute_percy_screenshot when
  # execute_script raises; it logs and re-raises the error.
  def test_execute_percy_screenshot_handles_error_reraises
    @mock_webdriver.expect(:execute_script, nil) do
      raise StandardError, 'screenshot failed'
    end
    error = assert_raises(StandardError) do
      @app_automate.execute_percy_screenshot(1080, 'singlepage', 5)
    end
    assert_equal 'screenshot failed', error.message
    @mock_webdriver.verify
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
