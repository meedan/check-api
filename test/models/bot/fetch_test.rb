require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::FetchTest < ActiveSupport::TestCase
  def setup
    super
    BotUser.delete_all
    Sidekiq::Testing.inline!
    WebMock.disable_net_connect! allow: /#{CONFIG['elasticsearch_host']}|#{CONFIG['storage']['endpoint']}/
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
      "claimReviewed": "Earth is not flat",
      "text": "Scientific evidences show that Earth is round",
      "image": "https://external.site/image.png",
      "reviewRating": {
        "@type": "Rating",
        "ratingValue": 0,
        "bestRating": 1,
        "alternateName": "False"
      }
    }.with_indifferent_access

    stub_configs({ 'fetch_url' => 'http://fetch:8000', 'fetch_token' => 'test', 'checkdesk_base_url_private' => 'http://check:5000' }, false)
    WebMock.stub_request(:get, 'https://external.site/image.png').to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    WebMock.stub_request(:get, 'http://fetch:8000/services').to_return(body: { services: [{ service: 'test', count: 1, earliest: '2017-08-09', latest: '2017-08-09' }, { service: 'foo', count: 0, earliest: nil, latest: nil }]}.to_json)
    WebMock.stub_request(:post, 'http://fetch:8000/subscribe.json').with(body: { service: 'test', url: 'http://check:5000/api/webhooks/fetch?team=fetch&token=test' }.to_json).to_return(body: '{}')
    WebMock.stub_request(:get, 'http://fetch:8000/claim_reviews.json?end_time=2017-08-10&per_page=10000&service=test&start_time=2017-08-09').to_return(body: [@claim_review].to_json)
    WebMock.stub_request(:post, 'http://fetch:8000/subscribe.json').with(body: { service: 'foo', url: 'http://check:5000/api/webhooks/fetch?team=fetch&token=test' }.to_json).to_return(body: '{}')
    WebMock.stub_request(:delete, 'http://fetch:8000/subscribe.json').with(body: { service: 'test', url: 'http://check:5000/api/webhooks/fetch?team=fetch&token=test' }.to_json).to_return(body: '{}')
    
    create_verification_status_stuff
    create_report_design_annotation_type
    json_schema = {
      type: 'object',
      required: ['id'],
      properties: {
        id: { type: 'string' }
      }
    }
    create_annotation_type_and_fields('Fetch', {}, json_schema)   
    @team = create_team slug: 'fetch'
    settings = [
      { name: 'fetch_service_name', label: 'Fetch Service Name', type: 'readonly', default: '' },
      { name: 'status_fallback', label: 'Status Fallback (Check status identifier)', type: 'readonly', default: '' },
      { name: 'status_mapping', label: 'Status Mapping (JSON where key is a reviewRating.ratingValue and value is a Check status identifier)', type: 'readonly', default: '' }
    ]
    @bot = create_team_bot name: 'Fetch', login: 'fetch', set_approved: true, set_settings: settings, set_events: [], set_request_url: "#{CONFIG['checkdesk_base_url_private']}/api/bots/fetch"
    @settings = {
      'fetch_service_name' => 'test',
      'status_fallback' => 'in_progress',
      'status_mapping' => {
        '0' => 'false',
        '1' => 'verified'
      }.to_json
    }
    @installation = create_team_bot_installation user_id: @bot.id, settings: @settings, team_id: @team.id
  end

  test "should install bot" do
    t = create_team
    assert_difference 'TeamBotInstallation.count' do
      create_team_bot_installation user_id: @bot.id, team_id: t.id, settings: {}
    end
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
    claim_review = @claim_review.clone
    claim_review['identifier'] = random_string
    request = OpenStruct.new(query_parameters: { 'team' => 'fetch' }, body: OpenStruct.new(read: claim_review.to_json))
    assert_difference "ProjectMedia.where(team_id: #{@team.id}).count" do
      assert Bot::Fetch.webhook(request)
    end
  end

  test "should not process webhook if an exception happens" do
    claim_review = @claim_review.clone
    claim_review['identifier'] = random_string
    @installation.set_status_mapping 'not a JSON'
    @installation.save!
    request = OpenStruct.new(query_parameters: { 'team' => 'fetch' }, body: OpenStruct.new(read: claim_review.to_json))
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
    WebMock.stub_request(:get, 'http://fetch:8000/subscribe.json?service=bar').to_return(body: '[]')
    assert_equal [], Bot::Fetch.subscriptions('bar')
  end

  test "should get installation for team" do
    assert_equal @installation, Bot::Fetch.get_installation_for_team('fetch')
    assert_nil Bot::Fetch.get_installation_for_team(random_string)
  end

  test "should set service" do
    Bot::Fetch.set_service('fetch', 'foo', 'undetermined', {})
    assert_equal 'foo', @installation.reload.get_fetch_service_name
    assert_equal 'undetermined', @installation.reload.get_status_fallback
    assert_equal '{}', @installation.reload.get_status_mapping
  end

  test "should get webhook URL" do
    assert_equal 'http://check:5000/api/webhooks/fetch?team=fetch&token=test', Bot::Fetch.webhook_url(@team)
  end

  test "should import claim reviews with report and correct status and ignore duplicates" do
    cr1 = @claim_review.deep_dup
    cr1['reviewRating']['ratingValue'] = 0
    cr1['identifier'] = 'first'
    cr2 = @claim_review.deep_dup
    cr2['reviewRating']['ratingValue'] = 1
    cr2['identifier'] = 'second'
    cr3 = @claim_review.deep_dup
    cr3['reviewRating']['ratingValue'] = 2
    cr3['identifier'] = 'third'
    WebMock.stub_request(:get, 'http://fetch:8000/services').to_return(body: { services: [{ service: 'foo', count: 4, earliest: '2017-08-09', latest: '2017-08-09' }]}.to_json)
    WebMock.stub_request(:get, 'http://fetch:8000/claim_reviews.json?end_time=2017-08-10&per_page=10000&service=foo&start_time=2017-08-09').to_return(body: [cr1, cr1, cr2, cr3].to_json)
    assert_difference "ProjectMedia.where(team_id: #{@team.id}).count", 3 do
      assert_difference 'Dynamic.where(annotation_type: "report_design").count', 3 do
        assert_difference 'Dynamic.where(annotation_type: "fetch").count', 3 do
          @installation.set_fetch_service_name 'foo'
          @installation.save!
        end
      end
    end
    statuses = ['false', 'verified', 'in_progress']
    ['first', 'second', 'third'].each_with_index do |id, i|
      d = Dynamic.where(annotation_type: 'fetch').where('data LIKE ?', "%id: #{id}%").last
      assert_not_nil d
      assert_equal @bot.id, d.annotated.user_id
      assert_equal @bot, d.annotator
      assert_equal statuses[i], d.annotated.last_status
    end
  end
end
