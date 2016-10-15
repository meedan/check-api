require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class BotTest < ActiveSupport::TestCase
  test "should create bot" do
    assert_difference 'Bot.count' do
      create_bot
    end
  end

  test "should not save bot without name" do
    assert_raise ActiveRecord::RecordInvalid do
      create_bot name: ''
    end
  end

  test "should have profile image" do
    b = create_bot
    assert_kind_of String, b.profile_image
  end
end
