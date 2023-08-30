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
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', true] })
    Sidekiq::Testing.inline! do
      pm = create_project_media
      assert_equal 0, pm.reload.requests_count
      d = create_dynamic_annotation annotation_type: 'smooch', annotated: pm
      assert_equal 1, pm.reload.requests_count
      d.destroy
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

  test "should create smooch annotation for user requests" do
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
        annotation_type: 'smooch',
        annotated_type: @pm_for_menu_option.class.name,
        annotated_id: @pm_for_menu_option.id
      }
      assert_difference "Dynamic.where(#{conditions}).count", 1 do
        Sidekiq::Worker.drain_all
      end
      a = Dynamic.where(conditions).last
      f = a.get_field_value('smooch_data')
      text  = JSON.parse(f)['text'].split("\n#{Bot::Smooch::MESSAGE_BOUNDARY}")
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
      assert_difference "Dynamic.where(#{conditions}).count", 1 do
        Sidekiq::Worker.drain_all
      end
      a = Dynamic.where(conditions).last
      f = a.get_field_value('smooch_data')
      text  = JSON.parse(f)['text'].split("\n#{Bot::Smooch::MESSAGE_BOUNDARY}")
      # verify that all messages stored
      assert_equal 5, text.size
      assert_equal '1', text.last
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      Time.stubs(:now).returns(now + 30.minutes)
      assert_difference 'Annotation.where(annotation_type: "smooch").count', 1 do
        Sidekiq::Worker.drain_all
      end
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot(random_string, uid)
      Time.stubs(:now).returns(now + 30.minutes)
      assert_difference 'Annotation.where(annotation_type: "smooch").count', 1 do
        Sidekiq::Worker.drain_all
      end
    end
    Time.unstub(:now)
  end

  test "should not raise exception if can't parse RSS feed" do
    BotUser.delete_all
    assert_nothing_raised do
      Bot::Smooch.refresh_rss_feeds_cache
    end
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
    pm = create_project_media team: t
    publish_report(pm)
    b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
    b.install_to!(t)
    tbi = TeamBotInstallation.where(team_id: t.id, user_id: b.id).last
    tbi.set_similarity_date_threshold = 6
    tbi.set_date_similarity_threshold_enabled = true
    tbi.save!

    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => 'Foo bar' })
    CheckSearch.any_instance.stubs(:medias).returns([pm])

    assert_equal [pm], Bot::Smooch.get_search_results(random_string, {}, pm.team_id, 'en')

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
    Bot::Alegre.stubs(:get_merged_similar_items).returns({ pm.id => { score: 0.9, model: 'elasticsearch' } })

    assert_equal [pm], Bot::Smooch.get_search_results(random_string, {}, pm.team_id, 'en')

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
    Bot::Alegre.stubs(:get_items_with_similar_media).returns({ pm.id => { score: 0.9, model: 'elasticsearch' } })

    assert_equal [pm], Bot::Smooch.get_search_results(random_string, {}, pm.team_id, 'en')

    Bot::Smooch.unstub(:bundle_list_of_messages)
    ProjectMedia.any_instance.unstub(:report_status)
    ProjectMedia.any_instance.unstub(:analysis_published_article_url)
    Bot::Alegre.unstub(:get_items_with_similar_media)
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
    results = { pm1.id => { model: 'elasticsearch', score: 10.8 }, pm2.id => { model: 'elasticsearch', score: 15.2},
      pm3.id => { model: 'anything-else', score: 1.98 }, pm4.id => { model: 'anything-else', score: 1.8}}
    assert_equal [pm3, pm4, pm2], Bot::Smooch.parse_search_results_from_alegre(results, t.id)
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

    assert_equal [], Bot::Smooch.get_search_results(random_string, {}, pm.team_id, 'en')

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
      assert_equal [pm], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id], nil)
    end

    assert_queries '=', 0 do
      assert_equal [pm], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id], nil)
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
    sleep 3 # Wait for ElasticSearch to index content

    [
      '🤣',  #Direct match
      '🤣 word', #Direct match
      'word 🤣', #Direct match
      'ward', #Fuzzy match (non-emoji)
      '🤣 ward', #Fuzzy match (non-emoji)
    ].each do |query|
      assert_equal [pm.id], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id]).to_a.map(&:id)
    end

    [
      '🤣🌞', #No match
      '🌞', #No match
      '🤣 🌞' #No match (we only perform AND)
    ].each do |query|
      assert_equal [], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id]).to_a.map(&:id)
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
    sleep 3 # Wait for ElasticSearch to index content

    assert_equal [pm1.id, pm2.id, pm3.id], Bot::Smooch.search_for_similar_published_fact_checks('text', 'Foo Bar', [t.id]).to_a.map(&:id)
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
    assert_equal [], Bot::Smooch.get_search_results(random_string, {}, pm.team_id, 'en')
  end
end
