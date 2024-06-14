# percy-appium-ruby

[Percy](https://percy.io) visual testing for Ruby Appium.

## Installation

npm install `@percy/cli`:

```sh-session
$ npm install --save-dev @percy/cli
```

gem install Percy appium package:

```ssh-session
$ gem install percy-appium-app
```


## Usage

This is an example test using the `percy_screenshot` function.

``` ruby
require 'appium_lib'
require 'percy-appium-app'

username = '<BROWSERSTACK_USERNAME>'
access_key = '<ACCESS_KEY>'

capabilities = {
  'platformName' => 'android',
  'platformVersion' => '13.0',
  'deviceName' => 'Google Pixel 7',
  'bstack:options' => {
    'appiumVersion' => '2.0.1'
  },
  'app' => '<APP LINK>',
  'appium:percyOptions' => {
    # enabled is default True. This can be used to disable visual testing for certain capabilities
    'enabled' => true
  }
}

appium_driver = Appium::Driver.new(
  {
    'caps' => capabilities,
    'appium_lib' => {
      server_url: "https://#{username}:#{access_key}@hub-cloud.browserstack.com/wd/hub"
    }
  }, true
)
driver = appium_driver.start_driver

# take a screenshot
percy_screenshot(driver, 'here is some name')
```

Running the test above normally will result in the following log:

```sh-session
[percy] Percy is not running, disabling screenshots
```

When running with [`percy
app:exec`](https://github.com/percy/cli/tree/master/packages/cli-exec#app-exec), and your project's
`PERCY_TOKEN`, a new Percy build will be created and screenshots will be uploaded to your project.

```sh-session
$ export PERCY_TOKEN=[your-project-token]
$ percy app:exec -- [ruby test command]
[percy] Percy has started!
[percy] Created build #1: https://percy.io/[your-project]
[percy] Screenshot taken "Ruby example"
[percy] Stopping percy...
[percy] Finalized build #1: https://percy.io/[your-project]
[percy] Done!
```

## Configuration

`percy_screenshot(driver, name[, **kwargs])`

- `driver` (**required**) - A appium driver instance
- `name` (**required**) - The screenshot name; must be unique to each screenshot
- `device_name` (**optional**) - The device name used for capturing screenshot
- `orientation` (**optional**) - Orientation of device while capturing screeenshot; Allowed values [`portrait` | `landscape`]
- `status_bar_height` (**optional**) - Height of status bar; int
- `nav_bar_height` (**optional**) - Height of navigation bar; int
- `fullpage` (**optional**) - [Alpha] Only supported on App Automate driver sessions [ needs @percy/cli 1.20.2+ ]; boolean
  - `screen_lengths` (**optional**) - [Alpha] Max screen lengths for fullPage; int
  - In case scrollview is overlapping with other app elements. Offsets can be provided to reduce the area which needs to be considered for scrolling:
    - `top_scrollview_offset`: (**optional**) - [Alpha] Offset from top of scrollview; int
    - `bottom_scrollview_offset` (**optional**) - [Alpha] Offset from bottom of scrollview; int
- `full_screen` (**optional**) - Indicate whether app is full screen; boolean [ needs @percy/cli 1.20.2+ ];
- `sync` (**optional**) - Waits for screenshot to be processed and gives the processed result of screenshot [needs @percy/cli v1.28.0-beta.0+]; boolean
- `scrollable_xpath` (**optional**) - [Alpha] Scrollable element xpath for fullpage [ needs @percy/cli 1.20.2+ ]; string
- `scrollable_id` (**optional**) - [Alpha] Scrollable element accessibility id for fullpage [ needs @percy/cli 1.20.2+ ]; string
- `ignore_regions_xpaths` (**optional**) - Elements xpaths that user want to ignore in visual diff [ needs @percy/cli 1.23.0+ ]; list of string
- `ignore_region_accessibility_ids` (**optional**) - Elements accessibility_ids that user want to ignore in visual diff [ needs @percy/cli 1.23.0+ ]; list of string
- `ignore_region_appium_elements` (**optional**) - Appium elements that user want to ignore in visual diff [ needs @percy/cli 1.23.0+ ]; list of appium element object
- `custom_ignore_regions` (**optional**) - Custom locations that user want to ignore in visual diff [ needs @percy/cli 1.23.0+ ]; list of ignore_region object
  - IgnoreRegion:-
    - Description: This class represents a rectangular area on a screen that needs to be ignored for visual diff.
    - Constructor:
      ```
      init(self, top, bottom, left, right)
      ```
    - Parameters:
      - `top` (int): Top coordinate of the ignore region.
      - `bottom` (int): Bottom coordinate of the ignore region.
      - `left` (int): Left coordinate of the ignore region.
      - `right` (int): Right coordinate of the ignore region.

## Running with Hybrid Apps

For a hybrid app, we need to switch to native context before taking screenshot.

- Add a helper method similar to following for say flutter based hybrid app:
```ruby
def percy_screenshot_flutter(driver, name: str, **kwargs):
  driver.switch_to.context('NATIVE_APP')
  percy_screenshot(driver, name, **kwargs)
  driver.switch_to.context('FLUTTER')
end
```

- Call PercyScreenshotFlutter helper function when you want to take screenshot.
```ruby
percy_screenshot_flutter(driver, name, **kwargs)
```

> Note: 
>
> For other hybrid apps the `driver.switch_to.context('FLUTTER')` would change to context that it uses like say WEBVIEW etc.
>

## Running Percy on Automate
`percy_screenshot(driver, name, options)` [ needs @percy/cli 1.27.0-beta.0+ ];
- `driver` (**required**) - A appium driver instance
- `name` (**required**) - The screenshot name; must be unique to each screenshot
- `options` (**optional**) - There are various options supported by percy_screenshot to server further functionality.
    - `sync` - Boolean value by default it falls back to `false`, Gives the processed result around screenshot [From CLI v1.28.0-beta.0+].
    - `freeze_animated_image` - Boolean value by default it falls back to `false`, you can pass `true` and percy will freeze image based animations.
    - `freeze_image_by_selectors` -List of selectors. Images will be freezed which are passed using selectors. For this to work `freeze_animated_image` must be set to true.
    - `freeze_image_by_xpaths` - List of xpaths. Images will be freezed which are passed using xpaths. For this to work `freeze_animated_image` must be set to true.
    - `percy_css` - Custom CSS to be added to DOM before the screenshot being taken. Note: This gets removed once the screenshot is taken.
    - `ignore_region_xpaths` - List of xpaths. elements in the DOM can be ignored using xpath
    - `ignore_region_selectors` - List of selectors. elements in the DOM can be ignored using selectors.
    - `ignore_region_appium_elements` - List of appium web-element. elements can be ignored using appium_elements.
    - `custom_ignore_regions` -  List of custom objects. elements can be ignored using custom boundaries. Just passing a simple object for it like below.
      - example: ```{"top": 10, "right": 10, "bottom": 120, "left": 10}```
      - In above example it will draw rectangle of ignore region as per given coordinates.
          - `top` (int): Top coordinate of the ignore region.
          - `bottom` (int): Bottom coordinate of the ignore region.
          - `left` (int): Left coordinate of the ignore region.
          - `right` (int): Right coordinate of the ignore region.
    - `consider_region_xpaths` - List of xpaths. elements in the DOM can be considered for diffing and will be ignored by Intelli Ignore using xpaths.
    - `consider_region_selectors` - List of selectors. elements in the DOM can be considered for diffing and will be ignored by Intelli Ignore using selectors.
    - `consider_region_appium_elements` - List of appium web-element. elements can be considered for diffing and will be ignored by Intelli Ignore using appium_elements.
    - `custom_consider_regions` - List of custom objects. elements can be considered for diffing and will be ignored by Intelli Ignore using custom boundaries
      - example:```{"top": 10, "right": 10, "bottom": 120, "left": 10}```
      - In above example it will draw rectangle of consider region will be drawn.
      - Parameters:
        - `top` (int): Top coordinate of the consider region.
        - `bottom` (int): Bottom coordinate of the consider region.
        - `left` (int): Left coordinate of the consider region.
        - `right` (int): Right coordinate of the consider region.

### Creating Percy on automate build
Note: Automate Percy Token starts with `auto` keyword. The command can be triggered using `exec` keyword.

```sh-session
$ export PERCY_TOKEN=[your-project-token]
$ percy exec -- [ruby test command]
[percy] Percy has started!
[percy] [Ruby example] : Starting automate screenshot ...
[percy] Screenshot taken "Ruby example"
[percy] Stopping percy...
[percy] Finalized build #1: https://percy.io/[your-project]
[percy] Done!
```

Refer to docs here: [Percy on Automate](https://www.browserstack.com/docs/percy/integrate/functional-and-visual)

### Migrating Config

If you have a previous Percy configuration file, migrate it to the newest version with the
[`config:migrate`](https://github.com/percy/cli/tree/master/packages/cli-config#percy-configmigrate-filepath-output) command:

```sh-session
$ percy config:migrate
```
