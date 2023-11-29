require 'minitest/autorun'
require 'json'
require 'webmock/minitest'
require 'appium_lib'
require 'webrick'

require_relative '../percy/screenshot'
require_relative '../percy/lib/app_percy'
require_relative 'mocks/mock_methods'

class MockServerRequestHandler < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(_request, response)
    response.status = 200
    response['Content-Type'] = 'application/json'
    response.body = 'Screenshot Me'
  end
end

mock_server = WEBrick::HTTPServer.new(Port: 8000)
mock_server.mount('/', MockServerRequestHandler)
mock_server_thread = Thread.new { mock_server.start }

# Mock helpers
def mock_healthcheck(fail: false, fail_how: 'error', type: 'AppPercy')
  health_body = JSON.dump(success: true, build: { 'id' => '123', 'url' => 'dummy_url' }, type: type)
  health_headers = { 'X-Percy-Core-Version' => '1.27.0-beta.1' }
  health_status = 200

  if fail && fail_how == 'error'
    health_body = '{"success": false, "error": "test"}'
    health_status = 500
  elsif fail && fail_how == 'wrong-version'
    health_headers = { 'X-Percy-Core-Version' => '2.0.0' }
  elsif fail && fail_how == 'no-version'
    health_headers = {}
  end

  stub_request(:get, 'http://localhost:5338/percy/healthcheck')
    .with(headers: health_headers)
    .to_return(body: health_body, status: health_status)

  stub_request(:get, 'http://localhost:5338/percy/healthcheck')
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Host' => 'localhost:5338',
        'User-Agent' => 'Ruby'
      }
    )
    .to_return(status: health_status, body: health_body, headers: health_headers)
end

def mock_screenshot(fail: false)
  stub_request(:post, 'http://localhost:5338/percy/comparison')
    .to_return(body: '{"success": ' + (fail ? 'false, "error": "test"' : 'true') + '}', status: (fail ? 500 : 200))
end

def mock_poa_screenshot(fail: false)
  stub_request(:post, 'http://localhost:5338/percy/automateScreenshot')
    .to_return(body: '{"success": ' + (fail ? 'false, "error": "test"' : 'true') + '}', status: (fail ? 500 : 200))
end

def mock_session_request
  stub_request(:post, 'http://127.0.0.1:4723/wd/hub/session')
    .to_return(status: 200, body: '', headers: {})
end

