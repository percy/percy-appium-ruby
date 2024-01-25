# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'appium_lib/version'
require_relative '../common/common'
require_relative '../exceptions/exceptions'
require_relative '../version'
require_relative '../environment'

module Percy
  CLIENT_INFO = "percy-appium-app/#{VERSION}"
  ENV_INFO = ["appium/#{Appium::VERSION}", "ruby/#{RUBY_VERSION}"].freeze

  PERCY_CLI_API = ENV['PERCY_CLI_API'] || 'http://localhost:5338'

  class CLIWrapper
    def initialize; end

    def self.percy_enabled?
      @percy_enabled ||= begin
        uri = URI("#{PERCY_CLI_API}/percy/healthcheck")
        response = Net::HTTP.get_response(uri)

        raise CLIException, response.body unless response.is_a?(Net::HTTPSuccess)

        data = JSON.parse(response.body)
        raise CLIException, data['error'] unless data['success']

        Percy::Environment.percy_build_id = data['build']['id']
        Percy::Environment.percy_build_url = data['build']['url']
        Percy::Environment.session_type = data.fetch('type', nil)

        version = response['x-percy-core-version']
        if version.split('.')[0] != '1'
          log("Unsupported Percy CLI version, #{version}")
          return false
        end
        return true unless version.split('.')[1].to_i < 27

        log('Please upgrade to the latest CLI version for using this SDK. Minimum compatible version is 1.27.0-beta.0')
        return false
      rescue StandardError => e
        log('Percy is not running, disabling screenshots')
        log(e, on_debug: true)
        return false
      end
    end

    def post_screenshots(name, tag, tiles, external_debug_url = nil, ignored_elements_data = nil,
                         considered_elements_data = nil, sync = false)
      body = request_body(name, tag, tiles, external_debug_url, ignored_elements_data, considered_elements_data, sync)
      body['client_info'] = Percy::Environment.get_client_info
      body['environment_info'] = Percy::Environment.get_env_info

      uri = URI("#{PERCY_CLI_API}/percy/comparison")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 600 # seconds
      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      request.body = body.to_json

      response = http.request(request)
      data = JSON.parse(response.body)

      raise CLIException, data.fetch('error', 'UnknownException') if response.code != '200'

      data
    end

    def self.post_failed_event(error)
      body = {
        'clientInfo' => Percy::Environment.get_client_info(true),
        'message' => error,
        'errorKind' => 'sdk'
      }

      uri = URI("#{PERCY_CLI_API}/percy/events")
      response = Net::HTTP.post(uri, body.to_json, 'Content-Type' => 'application/json')

      # Handle errors
      if response.code.to_i != 200
        data = JSON.parse(response.body)
        error_message = data.fetch('error', 'UnknownException')
        raise CLIException, error_message
      end

      JSON.parse(response.body)
    rescue StandardError => e
      log(e.message, on_debug: true)
      nil
    end

    def post_poa_screenshots(name, session_id, command_executor_url, capabilities, desired_capabilities, options = nil)
      body = {
        'sessionId' => session_id,
        'commandExecutorUrl' => command_executor_url,
        'capabilities' => capabilities.dup, # In Ruby, you can duplicate the hash with `dup`
        'sessionCapabilities' => desired_capabilities.dup,
        'snapshotName' => name,
        'options' => options
      }

      body['client_info'] = Percy::Environment.get_client_info # Using class method without the underscore
      body['environment_info'] = Percy::Environment.get_env_info

      uri = URI("#{PERCY_CLI_API}/percy/automateScreenshot")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 600 # seconds
      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      request.body = body.to_json

      response = http.request(request)
      # Handle errors
      raise CLIException, "Error: #{response.message}" unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)

      if response.code != '200'
        error_message = data.fetch('error', 'UnknownException')
        raise CLIException, error_message
      end

      data
    end

    def request_body(name, tag, tiles, external_debug_url, ignored_elements_data, considered_elements_data, sync)
      tiles = tiles.map(&:to_h)
      {
        'name' => name,
        'tag' => tag,
        'tiles' => tiles,
        'ignored_elements_data' => ignored_elements_data,
        'external_debug_url' => external_debug_url,
        'considered_elements_data' => considered_elements_data,
        'sync' => sync
      }
    end
  end
end
