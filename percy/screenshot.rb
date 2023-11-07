require_relative 'common/common'
require_relative 'lib/app_percy'
require_relative 'lib/percy_automate'
require_relative 'lib/cli_wrapper'
require_relative './environment'

def percy_screenshot(driver, name, **kwargs)
  begin
    return nil unless CLIWrapper.percy_enabled?
    app_percy = nil
    ProviderClass = Environment.session_type == 'automate' ? PercyOnAutomate : AppPercy
    app_percy = ProviderClass.new(driver)
    app_percy.screenshot(name, **kwargs)
  rescue StandardError => e
    CLIWrapper.post_failed_event(e.to_s)
    Common.log("Could not take screenshot \"#{name}\"")
    if app_percy && !app_percy.percy_options.ignore_errors
      raise e
    end
    Common.log(e, on_debug: true)
    nil
  end
end