class TestPercyScreenshot < Minitest::Test
  def setup
    @mock_webdriver = Minitest::Mock.new
    @bridge = Minitest::Mock.new
    @http = Minitest::Mock.new
    @server_url = Minitest::Mock.new
    @mock_webdriver.expect(:class, Appium::Core::Base::Driver)
    WebMock.enable!
    @requests = []
    WebMock.after_request do |request, _response|
      @requests << request
    end
  end

  def teardown
    WebMock.disable!
  end

  def test_throws_error_when_app_percy_arg_type_mismatch
    6.times do
      @mock_webdriver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    end
    30.times do
      @mock_webdriver.expect(:capabilities, get_android_capabilities)
    end
    6.times do
      @mock_webdriver.expect(:instance_variable_get, @bridge, [:@bridge])
      @http.expect(:instance_variable_get, @server_url, [:@server_url])
      @bridge.expect(:instance_variable_get, @http, [:@http])
      @server_url.expect(:to_s, 'https://hub-cloud.browserstack.com/wd/hub')
    end

    assert_raises(TypeError) { AppPercy.new(@mock_webdriver).screenshot(123) }
    assert_raises(TypeError) { AppPercy.new(@mock_webdriver).screenshot('screenshot 1', device_name: 123) }
    assert_raises(TypeError) { AppPercy.new(@mock_webdriver).screenshot('screenshot 1', full_screen: 123) }
    assert_raises(TypeError) { AppPercy.new(@mock_webdriver).screenshot('screenshot 1', orientation: 123) }
    assert_raises(TypeError) { AppPercy.new(@mock_webdriver).screenshot('screenshot 1', status_bar_height: 'height') }
    assert_raises(TypeError) { AppPercy.new(@mock_webdriver).screenshot('screenshot 1', nav_bar_height: 'height') }
  end

  def test_throws_error_when_a_driver_is_not_provided
    assert_raises(Exception) { percy_screenshot }
  end

  def test_throws_error_when_a_name_is_not_provided
    assert_raises(Exception) { percy_screenshot(@mock_webdriver) }
  end

  def test_disables_screenshots_when_the_healthcheck_fails
    mock_healthcheck(fail: true)

    assert_output(/Percy is not running, disabling screenshots/) do
      percy_screenshot(@mock_webdriver, 'screenshot 1')
      percy_screenshot(@mock_webdriver, 'screenshot 2')
    end

    assert_equal('/percy/healthcheck', @requests.last.uri.path)
  end

  def test_disables_screenshots_when_the_healthcheck_version_is_wrong
    mock_healthcheck(fail: true, fail_how: 'wrong-version')

    assert_output(/Unsupported Percy CLI version, 2.0.0/) do
      percy_screenshot(@mock_webdriver, 'screenshot 1')
      percy_screenshot(@mock_webdriver, 'screenshot 2')
    end

    assert_equal('/percy/healthcheck', @requests.last.uri.path)
  end

  def test_posts_screenshot_poa
    mock_healthcheck(type: 'automate')
    mock_poa_screenshot
    mock_session_request

    driver = Minitest::Mock.new
    @bridge = Minitest::Mock.new
    @http = Minitest::Mock.new
    @server_url = Minitest::Mock.new

    2.times do
      driver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    end
    10.times do
      driver.expect(:session_id, 'Dummy_session_id')
    end
    4.times do
      driver.expect(:capabilities, { 'key' => 'value' })
    end
    2.times do
      driver.expect(:desired_capabilities, { 'key' => 'value' })
    end
    2.times do
      driver.expect(:instance_variable_get, @bridge, [:@bridge])
      @http.expect(:instance_variable_get, @server_url, [:@server_url])
      @bridge.expect(:instance_variable_get, @http, [:@http])
      @server_url.expect(:to_s, 'https://hub-cloud.browserstack.com/wd/hub')
    end

    element = Minitest::Mock.new
    element.expect(:id, 'Dummy_id')

    consider_element = Minitest::Mock.new
    consider_element.expect(:id, 'Consider_Dummy_id')
    @mock_webdriver.expect(:capabilities, { 'key' => 'value' })

    percy_screenshot(driver, 'Snapshot 1', options: {})
    percy_screenshot(driver, 'Snapshot 2', options: { 'enable_javascript' => true,
                                                      'ignore_region_appium_elements' => [element],
                                                      'consider_region_appium_elements' => [consider_element] })

    assert_equal('/percy/automateScreenshot', @requests.last.uri.path)

    s1 = JSON.parse(@requests[1].body)
    assert_equal('Snapshot 1', s1['snapshotName'])
    assert_equal('Dummy_session_id', s1['sessionId'])
    assert_equal(
      driver.instance_variable_get(:@bridge).instance_variable_get(:@http).instance_variable_get(:@server_url).to_s,
      s1['commandExecutorUrl']
    )
    driver_caps = driver.capabilities
    assert_equal(driver_caps, s1['capabilities'])
    driver_desired_caps = driver.desired_capabilities
    assert_equal(driver_desired_caps, s1['sessionCapabilities'])
    assert_match(%r{percy-appium-app/\d+}, s1['client_info'])
    assert_match(%r{appium/\d+}, s1['environment_info'][0])
    assert_match(%r{ruby/\d+\.\d+\.\d+}, s1['environment_info'][1])

    s2 = JSON.parse(@requests[-1].body)
    assert_equal('Snapshot 2', s2['snapshotName'])
    assert_equal(true, s2['options']['enable_javascript'])
    assert_equal(['Dummy_id'], s2['options']['ignore_region_elements'])
    assert_equal(['Consider_Dummy_id'], s2['options']['consider_region_elements'])
  end

  def test_posts_multiple_screenshots_to_the_local_percy_server
    mock_healthcheck
    mock_screenshot

    driver = Minitest::Mock.new

    2.times do
      driver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    end

    10.times do
      driver.expect(:session_id, 'Dummy_session_id')
    end

    26.times do
      driver.expect(:capabilities, get_android_capabilities)
    end

    2.times do
      driver.expect(:instance_variable_get, @bridge, [:@bridge])
      @http.expect(:instance_variable_get, @server_url, [:@server_url])
      @bridge.expect(:instance_variable_get, @http, [:@http])
      @server_url.expect(:to_s, 'https://hub-cloud.browserstack.com/wd/hub')
    end

    6.times do
      driver.expect(:execute_script,
                    '{"success":true,"result":"[{\"sha\":\"sha-something\",\"status_bar\":null,\"nav_bar\":null,\"header_height\":0,\"footer_height\":0,\"index\":0}]"}', [String])
    end

    4.times do
      driver.expect(:get_system_bars, {
                      'statusBar' => { 'height' => 10, 'width' => 20 },
                      'navigationBar' => { 'height' => 10, 'width' => 20 }
                    })
    end

    percy_screenshot(driver, 'screenshot 1')
    percy_screenshot(driver, 'screenshot 2', full_screen: false)

    assert_equal('/percy/comparison', @requests.last.uri.path)

    body = JSON.parse(@requests[-1].body)
    assert_match(%r{percy-appium-app/\d+}, body['client_info'])
    assert_match(%r{appium/\d+}, body['environment_info'][0])
    assert_match(%r{ruby/\d+\.\d+\.\d+}, body['environment_info'][1])
  end

  def test_ignore_region_screenshots_to_the_local_percy_server
    mock_healthcheck
    mock_screenshot

    mock_element = Minitest::Mock.new
    mock_element.expect(:location, { 'x' => 10, 'y' => 20 })
    mock_element.expect(:size, { 'width' => 200, 'height' => 400 })

    xpaths = ['//path/to/element']

    driver = Minitest::Mock.new

    2.times do
      driver.expect(:is_a?, true, [Appium::Core::Base::Driver])
    end

    10.times do
      driver.expect(:session_id, 'Dummy_session_id')
    end

    26.times do
      driver.expect(:capabilities, get_android_capabilities)
    end

    2.times do
      driver.expect(:instance_variable_get, @bridge, [:@bridge])
      @http.expect(:instance_variable_get, @server_url, [:@server_url])
      @bridge.expect(:instance_variable_get, @http, [:@http])
      @server_url.expect(:to_s, 'https://hub-cloud.browserstack.com/wd/hub')
    end

    5.times do
      driver.expect(:execute_script,
                    '{"success":true,"result":"[{\"sha\":\"sha-something\",\"status_bar\":null,\"nav_bar\":null,\"header_height\":0,\"footer_height\":0,\"index\":0}]"}', [String])
    end

    4.times do
      driver.expect(:get_system_bars, {
                      'statusBar' => { 'height' => 10, 'width' => 20 },
                      'navigationBar' => { 'height' => 10, 'width' => 20 }
                    })
    end
    driver.expect(:find_element, mock_element,
                  [Appium::Core::Base::SearchContext::FINDERS[:xpath], '//path/to/element'])

    percy_screenshot(driver, 'screenshot 1', ignore_regions_xpaths: xpaths)

    assert_equal('/percy/comparison', @requests.last.uri.path)

    body = JSON.parse(@requests[-1].body)
    assert_match(%r{percy-appium-app/\d+}, body['client_info'])
    assert_match(%r{appium/\d+}, body['environment_info'][0])
    assert_equal(body['ignored_elements_data']['ignoreElementsData'].size, 1)

    ignored_element_data = body['ignored_elements_data']['ignoreElementsData'][0]
    assert_equal(ignored_element_data['selector'], 'xpath: //path/to/element')
    assert_equal(ignored_element_data['coOrdinates']['top'], 20)
    assert_equal(ignored_element_data['coOrdinates']['bottom'], 420)
    assert_equal(ignored_element_data['coOrdinates']['left'], 10)
    assert_equal(ignored_element_data['coOrdinates']['right'], 210)
  end

  def test_throws_error_when_a_driver_is_not_provided_poa
    mock_healthcheck(type: 'automate')
    assert_raises(Exception) { percy_screenshot }
  end

  def test_throws_error_when_invalid_driver_provided_poa
    mock_healthcheck(type: 'automate')
    assert_raises(Exception) { percy_screenshot('Wrong driver') }
  end

  def test_throws_error_when_a_name_is_not_provided_poa
    mock_healthcheck(type: 'automate')
    assert_raises(Exception) { percy_screenshot(@mock_webdriver) }
  end
end
