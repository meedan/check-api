require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::FetchTest < ActiveSupport::TestCase
  def setup
    super
    BotUser.delete_all
    Sidekiq::Testing.inline!
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
    User.unstub(:current)
    Team.unstub(:current)

    @claim_review = {
      "identifier": "123",
      "@context": "http://schema.org",
      "@type": "ClaimReview",
      "datePublished": "2020-01-10",
      "url": "https://external.site/claim_review",
      "author": {
        "name": "The Author",
        "url": nil
      },
      "claimReviewed": "Earth isn&#39;t flat",
      "text": "<p>Scientific evidences show that <b>Earth</b> is round</p>",
      "image": "https://external.site/image.png",
      "reviewRating": {
        "@type": "Rating",
        "ratingValue": 0,
        "bestRating": 1,
        "alternateName": "False"
      }
    }.with_indifferent_access

    stub_configs({ 'fetch_url' => 'http://fetch:8000', 'fetch_token' => 'test', 'fetch_check_webhook_url' => 'http://check:3100' }, false)
    WebMock.stub_request(:get, 'https://external.site/image.png').to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    WebMock.stub_request(:get, 'http://fetch:8000/services').to_return(body: { services: [{ service: 'test', count: 1, earliest: '2017-08-02', latest: '2017-08-05' }, { service: 'foo', count: 0, earliest: nil, latest: nil }]}.to_json)
    WebMock.stub_request(:post, 'http://fetch:8000/subscribe').with(body: { service: 'test', url: 'http://check:3100/api/webhooks/fetch?team=fetch&token=test', language: nil }.to_json).to_return(body: '{}')
    WebMock.stub_request(:get, 'http://fetch:8000/claim_reviews?end_time=2017-08-06&include_raw=false&offset=0&per_page=100&service=test&start_time=2017-08-01').to_return(body: [@claim_review].to_json)
    WebMock.stub_request(:get, 'http://fetch:8000/claim_reviews?end_time=2017-08-11&include_raw=false&offset=0&per_page=100&service=test&start_time=2017-08-06').to_return(body: [@claim_review].to_json)
    WebMock.stub_request(:post, 'http://fetch:8000/subscribe').with(body: { service: 'foo', url: 'http://check:3100/api/webhooks/fetch?team=fetch&token=test', language: nil }.to_json).to_return(body: '{}')
    WebMock.stub_request(:delete, 'http://fetch:8000/subscribe').with(body: { service: 'test', url: 'http://check:3100/api/webhooks/fetch?team=fetch&token=test'}.to_json).to_return(body: '{}')
    WebMock.stub_request(:post, 'http://alegre:3100/similarity/sync/text').to_return(body: {}.to_json)
    WebMock.stub_request(:delete, 'http://alegre:3100/text/similarity/').to_return(body: {}.to_json)
    
    create_verification_status_stuff
    create_report_design_annotation_type
    @team = create_team slug: 'fetch'
    settings = [
      { name: 'fetch_service_name', label: 'Fetch Service Name', type: 'readonly', default: '' },
      { name: 'status_fallback', label: 'Status Fallback (Check status identifier)', type: 'readonly', default: '' },
      { name: 'status_mapping', label: 'Status Mapping (JSON where key is a reviewRating.ratingValue and value is a Check status identifier)', type: 'readonly', default: '' }
    ]
    @bot = create_team_bot name: 'Fetch', set_role: 'editor', login: 'fetch', set_approved: true, set_settings: settings, set_events: [], set_request_url: "#{CheckConfig.get('fetch_check_webhook_url')}/api/bots/fetch"
    @settings = {
      'fetch_service_name' => 'test',
      'status_fallback' => 'in_progress',
      'status_mapping' => {
        'False' => 'false',
        'True' => 'verified'
      }.to_json
    }
    @installation = create_team_bot_installation user_id: @bot.id, settings: @settings, team_id: @team.id
  end

  test "should not install bot if service is not supported" do
    assert_raises ActiveRecord::RecordInvalid do
      @installation.set_fetch_service_name 'bar'
      @installation.save!
    end
  end

  test "should unsubscribe when service changes" do
    assert_nothing_raised do
      @installation.set_fetch_service_name 'foo'
      @installation.save!
    end
  end

  test "should process webhook" do
    RequestStore.store[:skip_cached_field_update] = false
    claim_review = @claim_review.clone
    claim_review['identifier'] = random_string
    request = OpenStruct.new(query_parameters: { 'team' => 'fetch' }, params: { 'claim_review' => claim_review })
    assert_difference "ProjectMedia.where(team_id: #{@team.id}).count" do
      assert Bot::Fetch.webhook(request)
    end
    pm = ProjectMedia.last
    data = { "main" => CheckChannels::ChannelCodes::FETCH }
    assert_equal data, pm.channel
  end

  # This test to reproduce errbit error #CHECK-166
  test "should handle es error" do
    setup_elasticsearch
    create_report_design_annotation_type
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Worker.drain_all
    Sidekiq::Testing.fake! do
      claim_review = @claim_review.clone
      claim_review['identifier'] = random_string
      request = OpenStruct.new(query_parameters: { 'team' => 'fetch' }, params: { 'claim_review' => claim_review })
      assert Bot::Fetch.webhook(request)
      assert_difference "ProjectMedia.where(team_id: #{@team.id}).count" do
        Sidekiq::Worker.drain_all
      end
    end
    pm = ProjectMedia.last
    result = $repository.find(get_es_id(pm))
    assert_equal pm.media.type, result['associated_type']
    assert_equal pm.original_title, result['title']
    assert_equal "Earth isn't flat", pm.title
  end

  test "should not process webhook if an exception happens" do
    claim_review = @claim_review.clone
    claim_review['identifier'] = random_string
    @installation.set_status_mapping 'not a JSON'
    @installation.save!
    request = OpenStruct.new(query_parameters: { 'team' => 'fetch' }, params: { 'claim_review' => claim_review })
    assert_no_difference "ProjectMedia.where(team_id: #{@team.id}).count" do
      assert !Bot::Fetch.webhook(request)
    end
  end

  test "should validate request" do
    request = OpenStruct.new(query_parameters: { 'team' => 'fetch', 'token' => 'test' }, body: OpenStruct.new(read: @claim_review.to_json))
    assert Bot::Fetch.valid_request?(request)
    request = OpenStruct.new(query_parameters: { 'team' => random_string, 'token' => 'test' }, body: OpenStruct.new(read: @claim_review.to_json))
    assert !Bot::Fetch.valid_request?(request)
    request = OpenStruct.new(query_parameters: { 'team' => create_team.slug, 'token' => 'test' }, body: OpenStruct.new(read: @claim_review.to_json))
    assert !Bot::Fetch.valid_request?(request)
    request = OpenStruct.new(query_parameters: { 'token' => 'test' }, body: OpenStruct.new(read: @claim_review.to_json))
    assert !Bot::Fetch.valid_request?(request)
    request = OpenStruct.new(query_parameters: { 'team' => 'fetch' }, body: OpenStruct.new(read: @claim_review.to_json))
    assert !Bot::Fetch.valid_request?(request)
    request = OpenStruct.new(query_parameters: { 'team' => 'fetch', 'token' => random_string }, body: OpenStruct.new(read: @claim_review.to_json))
    assert !Bot::Fetch.valid_request?(request)
  end

  test "should get subscriptions" do
    WebMock.stub_request(:get, 'http://fetch:8000/subscribe?service=bar').to_return(body: '[]')
    assert_equal [], Bot::Fetch.subscriptions('bar')
  end

  test "should get installation for team" do
    assert_equal @installation, Bot::Fetch.get_installation_for_team('fetch')
    assert_nil Bot::Fetch.get_installation_for_team(random_string)
  end

  test "should set service" do
    Bot::Fetch.set_service('fetch', 'foo', 'undetermined', {})
    assert_equal ['foo'], @installation.reload.get_fetch_service_name
    assert_equal 'undetermined', @installation.reload.get_status_fallback
    assert_equal '{}', @installation.reload.get_status_mapping
  end

  test "should get webhook URL" do
    assert_equal 'http://check:3100/api/webhooks/fetch?team=fetch&token=test', Bot::Fetch.webhook_url(@team)
  end


end