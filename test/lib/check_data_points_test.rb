require_relative '../test_helper'

class CheckDataPointsTest < ActiveSupport::TestCase
  def setup
    @team = create_team
    @team2 = create_team
    @start_date = (Time.now - 1.month).strftime("%Y-%m-%d")
    @end_date = (Time.now + 1.month).strftime("%Y-%m-%d")
  end

  def teardown
  end

  test "should calculate tipline messages" do
    create_tipline_message team_id: @team.id
    create_tipline_message team_id: @team.id
    create_tipline_message team_id: @team2.id
    Time.stubs(:now).returns(Time.new - 2.months)
    create_tipline_message team_id: @team.id
    Time.unstub(:now)
    assert_equal 2, CheckDataPoints.tipline_messages(@team.id, @start_date, @end_date)
    assert_equal 1, CheckDataPoints.tipline_messages(@team2.id, @start_date, @end_date)
    from = (Time.now - 4.month).strftime("%Y-%m-%d")
    assert_equal 3, CheckDataPoints.tipline_messages(@team.id, from, @end_date)
  end

  test "should calculate tipline requests, articles sent and average response time" do
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team
    tr = create_tipline_request team_id: @team.id, associated: pm
    create_tipline_request team_id: @team.id, associated: pm, smooch_request_type: 'relevant_search_result_requests'
    create_tipline_request team_id: @team.id, associated: pm, smooch_request_type: 'irrelevant_search_result_requests'
    create_tipline_request team_id: @team.id, associated: pm, smooch_request_type: 'timeout_search_requests'
    create_tipline_request team_id: @team.id, associated: pm, smooch_request_type: 'relevant_search_result_requests'
    create_tipline_request team_id: @team2.id, associated: pm2
    Time.stubs(:now).returns(Time.new - 2.months)
    create_tipline_request team_id: @team.id, associated: pm
    create_tipline_request team_id: @team.id, associated: pm, smooch_request_type: 'relevant_search_result_requests'
    create_tipline_request team_id: @team2.id, associated: pm2
    Time.unstub(:now)
    # Verify all tipline requests
    assert_equal 5, CheckDataPoints.tipline_requests(@team.id, @start_date, @end_date)
    assert_equal 1, CheckDataPoints.tipline_requests(@team2.id, @start_date, @end_date)
    # Verify granularity
    from = (Time.now - 4.month).strftime("%Y-%m-%d")
    result_g = CheckDataPoints.tipline_requests(@team.id, from, @end_date, 'month')
    assert_equal [2, 5], result_g.values.sort
    # Verify tipline requests by search_type
    result = CheckDataPoints.tipline_requests_by_search_type(@team.id, @start_date, @end_date)
    actual = { "irrelevant_search_result_requests" => 1, "relevant_search_result_requests" => 2, "timeout_search_requests" => 1 }
    assert_equal actual, result
    result = CheckDataPoints.tipline_requests_by_search_type(@team.id, from, @end_date)
    actual = { "irrelevant_search_result_requests" => 1, "relevant_search_result_requests" => 3, "timeout_search_requests" => 1 }
    assert_equal actual, result
    # Verify articles sent
    time_i = Time.now.to_i
    create_tipline_request team_id: @team.id, associated: pm, smooch_report_received_at: time_i
    create_tipline_request team_id: @team.id, associated: pm, smooch_report_update_received_at: time_i
    create_tipline_request team_id: @team.id, associated: pm, smooch_report_sent_at: time_i
    create_tipline_request team_id: @team.id, associated: pm, smooch_report_correction_sent_at: time_i
    assert_equal 8, CheckDataPoints.articles_sent(@team.id, @start_date, @end_date)
    # Verify average response time
    tr.smooch_report_received_at = time_i
    tr.save!
    assert_not_nil CheckDataPoints.average_response_time(@team.id, @start_date, @end_date)
  end

  test "should calculate tipline subscriptions" do
    create_tipline_subscription team_id: @team.id
    create_tipline_subscription team_id: @team.id
    create_tipline_subscription team_id: @team2.id
    Time.stubs(:now).returns(Time.new - 2.months)
    create_tipline_subscription team_id: @team.id
    Time.unstub(:now)
    assert_equal 2, CheckDataPoints.tipline_subscriptions(@team.id, @start_date, @end_date)
    assert_equal 1, CheckDataPoints.tipline_subscriptions(@team2.id, @start_date, @end_date)
    from = (Time.now - 4.month).strftime("%Y-%m-%d")
    assert_equal 3, CheckDataPoints.tipline_subscriptions(@team.id, from, @end_date)
  end

  test "should calculate newsletters sent" do
    newsletter = create_tipline_newsletter team: @team
    newsletter2 = create_tipline_newsletter team: @team2
    create_tipline_newsletter_delivery tipline_newsletter: newsletter
    create_tipline_newsletter_delivery tipline_newsletter: newsletter
    create_tipline_newsletter_delivery tipline_newsletter: newsletter2
    Time.stubs(:now).returns(Time.new - 2.months)
    create_tipline_newsletter_delivery tipline_newsletter: newsletter
    create_tipline_newsletter_delivery tipline_newsletter: newsletter2
    Time.unstub(:now)
    assert_equal 2, CheckDataPoints.newsletters_sent(@team.id, @start_date, @end_date)
    assert_equal 1, CheckDataPoints.newsletters_sent(@team2.id, @start_date, @end_date)
    from = (Time.now - 4.month).strftime("%Y-%m-%d")
    assert_equal 3, CheckDataPoints.newsletters_sent(@team.id, from, @end_date)
    result_g = CheckDataPoints.newsletters_sent(@team.id, from, @end_date, 'month')
    assert_equal [1, 2], result_g.values.sort
  end

  test "should calculate media_received_by_type" do
    bot = create_team_bot login: 'smooch', name: 'Smooch', set_approved: true
    create_project_media team: @team, user: bot, media: create_claim_media
    create_project_media team: @team, user: bot, media: create_claim_media
    create_project_media team: @team, user: bot, media: create_link
    create_project_media team: @team, user: bot, media: create_uploaded_image
    create_project_media team: @team2, user: bot, media: create_claim_media
    Time.stubs(:now).returns(Time.new - 2.months)
    create_project_media team: @team, user: bot, media: create_claim_media
    Time.unstub(:now)
    result = CheckDataPoints.media_received_by_type(@team.id, @start_date, @end_date)
    actual = { "Claim" => 2, "Link" => 1, "UploadedImage" =>1 }
    assert_equal actual, result
    result = CheckDataPoints.media_received_by_type(@team2.id, @start_date, @end_date)
    actual = { "Claim" => 1}
    assert_equal actual, result
    from = (Time.now - 4.month).strftime("%Y-%m-%d")
    result = CheckDataPoints.media_received_by_type(@team.id, from, @end_date)
    actual = { "Claim" => 3, "Link" => 1, "UploadedImage" =>1 }
    assert_equal actual, result
  end

  test "should calculate top clusters and top media tags" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media team: @team, disable_es_callbacks: false
    create_tipline_request team: @team.id, associated: pm
    pm2 = create_project_media team: @team, disable_es_callbacks: false
    3.times { create_tipline_request(team_id: @team.id, associated: pm2) }
    pm3 = create_project_media team: @team, disable_es_callbacks: false
    2.times { create_tipline_request(team_id: @team.id, associated: pm3) }
    pm4 = create_project_media team: @team, disable_es_callbacks: false
    4.times { create_tipline_request(team_id: @team.id, associated: pm4) }
    pm5 = create_project_media team: @team, disable_es_callbacks: false
    sleep 2
    # Verify top clusters
    result = CheckDataPoints.top_clusters(@team.id, @start_date, @end_date)
    actual = { pm4.id => 4, pm2.id => 3, pm3.id => 2, pm.id => 1 }
    assert_equal actual, result
    # Verify top media tags
    create_tipline_request team: @team.id, associated: pm5
    create_tag annotated: pm2, disable_es_callbacks: false
    create_tag annotated: pm3, disable_es_callbacks: false
    create_tag annotated: pm5, disable_es_callbacks: false
    sleep 2
    result = CheckDataPoints.top_media_tags(@team.id, @start_date, @end_date)
    actual = { pm2.id => 3, pm3.id => 2, pm5.id => 1 }
    assert_equal actual, result
  end

  test "should calculate users" do
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false] })
    pm = create_project_media team: @team
    author_id = random_string
    author_id2 = random_string
    smooch_data = { language: 'en', authorId: author_id, source: { type: 'whatsapp' } }
    create_tipline_request team_id: @team.id, smooch_data: smooch_data
    create_tipline_request team_id: @team.id, smooch_data: smooch_data
    create_tipline_request team_id: @team.id
    smooch_data[:authorId] = author_id2
    create_tipline_request team_id: @team.id, smooch_data: smooch_data
    create_tipline_request team_id: @team.id, smooch_data: smooch_data
    create_tipline_request team_id: @team2.id
    Time.stubs(:now).returns(Time.new - 3.months)
    create_tipline_request team_id: @team.id, associated: pm, smooch_data: smooch_data
    Time.unstub(:now)
    # All users
    assert_equal 3, CheckDataPoints.all_users(@team.id, @start_date, @end_date)
    # returning_users
    assert_equal 1, CheckDataPoints.returning_users(@team.id, @start_date, @end_date)
    # new_users
    create_dynamic_annotation annotated: @team, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string }.to_json
    create_dynamic_annotation annotated: @team, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string }.to_json
    Time.stubs(:now).returns(Time.new - 3.months)
    create_dynamic_annotation annotated: @team, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string }.to_json
    Time.unstub(:now)
    assert_equal 2, CheckDataPoints.new_users(@team.id, @start_date, @end_date)
  end

  test "should calculate average response time based also on custom manual messages" do
    travel_to Time.parse('2025-02-01').beginning_of_day do
      pm = create_project_media team: @team
      tr = create_tipline_request team_id: @team.id, associated: pm
      tr.update_columns(first_manual_response_at: (tr.created_at + 1.week).to_i, smooch_report_sent_at: (tr.created_at + 2.weeks).to_i)
      tr = create_tipline_request team_id: @team.id, associated: pm
      tr.update_columns(first_manual_response_at: (tr.created_at + 2.weeks).to_i, smooch_report_sent_at: (tr.created_at + 1.week).to_i)
      assert_equal 7, (CheckDataPoints.average_response_time(@team.id, '2025-01-01', '2025-03-01').to_i / (24 * 60 * 60)).to_i # 7 days
    end
  end
end
