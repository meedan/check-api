require_relative '../test_helper'

class TeamStatisticsTest < ActiveSupport::TestCase
  def setup
    Sidekiq::Testing.fake!    
    WebMock.stub_request(:post, /#{CheckConfig.get('alegre_host')}/).to_return(body: '{}')
    Explainer.delete_all
    @team = create_team
    @team.set_languages = ['en', 'pt']
    @team.save!
  end

  def teardown
  end

  test "should provide a valid period" do
    assert_raises ArgumentError do
      TeamStatistics.new(@team, 'past_century', 'en', 'whatsapp')
    end

    assert_nothing_raised do
      TeamStatistics.new(@team, 'past_month', 'en', 'whatsapp')
    end
  end

  test "should provide a valid workspace" do
    assert_raises ArgumentError do
      TeamStatistics.new(Class.new, 'past_month', 'en', 'whatsapp')
    end

    assert_nothing_raised do
      TeamStatistics.new(@team, 'past_month', 'en', 'whatsapp')
    end
  end

  test "should provide a valid platform" do
    assert_raises ArgumentError do
      TeamStatistics.new(@team, 'past_month', 'en', 'icq')
    end

    assert_nothing_raised do
      TeamStatistics.new(@team, 'past_month', 'en', 'whatsapp')
    end
  end

  test "should have a GraphQL ID" do
    assert_kind_of String, TeamStatistics.new(@team, 'past_month', 'en', 'whatsapp').id
  end

  test "should return articles statistics" do
    team = create_team
    exp = nil

    travel_to Time.parse('2024-01-01') do
      create_fact_check(tags: ['foo', 'bar'], language: 'en', rating: 'false', claim_description: create_claim_description(project_media: create_project_media(team: @team)))
      create_fact_check(tags: ['foo', 'bar'], claim_description: create_claim_description(project_media: create_project_media(team: team)))
      exp = create_explainer team: @team, language: 'en', tags: ['foo']
      create_explainer team: @team, tags: ['foo', 'bar'], language: 'pt'
      create_explainer language: 'en', team: team, tags: ['foo', 'bar']
    end

    travel_to Time.parse('2024-01-02') do
      create_fact_check(tags: ['bar'], report_status: 'published', rating: 'verified', language: 'en', claim_description: create_claim_description(project_media: create_project_media(team: @team)))
      create_fact_check(tags: ['foo', 'bar'], claim_description: create_claim_description(project_media: create_project_media(team: team)))
      create_explainer team: @team, language: 'en', tags: ['foo']
      create_explainer team: @team, tags: ['foo', 'bar'], language: 'pt'
      create_explainer language: 'en', team: team, tags: ['foo', 'bar']
      exp.updated_at = Time.now
      exp.save!
    end

    travel_to Time.parse('2024-01-08') do
      object = TeamStatistics.new(@team, 'past_week', 'en')
      assert_equal({ '2024-01-01' => 2, '2024-01-02' => 2, '2024-01-03' => 0, '2024-01-04' => 0, '2024-01-05' => 0, '2024-01-06' => 0, '2024-01-07' => 0, '2024-01-08' => 0 },
                   object.number_of_articles_created_by_date)
      assert_equal({ '2024-01-01' => 0, '2024-01-02' => 1, '2024-01-03' => 0, '2024-01-04' => 0, '2024-01-05' => 0, '2024-01-06' => 0, '2024-01-07' => 0, '2024-01-08' => 0 },
                   object.number_of_articles_updated_by_date)
      assert_equal 2, object.number_of_explainers_created
      assert_equal 2, object.number_of_fact_checks_created
      assert_equal 1, object.number_of_published_fact_checks
      assert_equal({ 'false' => 1, 'verified' => 1 }, object.number_of_fact_checks_by_rating)
      assert_equal([{ id: 'foo', label: 'foo', value: 3 }, { id: 'bar', label: 'bar', value: 2 }], object.top_articles_tags)
    end
  end

  test "should return number of articles sent" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false

    pm1 = create_project_media team: @team, disable_es_callbacks: false
    fc1 = create_fact_check title: 'Bar', report_status: 'published', rating: 'verified', language: 'en', claim_description: create_claim_description(project_media: pm1), disable_es_callbacks: false
    create_tipline_request team_id: @team.id, associated: pm1

    pm2 = create_project_media team: @team, disable_es_callbacks: false
    fc2 = create_fact_check title: 'Foo', report_status: 'published', rating: 'verified', language: 'en', claim_description: create_claim_description(project_media: pm2), disable_es_callbacks: false
    create_tipline_request team_id: @team.id, associated: pm2
    create_tipline_request team_id: @team.id, associated: pm2

    sleep 2

    object = TeamStatistics.new(@team, 'past_week', 'en')
    expected = [{ id: pm2.fact_check_id, label: 'Foo', value: 2 }, { id: pm1.fact_check_id, label: 'Bar', value: 1 }]
    assert_equal expected, object.top_articles_sent
  end

  test "should return tipline statistics" do
    pm1 = create_project_media team: @team, quote: 'Test'
    create_fact_check claim_description: create_claim_description(project_media: pm1)
    exp = create_explainer team: @team
    pm1.explainers << exp
    team = create_team
    pm2 = create_project_media team: team

    travel_to Time.parse('2024-01-01') do
      2.times { |i| create_tipline_message team_id: @team.id, language: 'en', platform: 'WhatsApp', direction: (i % 2 == 0 ? 'incoming' : 'outgoing') }
      create_tipline_message team_id: @team.id, language: 'en', platform: 'Telegram'
      create_tipline_message team_id: @team.id, language: 'pt', platform: 'WhatsApp'
      create_tipline_message team_id: team.id, language: 'en', platform: 'WhatsApp'

      create_tipline_request team_id: @team.id, associated: pm1, language: 'en', platform: 'whatsapp', smooch_request_type: 'relevant_search_result_requests'
      create_tipline_request team_id: team.id, associated: pm2, language: 'en', platform: 'whatsapp', smooch_request_type: 'relevant_search_result_requests'
      create_tipline_request team_id: @team.id, associated: pm1, language: 'pt', platform: 'whatsapp', smooch_request_type: 'relevant_search_result_requests'
      create_tipline_request team_id: @team.id, associated: pm1, language: 'en', platform: 'telegram', smooch_request_type: 'relevant_search_result_requests'
    end

    travel_to Time.parse('2024-01-03') do
      3.times { |i| create_tipline_message team_id: @team.id, language: 'en', platform: 'WhatsApp', direction: (i % 2 == 0 ? 'incoming' : 'outgoing') }
      create_tipline_message team_id: @team.id, language: 'en', platform: 'Telegram'
      create_tipline_message team_id: @team.id, language: 'pt', platform: 'WhatsApp'
      create_tipline_message team_id: team.id, language: 'en', platform: 'WhatsApp'

      2.times { create_tipline_request team_id: @team.id, associated: pm1, language: 'en', platform: 'whatsapp', smooch_request_type: 'irrelevant_search_result_requests' }
      create_tipline_request team_id: team.id, associated: pm2, language: 'en', platform: 'whatsapp', smooch_request_type: 'relevant_search_result_requests'
      create_tipline_request team_id: @team.id, associated: pm1, language: 'pt', platform: 'whatsapp', smooch_request_type: 'relevant_search_result_requests'
      create_tipline_request team_id: @team.id, associated: pm1, language: 'en', platform: 'telegram', smooch_request_type: 'relevant_search_result_requests'
    end

    travel_to Time.parse('2024-01-08') do
      object = TeamStatistics.new(@team, 'past_week', 'en', 'whatsapp')
      assert_equal 5, object.number_of_messages
      assert_equal 2, object.number_of_outgoing_messages
      assert_equal 3, object.number_of_incoming_messages
      assert_equal({ '2024-01-01' => 2, '2024-01-02' => 0, '2024-01-03' => 3, '2024-01-04' => 0, '2024-01-05' => 0, '2024-01-06' => 0, '2024-01-07' => 0, '2024-01-08' => 0 },
                   object.number_of_messages_by_date)
      assert_equal({ '2024-01-01' => 1, '2024-01-02' => 0, '2024-01-03' => 1, '2024-01-04' => 0, '2024-01-05' => 0, '2024-01-06' => 0, '2024-01-07' => 0, '2024-01-08' => 0 },
                   object.number_of_outgoing_messages_by_date)
      assert_equal({ '2024-01-01' => 1, '2024-01-02' => 0, '2024-01-03' => 2, '2024-01-04' => 0, '2024-01-05' => 0, '2024-01-06' => 0, '2024-01-07' => 0, '2024-01-08' => 0 },
                   object.number_of_incoming_messages_by_date)
      assert_equal 3, object.number_of_conversations
      assert_equal({ '2024-01-01' => 1, '2024-01-02' => 0, '2024-01-03' => 2, '2024-01-04' => 0, '2024-01-05' => 0, '2024-01-06' => 0, '2024-01-07' => 0, '2024-01-08' => 0 },
                   object.number_of_conversations_by_date)
      assert_equal({ 'Positive' => 1, 'Negative' => 2, 'No Response' => 0 }, object.number_of_search_results_by_feedback_type)
      assert_equal({ 'Claim' => 3, 'Link' => 0, 'UploadedAudio' => 0, 'UploadedImage' => 0, 'UploadedVideo' => 0 }, object.number_of_media_received_by_media_type)
      assert_equal 3, object.number_of_articles_sent
      assert_equal({ 'FactCheck' => 3, 'Explainer' => 3 }, object.number_of_matched_results_by_article_type)
    end
  end

  test "should return top requested media clusters" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    channel = CheckChannels::ChannelCodes::WHATSAPP
    Sidekiq::Testing.inline! do
      pm1 = create_project_media team: @team, quote: 'Bar', channel: { main: channel, others: [channel] }, disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm1, platform: 'whatsapp', language: 'en', disable_es_callbacks: false

      pm2 = create_project_media team: @team, quote: 'Foo', channel: { main: channel, others: [channel] }, disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm2, platform: 'whatsapp', language: 'en', disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm2, platform: 'whatsapp', language: 'en', disable_es_callbacks: false

      pm3 = create_project_media team: @team, quote: 'Test 1', channel: { main: 0, others: [0] }, disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm3, platform: 'whatsapp', language: 'en', disable_es_callbacks: false

      pm4 = create_project_media team: @team, quote: 'Test 2', channel: { main: channel, others: [channel] }, disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm4, platform: 'whatsapp', language: 'pt', disable_es_callbacks: false

      sleep 3

      object = TeamStatistics.new(@team, 'past_week', 'en', 'whatsapp')
      expected = [{ id: pm2.id, label: 'Foo', value: 2 }, { id: pm1.id, label: 'Bar', value: 1 }]
      assert_equal expected, object.top_requested_media_clusters
    end
  end

  test "should return top media tags" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    channel = CheckChannels::ChannelCodes::WHATSAPP
    TestDynamicAnnotationTables.load!
    create_annotation_type_and_fields('Language', { 'Language' => ['Text', true] })
    Sidekiq::Testing.inline! do
      pm1 = create_project_media team: @team, channel: { main: channel, others: [channel] }, tags: ['foo', 'bar'], disable_es_callbacks: false
      create_dynamic_annotation annotation_type: 'language', annotated: pm1, set_fields: { language: 'en' }.to_json, disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm1, platform: 'whatsapp', language: 'en', disable_es_callbacks: false

      pm2 = create_project_media team: @team, channel: { main: channel, others: [channel] }, tags: ['foo', 'test'], disable_es_callbacks: false
      create_dynamic_annotation annotation_type: 'language', annotated: pm2, set_fields: { language: 'en' }.to_json, disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm2, platform: 'whatsapp', language: 'en', disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm2, platform: 'whatsapp', language: 'en', disable_es_callbacks: false

      pm3 = create_project_media team: @team, channel: { main: 0, others: [0] }, tags: ['test-1'], disable_es_callbacks: false
      create_dynamic_annotation annotation_type: 'language', annotated: pm3, set_fields: { language: 'en' }.to_json, disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm3, platform: 'whatsapp', language: 'en', disable_es_callbacks: false

      pm4 = create_project_media team: @team, channel: { main: channel, others: [channel] }, tags: ['test-2'], disable_es_callbacks: false
      create_dynamic_annotation annotation_type: 'language', annotated: pm4, set_fields: { language: 'pt' }.to_json, disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm4, platform: 'whatsapp', language: 'pt', disable_es_callbacks: false

      pm5 = create_project_media team: @team, channel: { main: channel, others: [channel] }, disable_es_callbacks: false
      create_dynamic_annotation annotation_type: 'language', annotated: pm5, set_fields: { language: 'en' }.to_json, disable_es_callbacks: false
      create_tipline_request team_id: @team.id, associated: pm4, platform: 'whatsapp', language: 'en', disable_es_callbacks: false

      sleep 3

      object = TeamStatistics.new(@team, 'past_week', 'en', 'whatsapp')
      expected = [{ id: 'foo', label: 'foo', value: 3 }, { id: 'test', label: 'test', value: 2 }, { id: 'bar', label: 'bar', value: 1 }]
      assert_equal expected, object.top_media_tags
    end
  end
end
