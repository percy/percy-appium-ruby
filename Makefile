release:
	rake build
	gem push pkg/percy-appium-app-*
