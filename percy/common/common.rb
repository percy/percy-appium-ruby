# frozen_string_literal: true

require 'dotenv/load'


def log(message, on_debug: nil)
  return unless on_debug.nil? || (on_debug.is_a?(TrueClass) && percy_debug)

  label = "[\e[35m#{percy_debug ? 'percy:ruby' : 'percy'}\e[39m]"

  puts "#{label} #{message}"
end

def hashed(object)
  return object.as_json unless object.is_a?(Hash)

  object
end

def percy_debug
  ENV['PERCY_LOGLEVEL'] == 'debug'
end
