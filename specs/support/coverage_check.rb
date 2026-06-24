# frozen_string_literal: true

# Collates the per-process SimpleCov results written during the spec loop and
# enforces the coverage gate. Run after all specs:
#   bundle exec ruby specs/support/coverage_check.rb
require 'simplecov'

SimpleCov.collate Dir['coverage/.resultset.json'] do
  add_filter '/specs/'
  track_files 'percy/**/*.rb'
  minimum_coverage line: 100
end
