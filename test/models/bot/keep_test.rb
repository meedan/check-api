require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::KeepTest < ActiveSupport::TestCase
  def setup
    super
    DeviseMailer.any_instance.stubs(:confirmation_instructions)
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

  def teardown
    super
    DeviseMailer.any_instance.unstub(:confirmation_instructions)
  end

  test "should exist" do
    assert_kind_of Bot::Keep, @bot
  end

  test "should create Keep annotations" do
    t = create_team
    t.set_limits_keep = true
    t.save!
    TeamBot.delete_all
    tb = create_team_bot identifier: 'keep', settings: [{ name: 'archive_keep_backup_enabled', type: 'boolean' }], approved: true
    tbi = create_team_bot_installation team_bot_id: tb.id, team_id: t.id
    tbi.set_archive_keep_backup_enabled = true
    tbi.save!
    l = create_link
    p = create_project team: t
    pm = create_project_media project: p, media: l
    pm.create_all_archive_annotations
    assert_not_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should not create Keep annotations if media is not a link" do
    t = create_team
    t.set_limits_keep = true
    t.save!
    TeamBot.delete_all
    tb = create_team_bot identifier: 'keep', settings: [{ name: 'archive_keep_backup_enabled', type: 'boolean' }], approved: true
    tbi = create_team_bot_installation team_bot_id: tb.id, team_id: t.id
    tbi.set_archive_keep_backup_enabled = true
    tbi.save!
    c = create_claim_media
    p = create_project team: t
    pm = create_project_media project: p, media: c
    pm.create_all_archive_annotations
    assert_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should not create Keep annotations if team is not allowed to" do
    t = create_team
    t.set_limits_keep = false
    t.save!
    TeamBot.delete_all
    tb = create_team_bot identifier: 'keep', settings: [{ name: 'archive_keep_backup_enabled', type: 'boolean' }], approved: true
    tbi = create_team_bot_installation team_bot_id: tb.id, team_id: t.id
    tbi.set_archive_keep_backup_enabled = true
    tbi.save!
    l = create_link
    p = create_project team: t
    pm = create_project_media project: p, media: l
    pm.create_all_archive_annotations
    assert_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should create Keep annotations when bot runs" do
    t = create_team
    t.set_limits_keep = true
    t.save!
    TeamBot.delete_all
    tb = create_team_bot identifier: 'keep', settings: [{ name: 'archive_keep_backup_enabled', type: 'boolean' }], approved: true
    tbi = create_team_bot_installation team_bot_id: tb.id, team_id: t.id
    tbi.set_archive_keep_backup_enabled = true
    tbi.save!
    l = create_link
    p = create_project team: t
    pm = create_project_media project: p, media: l
    u = create_user is_admin: true
    Bot::Keep.run({ data: { dbid: pm.id }, user_id: u.id }.to_json)
    assert_not_nil pm.annotations.where(annotation_type: 'keep_backup').last
  end

  test "should parse webhook payload" do
    payload = { foo: 'bar' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    request = OpenStruct.new(headers: {}, env: {}, raw_post: nil)
    request.headers['X-Signature'] = sig
    request.raw_post = payload
    assert Bot::Keep.valid_request?(request)
  end

  test "should return authentication error when parsing webhook" do
    payload = { foo: 'bar' }.to_json
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), 'invalid_token', payload)
    request = OpenStruct.new(headers: {}, env: {}, raw_post: nil)
    request.headers['X-Signature'] = sig
    request.raw_post = payload
    assert !Bot::Keep.valid_request?(request)
  end

  test "should return unknown error when parsing webhook" do
    payload = nil
    sig = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), 'invalid_token', payload.to_s)
    request = OpenStruct.new(headers: {}, env: {}, raw_post: nil)
    request.headers['X-Signature'] = sig
    request.raw_post = payload
    assert !Bot::Keep.valid_request?(request)
  end
end
