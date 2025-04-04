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

    stub_configs({
      'fetch_url' => 'http://fetch:8000',
      'fetch_token' => 'test',
      'fetch_check_webhook_url' => 'http://check:3100',
      'alegre_host' => 'http://alegre:3100',
    }, false)
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

  test "should import claim reviews with report and correct status and ignore duplicates" do
    RequestStore.store[:skip_cached_field_update] = false
    cr1 = @claim_review.deep_dup
    cr1['reviewRating']['ratingValue'] = 0
    cr1['reviewRating']['alternateName'] = 'False'
    cr1['identifier'] = 'first'
    cr2 = @claim_review.deep_dup
    cr2['reviewRating']['ratingValue'] = 1
    cr2['reviewRating']['alternateName'] = 'True'
    cr2['identifier'] = 'second'
    cr3 = @claim_review.deep_dup
    cr3['reviewRating']['ratingValue'] = 2
    cr3['reviewRating']['alternateName'] = 'Not Mapped'
    cr3['identifier'] = 'third'
    WebMock.stub_request(:get, 'http://fetch:8000/services').to_return(body: { services: [{ service: 'foo', count: 4, earliest: '2017-08-09', latest: '2017-08-09' }]}.to_json)
    WebMock.stub_request(:get, 'http://fetch:8000/claim_reviews?end_time=2017-08-10&include_raw=false&offset=0&per_page=100&service=foo&start_time=2017-08-08').to_return(body: [cr1, cr1, cr2, cr3].to_json)
    WebMock.stub_request(:get, 'http://fetch:8000/claim_reviews?end_time=2017-08-12&include_raw=false&offset=0&per_page=100&service=foo&start_time=2017-08-10').to_return(body: [cr1, cr1, cr2, cr3].to_json)
    assert_difference "ProjectMedia.where(team_id: #{@team.id}).count", 3 do
      assert_difference 'Dynamic.where(annotation_type: "report_design").count', 3 do
        assert_difference 'DynamicAnnotation::Field.where(field_name: "external_id").count', 3 do
          @installation.set_fetch_service_name 'foo'
          @installation.save!
        end
      end
    end
    statuses = ['false', 'verified', 'in_progress']
    ['first', 'second', 'third'].each_with_index do |id, i|
      d = DynamicAnnotation::Field.where(field_name: 'external_id', value: "#{id}:#{@team.id}").last
      assert_not_nil d
      assert_equal statuses[i], d.annotation.annotated.last_status
      assert_equal "Earth isn't flat", d.annotation.annotated.fact_check_title
      assert_equal "Scientific evidences show that Earth is round",  d.annotation.annotated.fact_check_summary
    end
    r = Dynamic.where(annotation_type: 'report_design').last
    assert_equal "Earth isn't flat", r.report_design_field_value('headline')
    assert_equal "Scientific evidences show that Earth is round", r.report_design_field_value('description')
    assert_equal "Earth isn't flat", r.report_design_field_value('title')
    assert_equal "Scientific evidences show that Earth is round", r.report_design_field_value('text')
  end

  test "should notify Sentry if can't import a claim review" do
    CheckSentry.expects(:notify).once
    Bot::Fetch::Import.import_claim_review({}, 0, 0, random_string, {}, false)
  end

  test "should strip HTML tags and decode HTML entities" do
    assert_equal "Earth isn't flat", Bot::Fetch::Import.parse_text("Earth isn&#39;t flat")
    assert_equal "Scientific evidences show that Earth is round, as per link.Please see this image: .", Bot::Fetch::Import.parse_text('<p>Scientific evidences show that <b>Earth</b> is round, as per <a href="http://test.com">link</a>.<br />Please see this image: <img src="http://image/image.jpg" alt="" />.</p>')
  end

  test "should not import duplicate claim reviews" do
    id = random_string
    cr1 = @claim_review.deep_dup
    cr1['identifier'] = id
    cr2 = @claim_review.deep_dup
    cr2['identifier'] = id
    cr3 = @claim_review.deep_dup
    cr3['identifier'] = id

    assert_difference 'ProjectMedia.count' do
      Bot::Fetch::Import.import_claim_review(cr1, @team.id, @bot.id, 'undetermined', {}, false)
    end
    assert_no_difference 'ProjectMedia.count' do
      Bot::Fetch::Import.import_claim_review(cr2, @team.id, @bot.id, 'undetermined', {}, false)
    end

    # A race condition would bypass ActiveRecord validation and Redis semaphore, so let's be sure we have a unique index at the database level too (just for the same workspace)
    Bot::Fetch::Import.stubs(:already_imported?).returns(false)
    assert_no_difference 'ProjectMedia.count' do
      Bot::Fetch::Import.import_claim_review(cr3, @team.id, @bot.id, 'undetermined', {}, false)
    end
    assert_difference 'ProjectMedia.count' do
      Bot::Fetch::Import.import_claim_review(cr3, create_team.id, @bot.id, 'undetermined', {}, false)
    end
    Bot::Fetch::Import.unstub(:already_imported?)
  end

  test "should import tags" do
    id = random_string
    cr = @claim_review.deep_dup
    cr['identifier'] = id
    cr['keywords'] = 'foo , bar,  foo bar '

    assert_difference "Tag.where(annotation_type: 'tag').count", 3 do
      Bot::Fetch::Import.import_claim_review(cr, @team.id, @bot.id, 'undetermined', {}, false)
    end
  end

  test "should fallback to default status if status can't be set" do
    claim_review = { 'reviewRating' => { 'alternateName' => 'foo' } }
    status_mapping = { 'foo' => 'bar' }
    status_fallback = 'verified'
    pm = create_project_media

    assert_equal 'undetermined', pm.reload.last_status

    Bot::Fetch::Import.set_status(claim_review, pm, status_fallback, status_mapping)

    assert_equal 'verified', pm.reload.last_status
  end

  test "should return empty summary if it is equal to the title" do
    claim_review = {
      'text' => 'Foo',
      'headline' => 'Foo'
    }
    assert_equal '', Bot::Fetch::Import.get_summary(claim_review)

    claim_review = {
      'text' => 'Foo',
      'headline' => 'Bar'
    }
    assert_equal 'Foo', Bot::Fetch::Import.get_summary(claim_review)
  end

  test "should set factcheck language" do
    id = random_string
    cr = @claim_review.deep_dup
    cr['identifier'] = id
    cr['inLanguage'] = 'ar'
    assert_difference 'FactCheck.count' do
      Bot::Fetch::Import.import_claim_review(cr, @team.id, @bot.id, 'undetermined', {}, false)
    end
    pm = ProjectMedia.last
    cd = pm.claim_description
    fc = cd.fact_check
    assert_equal 'en', fc.language
    @team.set_languages(['en', 'fr'])
    @team.save!
    # Verify language with multilanguages team
    id = random_string
    cr = @claim_review.deep_dup
    cr['identifier'] = id
    cr['inLanguage'] = 'ar'
    assert_difference 'FactCheck.count' do
      Bot::Fetch::Import.import_claim_review(cr, @team.id, @bot.id, 'undetermined', {}, false)
    end
    pm = ProjectMedia.last
    cd = pm.claim_description
    fc = cd.fact_check
    assert_equal 'und', fc.language
    id = random_string
    cr = @claim_review.deep_dup
    cr['identifier'] = id
    cr['inLanguage'] = 'fr'
    assert_difference 'FactCheck.count' do
      Bot::Fetch::Import.import_claim_review(cr, @team.id, @bot.id, 'undetermined', {}, false)
    end
    pm = ProjectMedia.last
    cd = pm.claim_description
    fc = cd.fact_check
    assert_equal 'fr', fc.language
  end

  test "should cache item title for imported items" do
    RequestStore.store[:skip_cached_field_update] = false
    text = "Earth isn't flat"
    Bot::Fetch::Import.delay(retry: 0).import_claim_reviews(@installation.id)
    pm = ProjectMedia.last
    assert_equal text, pm.title
    assert_equal text, pm.fact_check_title
    assert_equal text, pm.title(true)
    assert_equal text, pm.fact_check_title(true)
  end

  test "should rollback everything if fact check can not be saved" do
    cr = @claim_review.deep_dup
    cr['identifier'] = random_string
    cr['url'] = 'foo'
    assert_no_difference 'ProjectMedia.count' do
      assert_no_difference 'FactCheck.count' do
        Bot::Fetch::Import.import_claim_review(cr, @team.id, @bot.id, 'undetermined', {}, false)     
      end
    end
  end

  test "should fallback to claim reviewed if headline is blank" do
    cr = @claim_review.deep_dup
    cr['identifier'] = random_string
    cr['headline'] = ''
    cr['text'] = ''
    cr['claimReviewed'] = 'foo'
    assert_difference 'FactCheck.count' do
      Bot::Fetch::Import.import_claim_review(cr, @team.id, @bot.id, 'undetermined', {}, false)
    end
  end

  test "should import claim review as published report" do
    cr = @claim_review.deep_dup
    cr['identifier'] = random_string
    assert_difference 'FactCheck.count' do
      Bot::Fetch::Import.import_claim_review(cr, @team.id, @bot.id, 'undetermined', {}, false)
    end

    r = Dynamic.where(annotation_type: 'report_design').last
    assert_equal "published", r.state

    fc = FactCheck.last
    assert_equal "published", fc.report_status
  end
end
