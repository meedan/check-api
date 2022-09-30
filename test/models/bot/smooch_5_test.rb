require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch5Test < ActiveSupport::TestCase
  def setup
    super
    setup_smooch_bot
  end

  def teardown
    super
    CONFIG.unstub(:[])
    Bot::Smooch.unstub(:get_language)
  end

  test "should update cached field when request is created or deleted" do
    RequestStore.store[:skip_cached_field_update] = false
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', true] })
    pm = create_project_media
    assert_equal 0, pm.reload.requests_count
    d = create_dynamic_annotation annotation_type: 'smooch', annotated: pm
    assert_equal 1, pm.reload.requests_count
    d.destroy
    assert_equal 0, pm.reload.requests_count
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
      assert_equal 'en', Bot::Smooch.get_user_language({ 'authorId' => uid })
      send_message_to_smooch_bot('3', uid)
      assert_equal 'main', sm.state.value
      assert_equal 'pt', Bot::Smooch.get_user_language({ 'authorId' => uid })
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
      # verify that all messages stored
      assert_equal 4, text.size
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
      assert_equal 6, text.size
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
    b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
    b.install_to!(t)
    tbi = TeamBotInstallation.where(team_id: t.id, user_id: b.id).last
    tbi.set_similarity_date_threshold = 6
    tbi.set_date_similarity_threshold_enabled = true
    tbi.save!
    pm = create_project_media team: t

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

  test "should format newsletter time as cron" do
    # Offset
    settings = {
      'smooch_newsletter_time' => '10',
      'smooch_newsletter_timezone' => 'America/Chicago (GMT-05:00)',
      'smooch_newsletter_day' => 'friday'
    }
    assert_equal '0 15 * * 5', Bot::Smooch.newsletter_cron(settings)

    # Offset, other direction
    settings = {
      'smooch_newsletter_time' => '10',
      'smooch_newsletter_timezone' => 'Indian/Maldives (GMT+05:00)',
      'smooch_newsletter_day' => 'friday'
    }
    assert_equal '0 5 * * 5', Bot::Smooch.newsletter_cron(settings)

    # Non-integer hours offset, but still same day as UTC
    settings = {
      'smooch_newsletter_time' => '19',
      'smooch_newsletter_timezone' => 'Asia/Kolkata (GMT+05:30)',
      'smooch_newsletter_day' => 'sunday'
    }
    assert_equal '30 13 * * 0', Bot::Smooch.newsletter_cron(settings)

    # Non-integer hours offset and not same day as UTC
    settings = {
      'smooch_newsletter_time' => '1',
      'smooch_newsletter_timezone' => 'Asia/Kolkata (GMT+05:30)',
      'smooch_newsletter_day' => 'sunday'
    }
    assert_equal '30 19 * * 6', Bot::Smooch.newsletter_cron(settings)

    # Integer hours offset and not same day as UTC
    settings = {
      'smooch_newsletter_time' => '23',
      'smooch_newsletter_timezone' => 'America/Los Angeles (GMT-07:00)',
      'smooch_newsletter_day' => 'sunday'
    }
    assert_equal '0 6 * * 1', Bot::Smooch.newsletter_cron(settings)

    # Everyday
    settings = {
      'smooch_newsletter_time' => '10',
      'smooch_newsletter_timezone' => 'America/New York (GMT-04:00)',
      'smooch_newsletter_day' => 'everyday'
    }
    assert_equal '0 14 * * *', Bot::Smooch.newsletter_cron(settings)

    # Legacy 3 letter codes
    settings = {
      'smooch_newsletter_time' => '10',
      'smooch_newsletter_timezone' => 'EST',
      'smooch_newsletter_day' => 'sunday'
    }
    assert_equal '0 15 * * 0', Bot::Smooch.newsletter_cron(settings)
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

  test "should search for longest string between query and URL description" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published')

    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","description":"Foo bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => "Foo bar foo bar #{url}" })
    CheckSearch.any_instance.stubs(:medias).returns([pm1])
    Bot::Alegre.stubs(:get_merged_similar_items).returns({ pm2.id => { score: 0.9, model: 'elasticsearch' } })

    assert_equal [pm2], Bot::Smooch.get_search_results(random_string, {}, t.id, 'en')
    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => "Test #{url}" })
    assert_equal [pm1], Bot::Smooch.get_search_results(random_string, {}, t.id, 'en')

    ProjectMedia.any_instance.unstub(:report_status)
    CheckSearch.any_instance.unstub(:medias)
    Bot::Smooch.unstub(:bundle_list_of_messages)
    Bot::Alegre.unstub(:get_merged_similar_items)
  end

  test "should search for feed" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch

    # Create testing data
    t1 = create_team
    pm1a = create_project_media quote: 'Bar Test', team: t1 # Should be in search results
    pm1b = create_project_media quote: 'Test 1A', team: t1 # Should not be in search results because doesn't match this team's filters
    pm1c = create_project_media media: Blank.create!, team: t1 # Should not be in search results because doesn't match the feed filters
    pm1d = create_project_media quote: 'Foo Bar', team: t1 # Should not be in keyword search results because doesn't match the query filter but should be in similarity search results because it's returned from Alegre
    pm1e = create_project_media quote: 'Bar Test 2', team: t1 # Should not be in search results because it's not published
    pm1f = create_project_media quote: 'Bar Test 3', team: t1 # Should not be in similarity search results because it's not returned by Alegre but should be in keyword search results
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","title":"Bar","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm1g = create_project_media media: l, team: t1 # Should be only in search results by URL
    t2 = create_team
    pm2a = create_project_media quote: 'Test 2', team: t2 # Should be in search results
    pm2b = create_project_media media: l, team: t2 # Should be only in search results by URL
    t3 = create_team
    pm3a = create_project_media quote: 'Test 3', team: t3 # Should not be in search results (team is part of feed but sharing is disabled)
    pm3b = create_project_media media: l, team: t3 # Should not be in search results by URL
    t4 = create_team
    pm4a = create_project_media quote: 'Test 4', team: t4 # Should not be in search results (team is not part of feed)
    pm4b = create_project_media media: l, team: t4 # Should not be in search results by URL
    f1 = create_feed published: true, filters: { show: ['claims', 'links'] }
    f1.teams << t1
    f1.teams << t2
    FeedTeam.update_all(shared: true)
    f1.teams << t3
    ft = FeedTeam.where(feed: f1, team: t1).last
    ft.filters = { keyword: 'Bar' }
    ft.save!
    u = create_bot_user
    [t1, t2, t3, t4].each { |t| TeamUser.create!(user: u, team: t, role: 'editor') }
    alegre_results = {}
    ProjectMedia.order('id ASC').all.each_with_index do |pm, i|
      publish_report(pm) if pm.id != pm1e.id
      alegre_results[pm.id] = { score: (1 - i / 10.0), model: 'elasticsearch' } unless [pm1f, pm1g, pm2b].map(&:id).include?(pm.id)
    end
    Bot::Alegre.stubs(:get_merged_similar_items).returns(alegre_results)
    Bot::Alegre.stubs(:get_items_with_similar_media).returns(alegre_results)

    # Get feed data scoped by teams that are part of the feed, taking into account the filters for the feed
    # and for each team participating in the feed
    with_current_user_and_team(u, t1) do

      # Keyword search
      assert_equal [pm1a, pm1f, pm2a].sort, Bot::Smooch.search_for_similar_published_fact_checks('text', 'Test', [t1.id, t2.id, t3.id, t4.id], nil, f1.id).to_a.sort

      # Text similarity search
      assert_equal [pm1a, pm1d, pm2a], Bot::Smooch.search_for_similar_published_fact_checks('text', 'This is a test', [t1.id, t2.id, t3.id, t4.id], nil, f1.id).to_a

      # Media similarity search
      assert_equal [pm1a, pm1d, pm2a], Bot::Smooch.search_for_similar_published_fact_checks('image', random_url, [t1.id, t2.id, t3.id, t4.id], nil, f1.id).to_a

      # URL search
      assert_equal [pm1g, pm2b].sort, Bot::Smooch.search_for_similar_published_fact_checks('text', "Test with URL: #{url}", [t1.id, t2.id, t3.id, t4.id], nil, f1.id).to_a.sort
    end

    Bot::Alegre.unstub(:get_merged_similar_items)
    Bot::Alegre.unstub(:get_items_with_similar_media)
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

  test "should search by URL" do
    t = create_team
    f = create_feed published: true
    f.teams << t
    FeedTeam.update_all(shared: true)

    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"http://projetocomprova.com.br/publicações/tuite-engana-ao-dizer-que-o-stf-decidiu-que-voto-impresso-e-inconstitucional/","type":"item","title":"Foo","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'https://projetocomprova.com.br/publica%C3%A7%C3%B5es/tuite-engana-ao-dizer-que-o-stf-decidiu-que-voto-impresso-e-inconstitucional/' } }).to_return(body: response)

    assert_nothing_raised do
      with_current_user_and_team(nil, t) do
        Bot::Smooch.search_for_similar_published_fact_checks('text', 'https://projetocomprova.com.br/publicações/tuite-engana-ao-dizer-que-o-stf-decidiu-que-voto-impresso-e-inconstitucional/ ', [t.id], nil, f.id)
      end
    end
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

  test "should perform fuzzy matching on keyword search" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch

    t = create_team
    pm1 = create_project_media quote: 'A segurança das urnas está provada.', team: t
    pm2 = create_project_media quote: 'Segurança pública é tema de debate.', team: t
    [pm1, pm2].each { |pm| publish_report(pm) }
    sleep 3 # Wait for ElasticSearch to index content

    [
      'Segurança das urnas',
      'Segurança dad urnas',
      'Segurança das urna',
      'Seguranca das urnas'
    ].each do |query|
      assert_equal [pm1.id], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id]).to_a.map(&:id)
    end
  end
end
