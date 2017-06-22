require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'test_helper')
require 'sidekiq/testing'

class Bot::KeepTest < ActiveSupport::TestCase
  def setup
    DynamicAnnotation::AnnotationType.delete_all
    DynamicAnnotation::FieldInstance.delete_all
    DynamicAnnotation::FieldType.delete_all
    DynamicAnnotation::Field.delete_all
    create_annotation_type_and_fields('Keep Backup', { 'Response' => ['JSON', false] })
    @bot = Bot::Keep.new
    WebMock.stub_request(:post, 'https://www.bravenewtech.org/api/').to_return(body: { package: '123456' }.to_json)
    WebMock.stub_request(:post, 'https://www.bravenewtech.org/api/status.php').to_return(body: { location: 'http://keep.org' }.to_json)
    WebMock.stub_request(:post, /#{Regexp.escape(CONFIG['bridge_reader_url_private'])}.*/)
  end

  test "should exist" do
    assert_kind_of Bot::Keep, @bot
  end

  test "should send media to Keep" do
    t = create_team
    t.keep_enabled = 1
    t.save!
    l = create_link
    p = create_project team: t
    pm = nil
    stub_config('keep_token', '123456') do
      pm = create_project_media project: p, media: l
    end
    assert_not_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should not send media to Keep if media is not a link" do
    t = create_team
    t.keep_enabled = 1
    t.save!
    c = create_claim_media
    p = create_project team: t
    pm = nil
    stub_config('keep_token', '123456') do
      pm = create_project_media project: p, media: c
    end
    assert_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should not send media to Keep if Keep is not enabled for team" do
    t = create_team
    l = create_link
    p = create_project team: t
    pm = nil
    stub_config('keep_token', '123456') do
      pm = create_project_media project: p, media: l
    end
    assert_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should not send media to Keep if there is no Keep key in the config" do
    t = create_team
    t.keep_enabled = 1
    t.save!
    l = create_link
    p = create_project team: t
    pm = nil
    stub_config('keep_token', nil) do
      pm = create_project_media project: p, media: l
    end
    assert_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should re-send media to Keep" do
    t = create_team
    t.keep_enabled = 1
    t.save!
    l = create_link
    p = create_project team: t
    pm = nil
    stub_config('keep_token', '123456') do
      pm = create_project_media project: p, media: l
    end
    assert_nothing_raised do
      pm.update_keep = 1
    end
  end

  test "should sent to Keep and re-try" do
    t = create_team
    t.keep_enabled = 1
    t.save!
    l = create_link
    p = create_project team: t
    pm = nil
    stub_config('keep_token', '123456') do
      Sidekiq::Testing.inline! do
        pm = create_project_media project: p, media: l
      end
    end
  end
end
