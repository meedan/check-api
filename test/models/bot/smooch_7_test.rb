require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch7Test < ActiveSupport::TestCase
  def setup
    super
    setup_smooch_bot
    Rails.cache.delete('smooch_bot_installation_id:smooch_webhook_secret:test')
  end

  def teardown
    super
    CONFIG.unstub(:[])
    Bot::Smooch.unstub(:get_language)
  end

  test "should update cached field when request is created or deleted" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      t = create_team
      pm = create_project_media team: t
      assert_equal 0, pm.reload.requests_count
      tr = create_tipline_request team_id: t.id, associated: pm
      assert_equal 1, pm.reload.requests_count
      tr.destroy
      assert_equal 0, pm.reload.requests_count
    end
  end

  test "should go through menus" do
    setup_smooch_bot(true)
    @team.set_languages ['en', 'pt']
    @team.save!
    uid = random_string
    sm = CheckStateMachine.new(uid)
    rss = '<rss version="1"><channel><title>x</title><link>x</link><description>x</description><item><title>x</title><link>x</link></item></channel></rss>'
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(status: 200, body: rss)
    Sidekiq::Testing.fake! do
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot('Hello', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('9', uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot('What?', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('What??', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('Hum', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot(' ONE', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('ONE ', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('4', uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot(' ONE', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('ONE ', uid)
      send_message_to_smooch_bot('2', uid)
      assert_equal 'query', sm.state.value
      send_message_to_smooch_bot('0', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      assert_equal 'en', Bot::Smooch.get_user_language(uid)
      send_message_to_smooch_bot('3', uid)
      assert_equal 'main', sm.state.value
      assert_equal 'pt', Bot::Smooch.get_user_language(uid)
      send_message_to_smooch_bot('um', uid)
      assert_equal 'query', sm.state.value
    end
    Rails.cache.stubs(:read).returns(nil)
    Rails.cache.stubs(:read).with("smooch:last_message_from_user:#{uid}").returns(Time.now + 10.seconds)
    assert_difference 'ProjectMedia.count' do
      send_message_to_smooch_bot(random_string, uid)
    end
    Rails.cache.unstub(:read)
    assert_equal 'waiting_for_message', sm.state.value
    @team.set_languages ['en']
    @team.save!
  end

  test "should transition from query state to query state" do
    uid = random_string
    sm = CheckStateMachine.new(uid)
    assert_nothing_raised do
      sm.go_to_query
      sm.go_to_query
    end
  end

  test "should timeout menu status" do
    setup_smooch_bot(true)
    Sidekiq::Testing.fake! do
      now = Time.now
      uid = random_string
      sm = CheckStateMachine.new(uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      Time.stubs(:now).returns(now + 30.minutes)
      Sidekiq::Worker.drain_all
      assert_equal 'waiting_for_message', sm.state.value
    end
    Time.unstub(:now)
  end

  test "should create tipline requests for user requests" do
    setup_smooch_bot(true)
    Sidekiq::Testing.fake! do
      now = Time.now
      uid = random_string
      sm = CheckStateMachine.new(uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('1', uid)
      conditions = {
        associated_type: @pm_for_menu_option.class.name,
        associated_id: @pm_for_menu_option.id
      }
      assert_difference "TiplineRequest.where(#{conditions}).count", 1 do
        Sidekiq::Worker.drain_all
      end
      tr = TiplineRequest.where(conditions).last
      text  = tr.smooch_data['text'].split("\n#{Bot::Smooch::MESSAGE_BOUNDARY}")
      # Verify that all messages were stored
      assert_equal 3, text.size
      assert_equal '1', text.last
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot('1', uid)
      assert_difference "TiplineRequest.where(#{conditions}).count", 1 do
        Sidekiq::Worker.drain_all
      end
      tr = TiplineRequest.where(conditions).last
      text  = tr.smooch_data['text'].split("\n#{Bot::Smooch::MESSAGE_BOUNDARY}")
      # verify that all messages stored
      assert_equal 5, text.size
      assert_equal '1', text.last
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      Time.stubs(:now).returns(now + 30.minutes)
      assert_difference 'TiplineRequest.count', 1 do
        Sidekiq::Worker.drain_all
      end
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot(random_string, uid)
      Time.stubs(:now).returns(now + 30.minutes)
      assert_difference 'TiplineRequest.count', 1 do
        Sidekiq::Worker.drain_all
      end
    end
    Time.unstub(:now)
  end

  test "should subscribe or unsubscribe to newsletter" do
    setup_smooch_bot(true)
    Sidekiq::Testing.fake! do
      uid = random_string
      sm = CheckStateMachine.new(uid)
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('5', uid)
      assert_equal 'subscription', sm.state.value
      send_message_to_smooch_bot('0', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('5', uid)
      assert_equal 'subscription', sm.state.value
      assert_difference 'TiplineSubscription.count' do
        send_message_to_smooch_bot('1', uid)
      end
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('5', uid)
      assert_equal 'subscription', sm.state.value
      assert_difference 'TiplineSubscription.count', -1 do
        send_message_to_smooch_bot('1', uid)
      end
    end
  end

  test "should perform a keyword search if text with less or equal to 3 words" do
    t = create_team
    pm = create_project_media team: t, media: create_valid_media
    publish_report(pm)
    b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
    b.install_to!(t)
    tbi = TeamBotInstallation.where(team_id: t.id, user_id: b.id).last
    tbi.set_similarity_date_threshold = 6
    tbi.set_date_similarity_threshold_enabled = true
    tbi.save!

    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => 'Foo bar' })
    CheckSearch.any_instance.stubs(:medias).returns([pm])

    uid = random_string
    query = Bot::Smooch.get_search_query(uid, {})
    assert_equal [pm], Bot::Smooch.get_search_results(uid, query, pm.team_id, 'en', 3)

    Bot::Smooch.unstub(:bundle_list_of_messages)
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should perform a text similarity search if text with more than 3 words" do
    t = create_team
    b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
    b.install_to!(t)
    tbi = TeamBotInstallation.where(team_id: t.id, user_id: b.id).last
    tbi.set_similarity_date_threshold = 6
    tbi.set_date_similarity_threshold_enabled = true
    tbi.save!
    pm = create_project_media team: t

    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => 'Foo bar foo bar foo bar' })
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    ProjectMedia.any_instance.stubs(:analysis_published_article_url).returns(random_url)
    Bot::Alegre.stubs(:get_merged_similar_items).returns({ pm.id => { score: 0.9, model: 'elasticsearch', context: {foo: :bar} } })

    uid = random_string
    query = Bot::Smooch.get_search_query(uid, {})
    assert_equal [pm], Bot::Smooch.get_search_results(uid, query, pm.team_id, 'en', 3)

    Bot::Smooch.unstub(:bundle_list_of_messages)
    ProjectMedia.any_instance.unstub(:report_status)
    ProjectMedia.any_instance.unstub(:analysis_published_article_url)
    Bot::Alegre.unstub(:get_merged_similar_items)
  end

  test "should perform a media similarity search" do
    t = create_team
    b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
    b.install_to!(t)
    tbi = TeamBotInstallation.where(team_id: t.id, user_id: b.id).last
    tbi.set_similarity_date_threshold = 6
    tbi.set_date_similarity_threshold_enabled = true
    tbi.save!
    pm = create_project_media team: t

    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'image', 'mediaUrl' => random_url })
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    ProjectMedia.any_instance.stubs(:analysis_published_article_url).returns(random_url)
    Bot::Alegre.stubs(:get_items_with_similar_media_v2).returns({ pm.id => { score: 0.9, model: 'elasticsearch', context: {foo: :bar} } })
    CheckS3.stubs(:rewrite_url).returns(random_url)

    assert_equal [pm], Bot::Smooch.get_search_results(random_string, {}, pm.team_id, 'en', 3)

    Bot::Smooch.unstub(:bundle_list_of_messages)
    ProjectMedia.any_instance.unstub(:report_status)
    ProjectMedia.any_instance.unstub(:analysis_published_article_url)
    Bot::Alegre.unstub(:get_items_with_similar_media_v2)
  end

  test "should handle exception when adding Smooch integration" do
    SmoochApi::IntegrationApi.any_instance.stubs(:create_integration).raises(SmoochApi::ApiError)
    assert_nothing_raised do
      @installation.smooch_add_integration('telegram', { token: random_string })
    end
    SmoochApi::IntegrationApi.any_instance.unstub(:create_integration)
  end

  test "should not timeout after subscribing to newsletter" do
    setup_smooch_bot(true)
    @team.set_languages ['de']
    @team.save!
    uid = random_string
    sm = CheckStateMachine.new(uid)
    Sidekiq::Testing.fake! do
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('5', uid)
      assert_equal 'subscription', sm.state.value
      assert_difference 'TiplineSubscription.count' do
        send_message_to_smooch_bot('1', uid)
        assert_equal 'waiting_for_message', sm.state.value
      end
      assert_no_difference "DynamicAnnotation::Field.where('value LIKE ?', '%timeout_request%').count" do
        Sidekiq::Worker.drain_all
      end
    end
  end
  
  test "should order results from Alegre" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published') # We can stub this because it's not what this test is testing
    t = create_team
    pm1 = create_project_media team: t #ES low score
    pm2 = create_project_media team: t #ES high score
    pm3 = create_project_media team: t #Vector high score
    pm4 = create_project_media team: t #Vector low score
    # Create more project media if needed
    results = { pm1.id => { model: 'elasticsearch', score: 10.8, context: {foo: :bar}}, pm2.id => { model: 'elasticsearch', score: 15.2, context: {foo: :bar}},
      pm3.id => { model: 'anything-else', score: 1.98, context: {foo: :bar}}, pm4.id => { model: 'anything-else', score: 1.8, context: {foo: :bar}}}
    assert_equal [pm3, pm4, pm2], Bot::Smooch.parse_search_results_from_alegre(results, 3, t.id)
    ProjectMedia.any_instance.unstub(:report_status)
  end

  test "should omit temporary results from Alegre" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published') # We can stub this because it's not what this test is testing
    t = create_team
    pm1 = create_project_media team: t #ES low score
    pm2 = create_project_media team: t #ES high score
    pm3 = create_project_media team: t #Vector high score
    pm4 = create_project_media team: t #Vector low score
    # Create more project media if needed
    results = { pm1.id => { model: 'elasticsearch', score: 10.8, context: {blah: 1} }, pm2.id => { model: 'elasticsearch', score: 15.2, context: {blah: 1} },
      pm3.id => { model: 'anything-else', score: 1.98, context: {temporary_media: true} }, pm4.id => { model: 'anything-else', score: 1.8, context: {temporary_media: false}}}
    assert_equal [pm4, pm2, pm1], Bot::Smooch.parse_search_results_from_alegre(results, 3, t.id)
    ProjectMedia.any_instance.unstub(:report_status)
  end

  test "should not search for empty link description" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published')

    t = create_team
    pm = create_project_media team: t
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => url })
    CheckSearch.any_instance.stubs(:medias).returns([pm])

    assert_equal [], Bot::Smooch.get_search_results(random_string, {}, pm.team_id, 'en', 3)

    ProjectMedia.any_instance.unstub(:report_status)
    CheckSearch.any_instance.unstub(:medias)
    Bot::Smooch.unstub(:bundle_list_of_messages)
  end

  test "should cache search results" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published')

    t = create_team
    pm = create_project_media team: t
    CheckSearch.any_instance.stubs(:medias).returns([pm])
    query = 'foo bar'

    assert_queries '>', 1 do
      assert_equal [pm], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id], 3, nil)
    end

    assert_queries '=', 0 do
      assert_equal [pm], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id], 3, nil)
    end

    ProjectMedia.any_instance.unstub(:report_status)
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should *not* perform fuzzy matching on keyword search when query is emoji only" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch

    t = create_team
    pm = create_project_media quote: '🤣 word', team: t
    publish_report(pm)
    sleep 2 # Wait for ElasticSearch to index content

    [
      '🤣',  #Direct match
      '🤣 word', #Direct match
      'word 🤣', #Direct match
      'ward', #Fuzzy match (non-emoji)
      '🤣 ward', #Fuzzy match (non-emoji)
    ].each do |query|
      assert_equal [pm.id], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id], 3).to_a.map(&:id)
    end

    [
      '🤣🌞', #No match
      '🌞', #No match
      '🤣 🌞' #No match (we only perform AND)
    ].each do |query|
      assert_equal [], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id], 3).to_a.map(&:id)
    end
  end

  test "should sort keyword search results by score" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch

    t = create_team
    pm1 = create_project_media quote: 'Foo Bar', team: t
    pm2 = create_project_media quote: 'Foo Bar Test', team: t
    pm3 = create_project_media quote: 'Foo Bar Test Testing', team: t
    [pm1, pm2, pm3].each { |pm| publish_report(pm) }
    sleep 2 # Wait for ElasticSearch to index content

    assert_equal [pm1.id, pm2.id, pm3.id], Bot::Smooch.search_for_similar_published_fact_checks('text', 'Foo Bar', [t.id], 3).to_a.map(&:id)
    # Calling wiht skip_cache true
    assert_equal [pm1.id, pm2.id, pm3.id], Bot::Smooch.search_for_similar_published_fact_checks('text', 'Foo Bar', [t.id], 3, nil, nil, nil, true).to_a.map(&:id)
  end

  test "should store media" do
    f = create_feed
    f.set_media_headers = { 'Authorization' => 'App 123456' }
    f.save!
    media_url = random_url
    WebMock.stub_request(:get, media_url).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    local_media_url = Bot::Smooch.save_locally_and_return_url(media_url, 'image', f.id)
    assert_match /^http/, local_media_url
    assert_not_equal media_url, local_media_url
  end

  test "should log resend error" do
    CheckSentry.expects(:notify).once
    Bot::Smooch.log_resend_error({ 'isFinalEvent' => true })
  end

  test "should be sure that template placeholders are not blank" do
    template_message = Bot::Smooch.format_template_message('test', ['foo', nil, 'bar'], nil, 'fallback', 'en')
    assert_match 'body_text=[[foo]]body_text=[[-]]body_text=[[bar]]', template_message
  end

  test "should not return cache search result if report is not published anymore" do
    pm = create_project_media
    Bot::Smooch.stubs(:search_for_similar_published_fact_checks).returns([pm])
    assert_equal [], Bot::Smooch.get_search_results(random_string, {}, pm.team_id, 'en', 3)
  end

  test "should store sent tipline message in background" do
    text = 'random_string'
    uid = random_string
    u = create_user
    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        source: { type: "whatsapp" },
        text: text
      }
    ]
    payload = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: messages,
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    Bot::Smooch.run(payload)
    sleep 1
    pm = ProjectMedia.last
    r = create_report(pm)
    Sidekiq::Testing.fake! do
      assert_equal 0, Sidekiq::Extensions::DelayedClass.jobs.size
      publish_report(pm, {}, r)
      assert_equal 2, Sidekiq::Extensions::DelayedClass.jobs.size
      assert_difference 'TiplineMessage.count', 2 do
        Sidekiq::Worker.drain_all
      end
    end
  end

  test "should store number of tipline requests by type" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline! do
      text = random_string
      pm = create_project_media team: @team, quote: text, disable_es_callbacks: false
      text2 = random_string
      pm2 = create_project_media team: @team, quote: text2, disable_es_callbacks: false
      message = lambda do
        {
          type: 'text',
          text: text,
          role: 'appUser',
          received: 1573082583.219,
          name: random_string,
          authorId: random_string,
          '_id': random_string,
          source: {
            originalMessageId: random_string,
            originalMessageTimestamp: 1573082582,
            type: 'whatsapp',
            integrationId: random_string
          },
          language: 'en',
        }
      end
      Bot::Smooch.save_message(message.call.to_json, @app_id, nil, 'relevant_search_result_requests', pm.id, pm.class.name)
      Bot::Smooch.save_message(message.call.to_json, @app_id, nil, 'relevant_search_result_requests', pm.id, pm.class.name)
      Bot::Smooch.save_message(message.call.to_json, @app_id, nil, 'timeout_search_requests', pm.id, pm.class.name)
      Bot::Smooch.save_message(message.call.to_json, @app_id, nil, 'irrelevant_search_result_requests', pm.id, pm.class.name)
      Bot::Smooch.save_message(message.call.to_json, @app_id, nil, 'irrelevant_search_result_requests', pm.id, pm.class.name)
      Bot::Smooch.save_message(message.call.to_json, @app_id, nil, 'irrelevant_search_result_requests', pm.id, pm.class.name)
      message = lambda do
        {
          type: 'text',
          text: text2,
          role: 'appUser',
          received: 1573082583.219,
          name: random_string,
          authorId: random_string,
          '_id': random_string,
          source: {
            originalMessageId: random_string,
            originalMessageTimestamp: 1573082582,
            type: 'whatsapp',
            integrationId: random_string
          },
          language: 'en',
        }
      end
      Bot::Smooch.save_message(message.call.to_json, @app_id, nil, 'relevant_search_result_requests', pm2.id, pm2.class.name)
      Bot::Smooch.save_message(message.call.to_json, @app_id, nil, 'irrelevant_search_result_requests', pm2.id, pm2.class.name)
      Bot::Smooch.save_message(message.call.to_json, @app_id, nil, 'irrelevant_search_result_requests', pm2.id, pm2.class.name)
      # Verify cached field
      assert_equal 6, pm.tipline_search_results_count
      assert_equal 2, pm.positive_tipline_search_results_count
      assert_equal 3, pm.negative_tipline_search_results_count
      assert_equal 3, pm2.tipline_search_results_count
      assert_equal 1, pm2.positive_tipline_search_results_count
      assert_equal 2, pm2.negative_tipline_search_results_count
      # Verify ES values
      es = $repository.find(pm.get_es_doc_id)
      assert_equal 6, es['tipline_search_results_count']
      assert_equal 2, es['positive_tipline_search_results_count']
      assert_equal 3, es['negative_tipline_search_results_count']
      es2 = $repository.find(pm2.get_es_doc_id)
      assert_equal 3, es2['tipline_search_results_count']
      assert_equal 1, es2['positive_tipline_search_results_count']
      assert_equal 2, es2['negative_tipline_search_results_count']
      # Verify destroy
      types = ["irrelevant_search_result_requests", "timeout_search_requests"]
      TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: pm.id, smooch_request_type: types).destroy_all
      assert_equal 2, pm.tipline_search_results_count
      assert_equal 2, pm.positive_tipline_search_results_count
      assert_equal 0, pm.negative_tipline_search_results_count
    end
  end

  test "should save report and report correction sent at " do
    messages = [
      {
        '_id': random_string,
        authorId: random_string,
        type: 'text',
        source: { type: "whatsapp" },
        text: random_string
      }
    ]
    payload = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: messages,
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    Bot::Smooch.run(payload)
    sleep 1
    pm = ProjectMedia.last
    r = create_report(pm)
    publish_report(pm, {}, r)
    r = Dynamic.find(r.id)
    r.set_fields = { state: 'paused' }.to_json
    r.action = 'pause'
    r.save!
    r = Dynamic.find(r.id)
    r.set_fields = { state: 'published' }.to_json
    r.action = 'republish_and_resend'
    r.save!
    tr = TiplineRequest.last
    assert_not_nil tr.smooch_report_sent_at
    assert_not_nil tr.smooch_report_correction_sent_at
    assert_not_nil tr.smooch_request_type
  end

  test "should include claim_description_content in smooch search" do
    WebMock.stub_request(:post, 'http://alegre:3100/similarity/async/image').to_return(body: {}.to_json)
    WebMock.stub_request(:post, 'http://alegre:3100/similarity/sync/text').to_return(body: {}.to_json)
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    m = create_uploaded_image
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    query = "Claim content"
    results = Bot::Smooch.search_by_keywords_for_similar_published_fact_checks(query.split(), nil, [t.id], 3)
    assert_empty results
    cd = create_claim_description project_media: pm, description: query
    publish_report(pm)
    assert_equal query, pm.claim_description_content
    results = Bot::Smooch.search_by_keywords_for_similar_published_fact_checks(query.split(), nil, [t.id], 3)
    assert_equal [pm.id], results.map(&:id)
  end

  test "should rescue when raise error on tipline request creation" do
    TiplineRequest.any_instance.stubs(:save!).raises(ActiveRecord::RecordNotUnique)
    t = create_team
    pm = create_project_media team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      fields = { 'smooch_request_type' => 'default_requests', 'smooch_message_id' => random_string, 'smooch_data' => { authorId: random_string, language: 'en', source: { type: "whatsapp" }, } }
      assert_no_difference 'TiplineRequest.count' do
        Bot::Smooch.create_tipline_requests(pm, nil, fields)
      end
    end
    TiplineRequest.any_instance.unstub(:save!)
  end

  test "should not try to create relationship between media and tipline resource" do
    t2 = create_team
    pm = create_project_media team: t2
    
    t = create_team
    tipline_resource = create_tipline_resource team: t
    tipline_resource.update_column(:id, pm.id)

    # It should not try to match at all, so we should never get to this notification
    CheckSentry.expects(:notify).never
    Rails.logger.expects(:notify).never

    Sidekiq::Testing.inline! do
      message = {
        type: 'video',
        source: { type: "whatsapp" },
        text: 'Something',
        caption: 'For this to happen, it needs a caption',
        mediaUrl: @video_url,
        '_id': random_string,
        language: 'en',
      }
      assert_no_difference 'Relationship.count' do
        Bot::Smooch.save_message(message.to_json, @app_id, @bot, 'resource_requests', tipline_resource.id, 'TiplineResource')
      end
    end
  end

  test "should replace message_id placeholder" do
    t = create_team
    uid = random_string
    create_tipline_message team_id: t.id, uid: uid, state: 'received', direction: 'incoming', 'external_id': 'abc123'
    create_tipline_message team_id: t.id, uid: uid, state: 'delivered', direction: 'outgoing'
    text = 'Foo {{message_id}} bar {{message_id}}'
    RequestStore.store[:smooch_bot_settings] = { 'team_id' => t.id }
    output = Bot::Smooch.replace_placeholders(uid, text)
    assert_equal "Foo abc123 bar abc123", output
  end
end
