require 'dotenv/load'

PERCY_LOGLEVEL = ENV['PERCY_LOGLEVEL']
PERCY_DEBUG = PERCY_LOGLEVEL == 'debug'
LABEL = "[\e[35m" + (PERCY_DEBUG ? 'percy:ruby' : 'percy') + "\e[39m]"

def log(message, on_debug: nil)
  if on_debug.nil? || (on_debug.is_a?(TrueClass) && PERCY_DEBUG)
    puts "#{LABEL} #{message}"
  end
end

def hashed(object)
  unless object.is_a?(Hash)
    return object.as_json
  end
  object
end
