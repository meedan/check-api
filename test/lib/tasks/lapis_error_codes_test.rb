require_relative '../../test_helper'
require 'rake'

class LapisErrorCodeTest < ActiveSupport::TestCase
  # Basic smoke test
  def setup
    Rake.application.rake_require("tasks/error_codes")
    Rake::Task.define_task(:environment)
  end

  test "lapis:error_codes doesn't error when run, and outputs list to stdout" do
    out, err = capture_io do
      Rake::Task['lapis:error_codes'].execute
    end

    assert_match /UNAUTHORIZED: 1/, out
    assert err.blank?
  end
end
