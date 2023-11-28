require 'json'


def get_android_capabilities
  {
    "platform" => "LINUX",
    "webStorageEnabled" => false,
    "takesScreenshot" => true,
    "javascriptEnabled" => true,
    "databaseEnabled" => false,
    "networkConnectionEnabled" => true,
    "locationContextEnabled" => false,
    "warnings" => {},
    "desired" => {
      "percy:options" => {
        "enabled" => true,
        "ignoreErrors" => false
      },
      "percyOptions" => {
        "enabled" => true,
        "ignoreErrors" => false
      },
      "platformName" => "Android",
      "bstack:options" => {
        "appiumVersion" => "1.17.0"
      },
      "goog:chromeOptions" => {},
      "newCommandTimeout" => 0,
      "deviceName" => "google pixel 4",
      "chromedriverPorts" => [
        [
          18144,
          18154
        ]
      ],
      "automationName" => "uiautomator2",
      "systemPort" => 8204,
      "chromedriverPort" => 18084,
      "build" => "android-builds",
      "os_version" => "10.0",
      "sessionName" => "first-session",
      "skipServerInstallation" => true,
      "udid" => "9A301FFAZ0043B",
      "appPackage" => "org.wikipedia.alpha",
      "appActivity" => "org.wikipedia.main.MainActivity",
      "nativeWebScreenshot" => true,
      "disableSuppressAccessibilityService" => true
    },
    "percy:options" => {
      "enabled" => true,
      "ignoreErrors" => true
    },
    "percyOptions" => {
      "enabled" => true,
      "ignoreErrors" => true
    },
    "platformName" => "Android",
    "bstack:options" => {
      "appiumVersion" => "1.17.0"
    },
    "goog:chromeOptions" => {},
    "newCommandTimeout" => 0,
    "deviceName" => "9A301FFAZ0043B",
    "chromedriverPorts" => [
      [
        18144,
        18154
      ]
    ],
    "automationName" => "uiautomator2",
    "systemPort" => 8204,
    "chromedriverPort" => 18084,
    "build" => "android-builds",
    "os_version" => "10.0",
    "sessionName" => "first-session",
    "skipServerInstallation" => true,
    "udid" => "9A301FFAZ0043B",
    "appPackage" => "org.wikipedia.alpha",
    "appActivity" => "org.wikipedia.main.MainActivity",
    "nativeWebScreenshot" => true,
    "disableSuppressAccessibilityService" => true,
    "deviceUDID" => "9A301FFAZ0043B",
    "deviceApiLevel" => 29,
    "platformVersion" => "10",
    "deviceScreenSize" => "1080x2280",
    "deviceScreenDensity" => 440,
    "deviceModel" => "Pixel 4",
    "deviceManufacturer" => "Google",
    "pixelRatio" => 2.75,
    "statBarHeight" => 83,
    "viewportRect" => {
      "left" => 0,
      "top" => 83,
      "width" => 1080,
      "height" => 2153
    }
  }
end

def get_ios_capabilities
  {
    "webStorageEnabled" => false,
    "locationContextEnabled" => false,
    "browserName" => "",
    "platform" => "MAC",
    "javascriptEnabled" => true,
    "databaseEnabled" => false,
    "takesScreenshot" => true,
    "networkConnectionEnabled" => false,
    "percy:options" => {
      "enabled" => true,
      "ignoreErrors" => true
    },
    "percyOptions" => {
      "enabled" => true,
      "ignoreErrors" => false
    },
    "platformName" => "iOS",
    "bstack:options" => {
      "appiumVersion" => "1.21.0"
    },
    "newCommandTimeout" => 0,
    "realMobile" => "true",
    "deviceName" => "iphone 14",
    "safariIgnoreFraudWarning" => true,
    "orientation" => "PORTRAIT",
    "deviceOrientation" => "PORTRAIT",
    "noReset" => true,
    "automationName" => "XCUITest",
    "keychainPath" => "[REDACTED VALUE]",
    "keychainPassword" => "[REDACTED VALUE]",
    "useXctestrunFile" => true,
    "bootstrapPath" => "/usr/local/.browserstack/config/wda_derived_data_16_1.21.0_e9279c32-baa8-4e44-b03e-00aa591b5c2b/Build/Products",
    "browserstack.isTargetBased" => "true",
    "build" => "ios-builds",
    "os_version" => "16",
    "sessionName" => "v0.0.1",
    "udid" => "00008110-001019020AA1401E",
    "bundleID" => "com.browserstack.Sample-iOS",
    "bundleId" => "com.browserstack.Sample-iOS",
    "webkitResponseTimeout" => 20000,
    "safariInitialUrl" => "http://mobile-internet-check.browserstack.com",
    "waitForQuiescence" => false,
    "wdaStartupRetries" => 3
  }
end
