require_relative '../../test_helper'

class LapisErrorCodeTest < ActiveSupport::TestCase
  # Basic smoke test
  def setup
    Check::Application.load_tasks
  end

  test "lapis:error_codes doesn't error when run, and outputs list to stdout" do
    out, err = capture_io do
      Rake::Task['lapis:error_codes'].invoke
    end

    assert_match /UNAUTHORIZED: 1/, out
    assert err.blank?
  end
end
