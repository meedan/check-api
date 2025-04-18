require_relative '../test_helper'

class ProjectMedia8Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Worker.clear_all
  end

  def teardown
  end

  test "when creating an item with tag/tags, after_create :create_tags_in_background callback should create tags in the background" do
    Sidekiq::Testing.inline!

    team = create_team
    project = create_project team: team
    pm = create_project_media project: project, tags: ['one']

    assert_equal 1, pm.annotations('tag').count
  end

  test "when creating an item with multiple tags, after_create :create_tags_in_background callback should only schedule one job" do
    Sidekiq::Testing.fake!

    team = create_team
    project = create_project team: team

    assert_nothing_raised do
      create_project_media project: project, tags: ['one', 'two', 'three']
    end
    assert_equal 1, GenericWorker.jobs.size
  end

  test "when creating an item with multiple tags, after_create :create_tags_in_background callback should not create duplicate tags" do
    Sidekiq::Testing.inline!

    team = create_team
    project = create_project team: team
    pm = create_project_media project: project, tags: ['one', 'one', '#one']

    assert_equal 1, pm.annotations('tag').count
  end

  test "should verify n + 1 for deduplicated TiplineRequest(CV2-5464)" do
    t = create_team
    pm = create_project_media team: t
    pm2 = create_project_media team: t
    pm3 = create_project_media team: t
    create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    [pm, pm2, pm3].each do |ass|
      create_tipline_request team_id: t.id, associated: ass
    end
    assert_queries(4, '=') {
      pm.get_deduplicated_tipline_requests
    }
    # Should add a new item for related_items_ids and got same queries count
    create_relationship source_id: pm.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
    [pm, pm2, pm3].each do |ass|
      create_tipline_request team_id: t.id, associated: ass
    end
    assert_queries(4, '=') {
      pm.get_deduplicated_tipline_requests
    }
  end

  test "should set media origin information" do
    Sidekiq::Testing.fake!
    Team.current = User.current = nil

    t = create_team
    u1 = create_user
    u2 = create_user
    u3 = create_user

    # TIPLINE_SUBMITTED
    b1 = create_bot_user login: 'smooch', name: 'Smooch', approved: true
    b2 = create_bot_user login: 'alegre', name: 'Alegre', approved: true
    pm1 = create_project_media team: t, user: b1
    assert_equal CheckMediaClusterOrigins::OriginCodes::TIPLINE_SUBMITTED, pm1.media_cluster_origin(true)
    assert_equal pm1.created_at.to_i, pm1.media_cluster_origin_timestamp(true)
    assert_equal b1.id, pm1.media_cluster_origin_user_id(true)

    # USER_ADDED
    pm2 = create_project_media team: t, user: u1
    assert_equal CheckMediaClusterOrigins::OriginCodes::USER_ADDED, pm2.media_cluster_origin(true)
    assert_equal pm2.created_at.to_i, pm2.media_cluster_origin_timestamp(true)
    assert_equal u1.id, pm2.media_cluster_origin_user_id(true)

    # USER_MERGED
    r1 = create_relationship source: pm1, target: pm2, user: u2
    assert_equal CheckMediaClusterOrigins::OriginCodes::TIPLINE_SUBMITTED, pm1.media_cluster_origin(true)
    assert_equal pm1.created_at.to_i, pm1.media_cluster_origin_timestamp(true)
    assert_equal b1.id, pm1.media_cluster_origin_user_id(true)
    assert_equal CheckMediaClusterOrigins::OriginCodes::USER_MERGED, pm2.media_cluster_origin(true)
    assert_equal r1.created_at.to_i, pm2.media_cluster_origin_timestamp(true)
    assert_equal u2.id, pm2.media_cluster_origin_user_id(true)

    # USER_MATCHED
    pm3 = create_project_media team: t, user: u1
    r2 = create_relationship source: pm1, target: pm3, user: b2, confirmed_at: Time.now, confirmed_by: u3.id
    assert_equal CheckMediaClusterOrigins::OriginCodes::TIPLINE_SUBMITTED, pm1.media_cluster_origin(true)
    assert_equal pm1.created_at.to_i, pm1.media_cluster_origin_timestamp(true)
    assert_equal b1.id, pm1.media_cluster_origin_user_id(true)
    assert_equal CheckMediaClusterOrigins::OriginCodes::USER_MATCHED, pm3.media_cluster_origin(true)
    assert_equal r2.confirmed_at.to_i, pm3.media_cluster_origin_timestamp(true)
    assert_equal u3.id, pm3.media_cluster_origin_user_id(true)

    # AUTO_MATCHED (Alegre)
    pm4 = create_project_media team: t, user: u1
    r3 = create_relationship source: pm1, target: pm4, user: b2
    assert_equal CheckMediaClusterOrigins::OriginCodes::TIPLINE_SUBMITTED, pm1.media_cluster_origin(true)
    assert_equal pm1.created_at.to_i, pm1.media_cluster_origin_timestamp(true)
    assert_equal b1.id, pm1.media_cluster_origin_user_id(true)
    assert_equal CheckMediaClusterOrigins::OriginCodes::AUTO_MATCHED, pm4.media_cluster_origin(true)
    assert_equal r3.created_at.to_i, pm4.media_cluster_origin_timestamp(true)
    assert_equal b2.id, pm4.media_cluster_origin_user_id(true)

    # AUTO_MATCHED (Smooch)
    pm5 = create_project_media team: t, user: u1
    r4 = create_relationship source: pm1, target: pm5, user: b1
    assert_equal CheckMediaClusterOrigins::OriginCodes::TIPLINE_SUBMITTED, pm1.media_cluster_origin(true)
    assert_equal pm1.created_at.to_i, pm1.media_cluster_origin_timestamp(true)
    assert_equal b1.id, pm1.media_cluster_origin_user_id(true)
    assert_equal CheckMediaClusterOrigins::OriginCodes::AUTO_MATCHED, pm5.media_cluster_origin(true)
    assert_equal r4.created_at.to_i, pm5.media_cluster_origin_timestamp(true)
    assert_equal b1.id, pm5.media_cluster_origin_user_id(true)
  end

  test "should get tipline_requests that never received articles" do
    t = create_team
    pm = create_project_media team: t
    assert_not pm.has_tipline_requests_that_never_received_articles
    tr_1a = create_tipline_request team_id: t.id, associated: pm
    tr_1b = create_tipline_request team_id: t.id, associated: pm
    assert pm.has_tipline_requests_that_never_received_articles
    Time.stubs(:now).returns(Time.new - 7.days)
    tr_7a = create_tipline_request team_id: t.id, associated: pm
    tr_7b = create_tipline_request team_id: t.id, associated: pm
    Time.unstub(:now)
    assert pm.has_tipline_requests_that_never_received_articles
    Time.stubs(:now).returns(Time.new - 30.days)
    tr_30a = create_tipline_request team_id: t.id, associated: pm
    tr_30b = create_tipline_request team_id: t.id, associated: pm
    Time.unstub(:now)
    Time.stubs(:now).returns(Time.new - 2.months)
    create_tipline_request team_id: t.id, associated: pm
    Time.unstub(:now)
    assert pm.has_tipline_requests_that_never_received_articles
    data = pm.number_of_tipline_requests_that_never_received_articles_by_time
    expected_result = { 1 => 2, 7 => 2, 30 => 4 }
    assert_equal expected_result, data
    tr_1a.smooch_request_type = 'relevant_search_result_requests'
    tr_1a.save!
    tr_7a.smooch_request_type = 'irrelevant_search_result_requests'
    tr_7a.save!
    tr_30a.smooch_request_type = 'timeout_search_requests'
    tr_30a.save!
    assert pm.has_tipline_requests_that_never_received_articles
    data = pm.number_of_tipline_requests_that_never_received_articles_by_time
    expected_result = { 1 => 1, 7 => 1, 30 => 2 }
    assert_equal expected_result, data
    tr_1b.smooch_report_update_received_at = Time.now.to_i
    tr_1b.save!
    tr_7b.smooch_report_sent_at = Time.now.to_i
    tr_7b.save!
    tr_30b.smooch_report_correction_sent_at = Time.now.to_i
    tr_30b.save!
    assert_not pm.has_tipline_requests_that_never_received_articles
    data = pm.number_of_tipline_requests_that_never_received_articles_by_time
    expected_result = { 1 => 0, 7 => 0, 30 => 0 }
    assert_equal expected_result, data
  end

  test "should have a fallback when trying to create a blank item with original claim but a timeout error happens" do
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}|httpstat\.us/
    WebMock.stub_request(:head, /httpstat\.us/).to_return(status: 200, headers: { 'Content-Type' => 'image/png' })
    image_data = File.read(File.join(Rails.root, 'test', 'data', 'rails.png'))
    Net::HTTPOK.any_instance.stubs(:body).returns(image_data)

    stub_configs({ 'short_request_timeout' => 5 }) do
      url = 'https://httpstat.us/200?sleep=10000'
      pm = create_project_media set_original_claim: url, media: Blank.create!
      assert_equal 'Claim', pm.media.type
      assert_equal url, pm.media.quote

      url = 'https://httpstat.us/200?sleep=2000'
      pm = create_project_media set_original_claim: url, media: Blank.create!
      assert_equal 'UploadedImage', pm.media.type
      assert_equal Digest::MD5.hexdigest(image_data), Digest::MD5.hexdigest(pm.media.file.file.read)
    end
  end
end
