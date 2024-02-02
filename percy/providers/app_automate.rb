# frozen_string_literal: true

require 'json'
require_relative '../common/common'
require_relative '../lib/tile'
require_relative 'generic_provider'
require_relative '../environment'

module Percy
  class AppAutomate < Percy::GenericProvider
    def self.supports(remote_url)
      r_index = remote_url.rindex(ENV['AA_DOMAIN'].nil? ? 'browserstack' : ENV['AA_DOMAIN'])
      if r_index
        r_index > -1
      else
        false
      end
    end

    def screenshot(name, **kwargs)
      session_details = execute_percy_screenshot_begin(name)

      if session_details
        metadata.device_name = session_details['deviceName']
        metadata.os_version = session_details['osVersion']
        set_debug_url(session_details)
      end

      begin
        response = super(name, **kwargs)
        percy_screenshot_url = response.fetch('link', '')
        execute_percy_screenshot_end(name, percy_screenshot_url, 'success', kwargs.fetch('sync', nil))
        response['data']
      rescue StandardError => e
        execute_percy_screenshot_end(name, percy_screenshot_url, 'failure', kwargs.fetch('sync', nil), e.message)
        raise e
      end
    end

    def set_debug_url(session_details)
      build_hash = session_details['buildHash'].to_s
      session_hash = session_details['sessionHash'].to_s
      @debug_url = "https://app-automate.browserstack.com/dashboard/v2/builds/#{build_hash}/sessions/#{session_hash}"
    end

    def _get_tiles(**kwargs)
      fullpage_ss = kwargs[:fullpage] || false
      if ENV['PERCY_DISABLE_REMOTE_UPLOADS'] == 'true'
        puts("Full page screenshots are only supported when 'PERCY_DISABLE_REMOTE_UPLOADS' is not set") if fullpage_ss
        return super(**kwargs) unless fullpage_ss
      end
      screenshot_type = fullpage_ss ? 'fullpage' : 'singlepage'
      screen_lengths = kwargs[:screen_lengths] || 4
      scrollable_xpath = kwargs[:scollable_xpath]
      scrollable_id = kwargs[:scrollable_id]
      top_scrollview_offset = kwargs[:top_scrollview_offset]
      bottom_scrollview_offset = kwargs[:top_scrollview_offset]

      data = execute_percy_screenshot(
        metadata.device_screen_size.fetch('height', 1),
        screenshot_type,
        screen_lengths,
        scrollable_xpath,
        scrollable_id,
        metadata.scale_factor,
        top_scrollview_offset,
        bottom_scrollview_offset
      )
      tiles = []
      status_bar_height = metadata.status_bar_height
      nav_bar_height = metadata.navigation_bar_height

      JSON.parse(data['result']).each do |tile_data|
        tiles << Percy::Tile.new(
          status_bar_height,
          nav_bar_height,
          tile_data['header_height'],
          tile_data['footer_height'],
          sha: tile_data['sha'].split('-')[0]
        )
      end

      tiles
    end

    def execute_percy_screenshot_begin(name)
      request_body = {
        action: 'percyScreenshot',
        arguments: {
          state: 'begin',
          percyBuildId: Percy::Environment.percy_build_id,
          percyBuildUrl: Percy::Environment.percy_build_url,
          name: name
        }
      }
      command = "browserstack_executor: #{request_body.to_json}"
      begin
        response = metadata.execute_script(command)
        JSON.parse(response)
      rescue StandardError => e
        log('Could not set session as Percy session')
        log('Error occurred during begin call', on_debug: true)
        log(e, on_debug: true)
        nil
      end
    end

    def execute_percy_screenshot_end(name, percy_screenshot_url, status, sync = nil, status_message = nil)
      request_body = {
        action: 'percyScreenshot',
        arguments: {
          state: 'end',
          percyScreenshotUrl: percy_screenshot_url,
          name: name,
          status: status,
          sync: sync
        }
      }
      request_body[:arguments][:statusMessage] = status_message if status_message
      command = "browserstack_executor: #{request_body.to_json}"
      begin
        metadata.execute_script(command)
      rescue StandardError => e
        log('Error occurred during end call', on_debug: true)
        log(e, on_debug: true)
      end
    end

    def execute_percy_screenshot(device_height, screenshotType, screen_lengths, scrollable_xpath = nil,
                                scrollable_id = nil, scale_factor = 1, top_scrollview_offset = 0,
                                bottom_scrollview_offset = 0)
      project_id = ENV['PERCY_ENABLE_DEV'] == 'true' ? 'percy-dev' : 'percy-prod'
      request_body = {
        action: 'percyScreenshot',
        arguments: {
          state: 'screenshot',
          percyBuildId: Percy::Environment.percy_build_id,
          screenshotType: screenshotType,
          projectId: project_id,
          scaleFactor: scale_factor,
          options: {
            numOfTiles: screen_lengths,
            deviceHeight: device_height,
            scrollableXpath: scrollable_xpath,
            scrollableId: scrollable_id,
            topScrollviewOffset: top_scrollview_offset,
            bottomScrollviewOffset: bottom_scrollview_offset,
            'FORCE_FULL_PAGE' => ENV['FORCE_FULL_PAGE'] == 'true'
          }
        }
      }
      command = "browserstack_executor: #{request_body.to_json}"
      begin
        response = metadata.execute_script(command)
        JSON.parse(response)
      rescue StandardError => e
        log('Error occurred during screenshot call', on_debug: true)
        log(e, on_debug: true)
        raise e
      end
    end
  end
end
