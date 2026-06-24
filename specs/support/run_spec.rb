# frozen_string_literal: true

# Per-spec runner used by CI: `bundle exec ruby specs/support/run_spec.rb specs/<file>.rb`.
# Requires spec_helper first (starting SimpleCov within the bundler context, which
# a command-line `-r` flag cannot do reliably) and then loads the target spec.
require_relative 'spec_helper'

spec_file = ARGV[0] or abort('usage: run_spec.rb <spec_file>')
load File.expand_path(spec_file)
