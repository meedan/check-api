require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'test_helper')
require 'sidekiq/testing'

class Bot::KeepTest < ActiveSupport::TestCase
  def setup
    create_annotation_type_and_fields('Keep Backup', { 'Response' => ['JSON', false] })
    @bot = Bot::Keep.new
  end

  test "should exist" do
    assert_kind_of Bot::Keep, @bot
  end
end
