class BaseException < StandardError; end

class UnsupportedDevice < BaseException; end

class UnknownProvider < BaseException; end

class PlatformNotSupported < BaseException; end

class DriverNotSupported < BaseException; end

class CLIException < StandardError; end
