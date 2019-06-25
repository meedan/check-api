require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::TwitterTest < ActiveSupport::TestCase
  def setup
    super
    @bot = create_twitter_bot
    tt = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: tt, name: 'translation_published'
    create_field_instance annotation_type_object: tt, name: 'translation_text'
  end

  test "should return default bot" do
    assert_not_nil Bot::Twitter.default
  end

  test "should not send translation to Twitter in background if type is not translation" do
    Bot::Twitter.stubs(:delay_for).never
    d = create_dynamic_annotation
    @bot.send_to_twitter_in_background(d)
    Bot::Twitter.unstub(:delay_for)
  end

  test "should not send translation to Twitter in background if annotation is null" do
    Bot::Twitter.stubs(:delay_for).never
    @bot.send_to_twitter_in_background(nil)
    Bot::Twitter.unstub(:delay_for)
  end

  test "should send translation to Twitter in background if type is translation" do
    mocked = Bot::Twitter.delay_for(1.second)
    Bot::Twitter.stubs(:delay_for).returns(mocked).once
    t = create_dynamic_annotation annotation_type: 'translation'
    @bot.send_to_twitter_in_background(t)
    Bot::Twitter.unstub(:delay_for)
  end

  test "should send to Twitter" do
    p = create_project
    p.set_social_publishing({ 'twitter' => { 'token' => '123456', 'secret' => '123456' }, 'facebook' => { 'token' => '123456' } })
    p.save!
    pm = create_project_media project: p
    t = create_dynamic_annotation annotation_type: 'translation', set_fields: { 'translation_text' => 'Test' }.to_json, annotated: pm
    Twitter::REST::Client.any_instance.stubs(:update).returns(OpenStruct.new({ url: 'https://twitter.com/test/654321' })).once
    Twitter::REST::Client.any_instance.stubs(:configuration).returns(OpenStruct.new({ short_url_length_https: 10 }))
    Bot::Twitter.send_to_twitter(t.id)
    assert_equal 'https://twitter.com/test/654321', JSON.parse(DynamicAnnotation::Field.where(field_name: 'translation_published').last.value)['twitter']
  end

  test "should truncate text" do
    Bot::Twitter.any_instance.stubs(:twitter_client).returns(OpenStruct.new(configuration: OpenStruct.new({ short_url_length_https: 10 })))
    text = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna... aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
    assert_equal 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna... aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in repreh... ', @bot.send(:format_for_twitter, text)
    Bot::Twitter.any_instance.unstub(:twitter_client)
  end
end
