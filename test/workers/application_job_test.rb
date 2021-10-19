require_relative '../test_helper'

class ApplicationJobTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
  end

  test "should define class" do
    assert_nothing_raised do
      assert ApplicationJob.is_a?(Class)
    end
  end
end
