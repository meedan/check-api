require_relative '../test_helper'

class ClaimSourceTest < ActiveSupport::TestCase
  def setup
    super
    @m = create_claim_media
    @s = create_source
  end

  test "should create claim source" do
    assert_difference 'ClaimSource.count' do
      create_claim_source media: @m, source: @s
    end
  end

  test "should have a source and media" do
    assert_no_difference 'ClaimSource.count' do
      assert_raise ActiveRecord::RecordInvalid do
        create_claim_source media: nil, source: @s
      end
      assert_raise ActiveRecord::RecordInvalid do
        create_claim_source source: nil, media: @m
      end
    end
  end
end
