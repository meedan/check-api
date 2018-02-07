require_relative '../../test_helper'
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
    WebMock.stub_request(:post, /#{Regexp.escape(CONFIG['bridge_reader_url_private'])}.*/) unless CONFIG['bridge_reader_url_private'].blank?
  end

  test "should exist" do
    assert_kind_of Bot::Keep, @bot
  end

  test "should create Keep annotations" do
    t = create_team
    t.archive_keep_backup_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    l = create_link
    p = create_project team: t
    pm = create_project_media project: p, media: l
    assert_not_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should not create Keep annotations if media is not a link" do
    t = create_team
    t.archive_keep_backup_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    c = create_claim_media
    p = create_project team: t
    pm = create_project_media project: p, media: c
    assert_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should not create Keep annotations if team is not allowed to" do
    t = create_team
    t.archive_keep_backup_enabled = 1
    t.set_limits_keep_screenshot = false
    t.save!
    l = create_link
    p = create_project team: t
    pm = create_project_media project: p, media: l
    assert_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should not create Keep annotations if archiver is not enabled" do
    t = create_team
    t.archive_keep_backup_enabled = 0
    t.set_limits_keep_screenshot = true
    t.save!
    l = create_link
    p = create_project team: t
    pm = create_project_media project: p, media: l
    assert_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end
end
