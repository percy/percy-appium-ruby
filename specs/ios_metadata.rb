require 'minitest/autorun'
require 'minitest/mock'
require_relative 'mocks/mock_methods'
require_relative '../percy/metadata/ios_metadata'

class TestIOSMetadata < Minitest::Test
  def setup
    @mock_webdriver = Minitest::Mock.new
    @bridge = Minitest::Mock.new
    @http = Minitest::Mock.new
    @server_url = Minitest::Mock.new
    @ios_metadata = IOSMetadata.new(@mock_webdriver)
  end

  def test_ios_execute_script
    puts "test_ios_execute_script"
    command = 'some dummy command'
    output = 'some output'
    @mock_webdriver.expect(:execute_script, output, [command])

    response = @ios_metadata.execute_script(command)
    assert_equal(output, response)
  end

  def test_remote_url
    puts "test_remote_url"
    @mock_webdriver.expect(:instance_variable_get, @bridge, [:@bridge])
    @http.expect(:instance_variable_get, @server_url, [:@server_url])
    @bridge.expect(:instance_variable_get, @http, [:@http])
    @server_url.expect(:to_s, 'some-remote-url')

    assert_equal('some-remote-url', @ios_metadata.remote_url)

    
  end

  def test_get_window_size
    puts "test_get_window_size"
    height, width = 100, 100
    window_size = { 'height' => height, 'width' => width }
    @mock_webdriver.expect(:get_window_size, window_size)
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)

    assert_equal({}, @ios_metadata._window_size)
    fetched_window_size = @ios_metadata.get_window_size
    assert_equal(window_size, fetched_window_size)

    
  end

  def test_device_screen_size
    puts "test_device_screen_size"
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:capabilities, {"deviceName" => 'iPhone 6'})
    # @mock_webdriver.expect(:capabilities, get_ios_capabilities)
    @mock_webdriver.expect(:get_window_size, { 'height' => 100, 'width' => 100 })
    # @mock_webdriver.expect(:device_name, 'iPhone 6')
    device_screen_size = @ios_metadata.device_screen_size
    puts "device_screen_size", device_screen_size
    assert_equal({ 'height' => 200, 'width' => 200 }, device_screen_size)

    
  end

  def test_status_bar
    puts "test_status_bar"
    @mock_webdriver.expect(:capabilities, {"deviceName" => 'iPhone 6'})
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    
    status_bar = @ios_metadata.status_bar
    assert_equal({ 'height' => 40 }, status_bar)
    
  end

  def test_scale_factor_present_in_devices_json
    puts "test_scale_factor_present_in_devices_json"
    @mock_webdriver.expect(:capabilities, {"deviceName" => 'iPhone 6'})
    assert_equal(2, @ios_metadata.scale_factor)
    
  end

  def test_scale_factor_not_present_in_devices_json
    puts "test_scale_factor_not_present_in_devices_json"
    window_size = { 'height' => 100, 'width' => 100 }
    session_id = 'session_id_123'
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:session_id, session_id)
    @mock_webdriver.expect(:capabilities, {"deviceName" => 'iPhone 14'})
    @mock_webdriver.expect(:get_window_size, window_size)
    @mock_webdriver.expect(:execute_script, { 'height' => 100, 'width' => 200 }, ['mobile: viewportRect'])

    assert_equal(2, @ios_metadata.scale_factor)

    
  end
end

