require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::FacebookTest < ActiveSupport::TestCase
  def setup
    super
    @bot = create_facebook_bot
    tt = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: tt, name: 'translation_published'
    create_field_instance annotation_type_object: tt, name: 'translation_text'
  end

  test "should return default bot" do
    assert_not_nil Bot::Facebook.default
  end

  test "should not send translation to Facebook in background if type is not translation" do
    Bot::Facebook.stubs(:delay_for).never
    d = create_dynamic_annotation
    @bot.send_to_facebook_in_background(d)
    Bot::Facebook.unstub(:delay_for)
  end

  test "should not send translation to Facebook in background if annotation is null" do
    Bot::Facebook.stubs(:delay_for).never
    @bot.send_to_facebook_in_background(nil)
    Bot::Facebook.unstub(:delay_for)
  end

  test "should send translation to Facebook in background if type is translation" do
    mocked = Bot::Facebook.delay_for(1.second)
    Bot::Facebook.stubs(:delay_for).returns(mocked).once
    t = create_dynamic_annotation annotation_type: 'translation'
    @bot.send_to_facebook_in_background(t)
    Bot::Facebook.unstub(:delay_for)
  end

  test "should send to Facebook" do
    p = create_project
    p.set_social_publishing({ 'twitter' => { 'token' => '123456', 'secret' => '123456' }, 'facebook' => { 'token' => '123456' } })
    p.save!
    pm = create_project_media project: p
    t = create_dynamic_annotation annotation_type: 'translation', set_fields: { 'translation_text' => 'Test' }.to_json, annotated: pm
    Bot::Facebook.send_to_facebook(t.id)
    assert_match /facebook.com/, JSON.parse(DynamicAnnotation::Field.where(field_name: 'translation_published').last.value)['facebook']
  end
end
