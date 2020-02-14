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
    create_annotation_type_and_fields('Metadata', { 'Value' => ['JSON', false] })
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
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_keep_backup_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_keep_backup_enabled = true
    tbi.save!
    l = create_link
    p = create_project team: t
    pm = create_project_media project: p, media: l
    assert_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "keep_backup_response").count' do
        pm.create_all_archive_annotations
      end
    end
  end

  test "should not create Keep annotations if media is not a link" do
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_keep_backup_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_keep_backup_enabled = true
    tbi.save!
    c = create_claim_media
    p = create_project team: t
    pm = create_project_media project: p, media: c
    assert_no_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_no_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "keep_backup_response").count' do
        pm.create_all_archive_annotations
      end
    end
  end

  test "should create Keep annotations when bot runs" do
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_keep_backup_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_keep_backup_enabled = true
    tbi.save!
    l = create_link
    p = create_project team: t
    pm = create_project_media project: p, media: l
    u = create_user is_admin: true
    assert_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "keep_backup_response").count' do
        Bot::Keep.run({ data: { dbid: pm.id }, user_id: u.id })
      end
    end
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

  test "should update metrics" do
    RequestStore.store[:skip_cached_field_update] = false
    create_annotation_type_and_fields('Metrics', { 'Data' => ['JSON', false] })
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    pm = create_project_media media: nil, url: url
    payload = { type: 'metrics', url: url, metrics: { facebook: { share_count: 123 } } }.to_json
    request = OpenStruct.new(raw_post: nil)
    request.raw_post = payload
    assert_difference "Dynamic.where(annotation_type: 'metrics').count" do
      Bot::Keep.webhook(request)
    end
    data = JSON.parse(pm.reload.get_annotations('metrics').last.load.get_field_value('metrics_data'))
    assert_equal({ 'facebook' => { 'share_count' => 123 } }, data)
    assert_equal 123, pm.reload.share_count
    payload = { type: 'metrics', url: url, metrics: { facebook: { share_count: 321, comments_count: 456 }, twitter: { retweet_count: 789 } } }.to_json
    request = OpenStruct.new(raw_post: nil)
    request.raw_post = payload
    assert_no_difference "Dynamic.where(annotation_type: 'metrics').count" do
      Bot::Keep.webhook(request)
    end
    data = JSON.parse(pm.reload.get_annotations('metrics').last.load.get_field_value('metrics_data'))
    assert_equal({ 'facebook' => { 'share_count' => 321, 'comments_count' => 456 }, 'twitter' => { 'retweet_count' => 789 } }, data)
    assert_equal 321, pm.reload.share_count
  end
end
