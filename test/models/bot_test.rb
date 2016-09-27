require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class BotTest < ActiveSupport::TestCase

  test "should create bot" do
    assert_difference 'Bot.count' do
      create_bot
    end
  end

  test "should not save bot without name" do
    project = Project.new
    assert_not project.save
  end

end
