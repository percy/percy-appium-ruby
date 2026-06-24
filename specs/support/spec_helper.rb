# frozen_string_literal: true

# Loaded (via `ruby -r ./specs/support/spec_helper`) before each spec so
# SimpleCov can instrument the percy source. The suite runs one spec per
# process, so each process records its own result under a unique command_name;
# SimpleCov merges them into coverage/.resultset.json, and
# specs/support/coverage_check.rb collates the merged result and enforces the gate.
require 'simplecov'

SimpleCov.start do
  add_filter '/specs/'
  track_files 'percy/**/*.rb'
  command_name "specs:#{File.basename(ARGV.first || $PROGRAM_NAME)}"
  merge_timeout 3600
end
