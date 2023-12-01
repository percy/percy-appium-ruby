# frozen_string_literal: true

require_relative 'common/common'
require_relative 'lib/app_percy'
require_relative 'lib/percy_automate'
require_relative 'lib/cli_wrapper'
require_relative 'environment'

def percy_screenshot(driver, name, **kwargs)
  return nil unless Percy::CLIWrapper.percy_enabled?

  app_percy = nil
  provider_class = Percy::Environment.session_type == 'automate' ? Percy::PercyOnAutomate : Percy::AppPercy
  app_percy = provider_class.new(driver)
  app_percy.screenshot(name, **kwargs)
rescue StandardError => e
  Percy::CLIWrapper.post_failed_event(e.to_s)
  log("Could not take screenshot \"#{name}\"")
  raise e if app_percy && !app_percy.percy_options.ignore_errors

  log(e, on_debug: true)
  nil
end
