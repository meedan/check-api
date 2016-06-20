require 'test_helper'

class SourceTest < ActiveSupport::TestCase

  test "should create source" do
    assert_difference 'Source.count' do
      create_source
    end
  end

  test "should not save source without name" do
    source = Source.new
    assert_not  source.save
  end
end
